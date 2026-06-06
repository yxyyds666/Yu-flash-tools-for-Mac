import Foundation

enum FastbootServiceError: Error {
    case executableMissing
    case commandFailed(String)
}

extension FastbootServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .executableMissing:
            return "找不到 fastboot 可执行文件"
        case .commandFailed(let output):
            return output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "fastboot 命令执行失败" : output
        }
    }
}

enum FastbootRebootTarget: String {
    case system
    case bootloader
    case fastbootd = "fastboot"
    case recovery
}

typealias FastbootExecutableResolver = @Sendable () -> URL?

final class FastbootService: Sendable {
    private let runner: any ProcessRunning
    private let resolveExecutable: FastbootExecutableResolver

    init(
        runner: any ProcessRunning = ProcessRunner(),
        resolveExecutable: @escaping FastbootExecutableResolver = FastbootExecutableLocator.locate
    ) {
        self.runner = runner
        self.resolveExecutable = resolveExecutable
    }

    func listDevices(serial: String? = nil) async throws -> [DeviceInfo] {
        let output = try await run(arguments: ["devices"], serial: serial)
        return FastbootParser.parseDevices(from: output)
    }

    func getVar(_ key: String, serial: String? = nil) async throws -> String {
        try await run(arguments: ["getvar", key], serial: serial)
    }

    func flash(partition: String, image: URL, serial: String? = nil) async throws -> String {
        try await run(arguments: ["flash", partition, image.path], serial: serial, timeout: 300)
    }

    func reboot(_ target: FastbootRebootTarget, serial: String? = nil) async throws -> String {
        switch target {
        case .system:
            return try await run(arguments: ["reboot"], serial: serial)
        case .bootloader:
            return try await run(arguments: ["reboot-bootloader"], serial: serial)
        case .fastbootd, .recovery:
            return try await run(arguments: ["reboot", target.rawValue], serial: serial)
        }
    }

    private func run(arguments: [String], serial: String? = nil, timeout: TimeInterval = 20) async throws -> String {
        guard let executable = resolveExecutable() else {
            throw FastbootServiceError.executableMissing
        }

        let effectiveArgs: [String]
        if let serial, !serial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, serial != "-" {
            effectiveArgs = ["-s", serial] + arguments
        } else {
            effectiveArgs = arguments
        }

        let result = try await runner.run(executable: executable, arguments: effectiveArgs, timeout: timeout)
        guard result.exitCode == 0 else {
            throw FastbootServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
