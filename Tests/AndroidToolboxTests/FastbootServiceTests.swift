import Foundation
import Testing
@testable import AndroidToolbox

private final class FastbootMockProcessRunner: ProcessRunning, @unchecked Sendable {
    var nextResult: ProcessRunnerResult = .init(output: "", exitCode: 0)
    private(set) var capturedArguments: [String] = []

    func run(executable: URL, arguments: [String], timeout: TimeInterval) throws -> ProcessRunnerResult {
        capturedArguments = arguments
        return nextResult
    }
}

@Test
func fastbootService_listDevices_withExplicitSerial_injectsDashS() throws {
    let runner = FastbootMockProcessRunner()
    runner.nextResult = .init(output: "device-1\tfastboot", exitCode: 0)
    let service = FastbootService(runner: runner, resolveExecutable: { URL(fileURLWithPath: "/tmp/fastboot") })

    _ = try service.listDevices(serial: "device-1")

    #expect(runner.capturedArguments == ["-s", "device-1", "devices"])
}
