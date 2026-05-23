import Foundation

enum EDLServiceError: Error {
    case executableMissing
    case commandFailed(String)
}

final class EDLService {
    private let runner: ProcessRunner

    init(runner: ProcessRunner = ProcessRunner()) {
        self.runner = runner
    }

    func probe() -> [DeviceInfo] {
        let ioregDevices = detectFromIORegistry()
        if !ioregDevices.isEmpty {
            return ioregDevices
        }

        if let output = try? run(arguments: ["--version"]) {
            return [DeviceInfo(serial: "EDL", model: "Qualcomm 9008", state: output.isEmpty ? "ready" : "ready")]
        }

        return []
    }

    func runRawCommand(_ commandLine: String) throws -> String {
        let parts = commandLine
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .map(String.init)
        guard !parts.isEmpty else { return "" }
        return try run(arguments: parts)
    }

    private func detectFromIORegistry() -> [DeviceInfo] {
        let ioreg = URL(fileURLWithPath: "/usr/sbin/ioreg")
        guard FileManager.default.isExecutableFile(atPath: ioreg.path) else { return [] }

        guard let result = try? runner.run(executable: ioreg, arguments: ["-p", "IOUSB", "-l"]) else {
            return []
        }

        return EDLParser.parseIOReg(result.output)
    }

    private func run(arguments: [String]) throws -> String {
        guard let executable = EDLExecutableLocator.locate() else {
            throw EDLServiceError.executableMissing
        }

        let result = try runner.run(executable: executable, arguments: arguments)
        guard result.exitCode == 0 else {
            throw EDLServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
