import Foundation

enum ADBRebootTarget: String {
    case system
    case fastboot
    case bootloader
    case edl
    case recovery
    case sideload
}

struct ADBDeviceList {
    let devices: [DeviceInfo]
}

enum ADBServiceError: Error {
    case executableMissing
    case commandFailed(String)
}

typealias ADBExecutableResolver = @Sendable () -> URL?

final class ADBService: Sendable {
    private let runner: any ProcessRunning
    private let resolveExecutable: ADBExecutableResolver

    init(
        runner: any ProcessRunning = ProcessRunner(),
        resolveExecutable: @escaping ADBExecutableResolver = ADBExecutableLocator.locate
    ) {
        self.runner = runner
        self.resolveExecutable = resolveExecutable
    }

    func listDevices() async throws -> ADBDeviceList {
        let output = try await run(arguments: ["devices", "-l"])
        return ADBDeviceList(devices: ADBParser.parseDevices(from: output))
    }

    func runShell(_ command: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["shell", command], serial: serial)
    }

    func install(apkPath: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["install", apkPath], timeout: 300, serial: serial)
    }

    func uninstall(packageName: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["uninstall", packageName], serial: serial)
    }

    func listPackages(filter: String?, serial: String? = nil) async throws -> String {
        var args = ["shell", "pm", "list", "packages"]
        if let filter, !filter.isEmpty {
            args.append(contentsOf: ["-f", filter])
        }
        return try await run(arguments: args, serial: serial)
    }

    func listThirdPartyPackages(serial: String? = nil) async throws -> [InstalledApp] {
        let script = """
        pm list packages -3 | sed 's/package://' | while read pkg; do
            label=$(dumpsys package "$pkg" 2>/dev/null | grep 'application-label:' | head -1 | sed "s/.*application-label:'//; s/'//")
            echo "${label:-$pkg}|$pkg"
        done
        """
        let output = try await run(arguments: ["shell", script], timeout: 120, serial: serial)

        let apps: [InstalledApp] = output
            .split(separator: "\n")
            .map(String.init)
            .compactMap { line -> InstalledApp? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard let sep = trimmed.lastIndex(of: "|") else { return nil }
                let appName = String(trimmed[..<sep]).trimmingCharacters(in: .whitespaces)
                let pkgName = String(trimmed[trimmed.index(after: sep)...]).trimmingCharacters(in: .whitespaces)
                guard !pkgName.isEmpty else { return nil }
                return InstalledApp(packageName: pkgName, appName: appName.isEmpty ? pkgName : appName)
            }

        return apps.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
    }

    func grantPermission(packageName: String, permission: String, serial: String? = nil) async throws -> String {
        let command = "pm grant \(ADBShell.quote(packageName)) \(ADBShell.quote(permission))"
        return try await run(arguments: ["shell", command], serial: serial)
    }

    func revokePermission(packageName: String, permission: String, serial: String? = nil) async throws -> String {
        let command = "pm revoke \(ADBShell.quote(packageName)) \(ADBShell.quote(permission))"
        return try await run(arguments: ["shell", command], serial: serial)
    }

    func pull(remotePath: String, localPath: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["pull", remotePath, localPath], timeout: 300, serial: serial)
    }

    func push(localPath: String, remotePath: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["push", localPath, remotePath], timeout: 300, serial: serial)
    }

    func listRemoteDirectory(path: String, asRoot: Bool = false, serial: String? = nil) async throws -> [ADBFileEntry] {
        let lsCommand = "ls -a -p -- \(ADBShell.quote(path))"
        let arguments: [String]
        if asRoot {
            arguments = ["shell", "su", "-c", lsCommand]
        } else {
            arguments = ["shell", lsCommand]
        }

        let output = try await run(arguments: arguments, serial: serial)
        return parseRemoteEntries(output: output, basePath: path)
    }

    func reboot(_ target: ADBRebootTarget, serial: String? = nil) async throws -> String {
        switch target {
        case .system:
            return try await run(arguments: ["reboot"], serial: serial)
        case .fastboot, .bootloader, .edl, .recovery, .sideload:
            return try await run(arguments: ["reboot", target.rawValue], serial: serial)
        }
    }

    private func parseRemoteEntries(output: String, basePath: String) -> [ADBFileEntry] {
        output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { $0 != "." && $0 != ".." }
            .map { line in
                let isDirectory = line.hasSuffix("/")
                let rawName = isDirectory ? String(line.dropLast()) : line
                let path = joinRemotePath(base: basePath, name: rawName)
                return ADBFileEntry(path: path, name: rawName, isDirectory: isDirectory)
            }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory && !rhs.isDirectory
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private func joinRemotePath(base: String, name: String) -> String {
        if base == "/" {
            return "/\(name)"
        }
        return base.hasSuffix("/") ? base + name : base + "/" + name
    }

    private func run(arguments: [String], timeout: TimeInterval = 20, serial: String? = nil) async throws -> String {
        guard let executable = resolveExecutable() else {
            throw ADBServiceError.executableMissing
        }

        let effectiveArgs: [String]
        if let serial, !serial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, serial != "-" {
            effectiveArgs = ["-s", serial] + arguments
        } else {
            effectiveArgs = arguments
        }

        let result = try await runner.run(executable: executable, arguments: effectiveArgs, timeout: timeout)
        guard result.exitCode == 0 else {
            throw ADBServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
