import Foundation

enum FastbootServiceError: Error {
    case executableMissing
    case commandFailed(String)
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

    func listDevices(serial: String? = nil) throws -> [DeviceInfo] {
        let output = try run(arguments: ["devices"], serial: serial)
        return FastbootParser.parseDevices(from: output)
    }

    func getVar(_ key: String, serial: String? = nil) throws -> String {
        try run(arguments: ["getvar", key], serial: serial)
    }

    func reboot(_ target: FastbootRebootTarget, serial: String? = nil) throws -> String {
        switch target {
        case .system:
            return try run(arguments: ["reboot"], serial: serial)
        case .bootloader:
            return try run(arguments: ["reboot-bootloader"], serial: serial)
        case .fastbootd, .recovery:
            return try run(arguments: ["reboot", target.rawValue], serial: serial)
        }
    }

    private func run(arguments: [String], serial: String? = nil) throws -> String {
        guard let executable = resolveExecutable() else {
            throw FastbootServiceError.executableMissing
        }

        let effectiveArgs: [String]
        if let serial, !serial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, serial != "-" {
            effectiveArgs = ["-s", serial] + arguments
        } else {
            effectiveArgs = arguments
        }

        let result = try runner.run(executable: executable, arguments: effectiveArgs, timeout: 20)
        guard result.exitCode == 0 else {
            throw FastbootServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
