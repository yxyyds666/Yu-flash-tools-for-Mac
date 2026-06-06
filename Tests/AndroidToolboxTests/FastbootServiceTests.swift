import Foundation
import Testing
@testable import AndroidToolbox

private final class FastbootMockProcessRunner: ProcessRunning, @unchecked Sendable {
    var nextResult: ProcessRunnerResult = .init(output: "", exitCode: 0)
    private(set) var capturedArguments: [String] = []
    private(set) var capturedTimeout: TimeInterval?

    func run(executable: URL, arguments: [String], timeout: TimeInterval) async throws -> ProcessRunnerResult {
        capturedArguments = arguments
        capturedTimeout = timeout
        return nextResult
    }
}

@Test
func fastbootService_listDevices_withExplicitSerial_injectsDashS() async throws {
    let runner = FastbootMockProcessRunner()
    runner.nextResult = .init(output: "device-1\tfastboot", exitCode: 0)
    let service = FastbootService(runner: runner, resolveExecutable: { URL(fileURLWithPath: "/tmp/fastboot") })

    _ = try await service.listDevices(serial: "device-1")

    #expect(runner.capturedArguments == ["-s", "device-1", "devices"])
}

@Test
func fastbootService_flash_usesLongTimeoutAndExplicitSerial() async throws {
    let runner = FastbootMockProcessRunner()
    let service = FastbootService(runner: runner, resolveExecutable: { URL(fileURLWithPath: "/tmp/fastboot") })

    _ = try await service.flash(partition: "boot", image: URL(fileURLWithPath: "/tmp/boot.img"), serial: "device-1")

    #expect(runner.capturedArguments == ["-s", "device-1", "flash", "boot", "/tmp/boot.img"])
    #expect(runner.capturedTimeout == 300)
}
