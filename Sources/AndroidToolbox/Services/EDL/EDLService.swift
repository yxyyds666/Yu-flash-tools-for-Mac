import Foundation

enum EDLServiceError: Error {
    case executableMissing
    case commandFailed(String)
}

final class EDLService: Sendable {
    private let runner: any ProcessRunning

    init(runner: any ProcessRunning = ProcessRunner()) {
        self.runner = runner
    }

    func probe() async -> [DeviceInfo] {
        let ioregDevices = await detectFromIORegistry()
        if !ioregDevices.isEmpty {
            return ioregDevices
        }

        if let output = try? await run(arguments: ["--version"]) {
            return [DeviceInfo(serial: "EDL", model: "Qualcomm 9008", state: output.isEmpty ? "ready" : "ready")]
        }

        return []
    }

    func runRawCommand(_ commandLine: String) async throws -> String {
        let parts = commandLine
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .map(String.init)
        guard !parts.isEmpty else { return "" }
        return try await run(arguments: parts)
    }

    private func detectFromIORegistry() async -> [DeviceInfo] {
        let ioreg = URL(fileURLWithPath: "/usr/sbin/ioreg")
        guard FileManager.default.isExecutableFile(atPath: ioreg.path) else { return [] }

        guard let result = try? await runner.run(executable: ioreg, arguments: ["-p", "IOUSB", "-l"], timeout: 20) else {
            return []
        }

        return EDLParser.parseIOReg(result.output)
    }

    private func run(arguments: [String]) async throws -> String {
        guard let executable = EDLExecutableLocator.locate() else {
            throw EDLServiceError.executableMissing
        }

        let result = try await runner.run(executable: executable, arguments: arguments, timeout: 20)
        guard result.exitCode == 0 else {
            throw EDLServiceError.commandFailed(result.output)
        }

        return result.output
    }
}
