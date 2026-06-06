import Foundation
import Testing
@testable import AndroidToolbox

private final class MockProcessRunner: ProcessRunning, @unchecked Sendable {
    var nextResult: ProcessRunnerResult = .init(output: "", exitCode: 0)
    var nextError: Error?
    private(set) var capturedExecutable: URL?
    private(set) var capturedArguments: [String] = []

    func run(executable: URL, arguments: [String], timeout: TimeInterval) async throws -> ProcessRunnerResult {
        capturedExecutable = executable
        capturedArguments = arguments

        if let nextError {
            throw nextError
        }

        return nextResult
    }
}

@Test
func adbService_listDevices_parsesOutputAndInvokesRunner() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(
        output: """
        List of devices attached
        emulator-5554\tdevice product:sdk model:sdk_gphone device:emu transport_id:1
        """,
        exitCode: 0
    )

    let executable = URL(fileURLWithPath: "/tmp/adb")
    let service = ADBService(runner: runner, resolveExecutable: { executable })

    let list = try await service.listDevices()

    #expect(list.devices.count == 1)
    #expect(list.devices[0].serial == "emulator-5554")
    #expect(runner.capturedExecutable?.path == "/tmp/adb")
    #expect(runner.capturedArguments == ["devices", "-l"])
}

@Test
func adbService_listDevices_throwsWhenExecutableMissing() async {
    let runner = MockProcessRunner()
    let service = ADBService(runner: runner, resolveExecutable: { nil })

    do {
        _ = try await service.listDevices()
        Issue.record("Expected executableMissing error")
    } catch let error as ADBServiceError {
        switch error {
        case .executableMissing:
            break
        case .commandFailed:
            Issue.record("Expected executableMissing, got commandFailed")
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func adbService_runShell_throwsCommandFailedWhenExitCodeNonZero() async {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "permission denied", exitCode: 1)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    do {
        _ = try await service.runShell("id")
        Issue.record("Expected commandFailed error")
    } catch let error as ADBServiceError {
        switch error {
        case .commandFailed(let output):
            #expect(output == "permission denied")
        case .executableMissing:
            Issue.record("Expected commandFailed, got executableMissing")
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func adbService_runShell_withExplicitSerial_injectsDashS() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "", exitCode: 0)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    _ = try await service.runShell("id", serial: "abc123")

    #expect(runner.capturedArguments == ["-s", "abc123", "shell", "id"])
}

@Test
func adbService_runShell_withExplicitSerial_injectsDashSWithoutMutableServiceState() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "", exitCode: 0)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    _ = try await service.runShell("id", serial: "abc123")
    _ = try await service.runShell("id")

    #expect(runner.capturedArguments == ["shell", "id"])
}

@Test
func adbService_runShell_withoutSelectedSerial_omitsDashS() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "", exitCode: 0)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )
    _ = try await service.runShell("id")

    #expect(runner.capturedArguments == ["shell", "id"])
}

@Test
func adbService_listRemoteDirectory_parsesAndSortsEntries() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(
        output: """
        .
        ..
        Download/
        Movies/
        a.txt
        z.txt
        """,
        exitCode: 0
    )

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    let entries = try await service.listRemoteDirectory(path: "/sdcard")

    #expect(entries.map(\.name) == ["Download", "Movies", "a.txt", "z.txt"])
    #expect(entries[0].isDirectory)
    #expect(entries[2].isDirectory == false)
    #expect(entries[0].path == "/sdcard/Download")
    #expect(runner.capturedArguments == ["shell", "ls -a -p -- '/sdcard'"])
}

@Test
func adbService_listRemoteDirectory_asRoot_usesSuCommand() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "", exitCode: 0)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    _ = try await service.listRemoteDirectory(path: "/system", asRoot: true)

    #expect(runner.capturedArguments == ["shell", "su", "-c", "ls -a -p -- '/system'"])
}

@Test
func adbService_listRemoteDirectory_asRoot_quotesSpecialPath() async throws {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "", exitCode: 0)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    _ = try await service.listRemoteDirectory(path: "/data/local/tmp/ab c'd", asRoot: true)

    #expect(runner.capturedArguments == ["shell", "su", "-c", "ls -a -p -- '/data/local/tmp/ab c'\\''d'"])
}

@Test
func adbService_listRemoteDirectory_asRoot_propagatesCommandFailure() async {
    let runner = MockProcessRunner()
    runner.nextResult = .init(output: "su: inaccessible or not found", exitCode: 1)

    let service = ADBService(
        runner: runner,
        resolveExecutable: { URL(fileURLWithPath: "/tmp/adb") }
    )

    do {
        _ = try await service.listRemoteDirectory(path: "/", asRoot: true)
        Issue.record("Expected commandFailed error")
    } catch let error as ADBServiceError {
        switch error {
        case .commandFailed(let output):
            #expect(output == "su: inaccessible or not found")
        case .executableMissing:
            Issue.record("Expected commandFailed, got executableMissing")
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
