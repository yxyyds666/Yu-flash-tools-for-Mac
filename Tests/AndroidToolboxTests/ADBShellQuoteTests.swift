import Foundation
import Testing
@testable import AndroidToolbox

private final class CapturingRunner: ProcessRunning, @unchecked Sendable {
    var nextResult: ProcessRunnerResult = .init(output: "", exitCode: 0)
    private(set) var capturedArguments: [String] = []

    func run(executable: URL, arguments: [String], timeout: TimeInterval) async throws -> ProcessRunnerResult {
        capturedArguments = arguments
        return nextResult
    }
}

private func makeService(_ runner: CapturingRunner) -> ADBService {
    ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )
}

@Test
func adbShellQuote_wrapsPlainStringInSingleQuotes() {
    #expect(ADBShell.quote("/sdcard") == "'/sdcard'")
}

@Test
func adbShellQuote_escapesEmbeddedSingleQuote() {
    #expect(ADBShell.quote("ab'cd") == "'ab'\\''cd'")
}

@Test
func adbShellQuote_passesSpacesAndDollarThrough() {
    #expect(ADBShell.quote("/sd card/$HOME") == "'/sd card/$HOME'")
}

@Test
func adbService_listRemoteDirectory_quotesPathWithSpaces() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.listRemoteDirectory(path: "/sdcard/My Documents")

    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard/My Documents'"])
}

@Test
func adbService_listRemoteDirectory_neutralizesCommandSubstitution() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.listRemoteDirectory(path: "/sdcard/$(rm -rf /)")

    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard/$(rm -rf /)'"])
}

@Test
func adbService_listRemoteDirectory_neutralizesBacktickExecution() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.listRemoteDirectory(path: "/sdcard/`reboot`")

    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard/`reboot`'"])
}

@Test
func adbService_listRemoteDirectory_neutralizesSemicolonChain() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.listRemoteDirectory(path: "/sdcard; rm -rf /")

    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard; rm -rf /'"])
}

@Test
func adbService_listRemoteDirectory_neutralizesNewlineInjection() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.listRemoteDirectory(path: "/sdcard\nrm -rf /")

    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard\nrm -rf /'"])
}

@Test
func adbService_grantPermission_quotesArguments() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.grantPermission(
        packageName: "com.example.app",
        permission: "android.permission.CAMERA"
    )

    #expect(runner.capturedArguments == [
        "shell",
        "pm grant 'com.example.app' 'android.permission.CAMERA'"
    ])
}

@Test
func adbService_revokePermission_quotesArguments() async throws {
    let runner = CapturingRunner()
    let service = makeService(runner)

    _ = try await service.revokePermission(
        packageName: "com.example.app; rm -rf /",
        permission: "android.permission.CAMERA"
    )

    #expect(runner.capturedArguments == [
        "shell",
        "pm revoke 'com.example.app; rm -rf /' 'android.permission.CAMERA'"
    ])
}
