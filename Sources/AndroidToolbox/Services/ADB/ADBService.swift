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

typealias ADBExecutableResolver = () -> URL?

final class ADBService: @unchecked Sendable {
    private let runner: any ProcessRunning
    private let resolveExecutable: ADBExecutableResolver

    var selectedSerial: String?

    init(
        runner: any ProcessRunning = ProcessRunner(),
        resolveExecutable: @escaping ADBExecutableResolver = ADBExecutableLocator.locate
    ) {
        self.runner = runner
        self.resolveExecutable = resolveExecutable
    }

    func listDevices() throws -> ADBDeviceList {
        let output = try run(arguments: ["devices", "-l"])
        return ADBDeviceList(devices: ADBParser.parseDevices(from: output))
    }

    func runShell(_ command: String) throws -> String {
        try run(arguments: ["shell", command])
    }

    func install(apkPath: String) throws -> String {
        try run(arguments: ["install", apkPath])
    }

    func uninstall(packageName: String) throws -> String {
        try run(arguments: ["uninstall", packageName])
    }

    func listPackages(filter: String?) throws -> String {
        var args = ["shell", "pm", "list", "packages"]
        if let filter, !filter.isEmpty {
            args.append(contentsOf: ["-f", filter])
        }
        return try run(arguments: args)
    }

    func listThirdPartyPackages() throws -> [InstalledApp] {
        let script = """
        pm list packages -3 | sed 's/package://' | while read pkg; do
            label=$(dumpsys package "$pkg" 2>/dev/null | grep 'application-label:' | head -1 | sed "s/.*application-label:'//; s/'//")
            echo "${label:-$pkg}|$pkg"
        done
        """
        let output = try run(arguments: ["shell", script], timeout: 120)

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

    func grantPermission(packageName: String, permission: String) throws -> String {
        try run(arguments: ["shell", "pm", "grant", packageName, permission])
    }

    func revokePermission(packageName: String, permission: String) throws -> String {
        try run(arguments: ["shell", "pm", "revoke", packageName, permission])
    }

    func pull(remotePath: String, localPath: String) throws -> String {
        try run(arguments: ["pull", remotePath, localPath])
    }

    func push(localPath: String, remotePath: String) throws -> String {
        try run(arguments: ["push", localPath, remotePath])
    }

    func listRemoteDirectory(path: String, asRoot: Bool = false) throws -> [ADBFileEntry] {
        let arguments: [String]
        if asRoot {
            let command = "ls -a -p -- \(shellQuote(path))"
            arguments = ["shell", "su", "-c", command]
        } else {
            arguments = ["shell", "ls", "-a", "-p", "--", path]
        }

        let output = try run(arguments: arguments)
        return parseRemoteEntries(output: output, basePath: path)
    }

    func reboot(_ target: ADBRebootTarget) throws -> String {
        switch target {
        case .system:
            return try run(arguments: ["reboot"])
        case .fastboot, .bootloader, .edl, .recovery, .sideload:
            return try run(arguments: ["reboot", target.rawValue])
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

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func run(arguments: [String], timeout: TimeInterval = 20) throws -> String {
        guard let executable = resolveExecutable() else {
            throw ADBServiceError.executableMissing
        }

        let effectiveArgs: [String]
        if let serial = selectedSerial, serial != "-" {
            effectiveArgs = ["-s", serial] + arguments
        } else {
            effectiveArgs = arguments
        }

        let result = try runner.run(executable: executable, arguments: effectiveArgs, timeout: timeout)
        guard result.exitCode == 0 else {
            throw ADBServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
