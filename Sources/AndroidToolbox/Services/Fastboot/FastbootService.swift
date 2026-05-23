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

final class FastbootService {
    private let runner: any ProcessRunning
    var selectedSerial: String?

    init(runner: any ProcessRunning = ProcessRunner()) {
        self.runner = runner
    }

    func listDevices() throws -> [DeviceInfo] {
        let output = try run(arguments: ["devices"])
        return FastbootParser.parseDevices(from: output)
    }

    func getVar(_ key: String) throws -> String {
        try run(arguments: ["getvar", key])
    }

    func reboot(_ target: FastbootRebootTarget) throws -> String {
        switch target {
        case .system:
            return try run(arguments: ["reboot"])
        case .bootloader:
            return try run(arguments: ["reboot-bootloader"])
        case .fastbootd, .recovery:
            return try run(arguments: ["reboot", target.rawValue])
        }
    }

    private func run(arguments: [String]) throws -> String {
        guard let executable = FastbootExecutableLocator.locate() else {
            throw FastbootServiceError.executableMissing
        }

        let effectiveArgs: [String]
        if let serial = selectedSerial, !serial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, serial != "-" {
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
