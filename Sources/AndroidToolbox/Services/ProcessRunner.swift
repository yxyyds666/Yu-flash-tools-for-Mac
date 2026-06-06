import Foundation

enum ProcessRunnerError: Error {
    case launchFailed(String)
    case timedOut
}

struct ProcessRunnerResult: Sendable {
    let output: String
    let exitCode: Int32
}

protocol ProcessRunning: Sendable {
    func run(executable: URL, arguments: [String], timeout: TimeInterval) async throws -> ProcessRunnerResult
}

final class ProcessRunner: ProcessRunning, Sendable {
    func run(executable: URL, arguments: [String], timeout: TimeInterval = 20) async throws -> ProcessRunnerResult {
        let state = ProcessRunnerState()
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        let appendChunk: @Sendable (FileHandle) -> Void = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            state.append(chunk)
        }
        stdout.fileHandleForReading.readabilityHandler = appendChunk
        stderr.fileHandleForReading.readabilityHandler = appendChunk

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ProcessRunnerResult, Error>) in
                let resumeOnce: @Sendable (Result<ProcessRunnerResult, Error>) -> Void = { result in
                    guard state.markResumedIfNeeded() else { return }
                    stdout.fileHandleForReading.readabilityHandler = nil
                    stderr.fileHandleForReading.readabilityHandler = nil
                    if let tail = try? stdout.fileHandleForReading.readToEnd(), !tail.isEmpty {
                        state.append(tail)
                    }
                    if let tail = try? stderr.fileHandleForReading.readToEnd(), !tail.isEmpty {
                        state.append(tail)
                    }
                    continuation.resume(with: result)
                }

                process.terminationHandler = { proc in
                    let output = state.snapshot()
                    resumeOnce(.success(ProcessRunnerResult(output: output, exitCode: proc.terminationStatus)))
                }

                do {
                    try process.run()
                } catch {
                    resumeOnce(.failure(ProcessRunnerError.launchFailed(error.localizedDescription)))
                    return
                }

                if timeout > 0 {
                    let deadline = DispatchTime.now() + .milliseconds(Int(timeout * 1000))
                    DispatchQueue.global().asyncAfter(deadline: deadline) {
                        guard process.isRunning else { return }
                        process.terminate()
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                            resumeOnce(.failure(ProcessRunnerError.timedOut))
                        }
                    }
                }
            }
        } onCancel: {
            if process.isRunning {
                process.terminate()
            }
        }
    }
}

private final class ProcessRunnerState: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private var resumed = false

    func append(_ data: Data) {
        lock.lock(); defer { lock.unlock() }
        buffer.append(data)
    }

    func snapshot() -> String {
        lock.lock(); defer { lock.unlock() }
        return String(decoding: buffer, as: UTF8.self)
    }

    func markResumedIfNeeded() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if resumed { return false }
        resumed = true
        return true
    }
}
