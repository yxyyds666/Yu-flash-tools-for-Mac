import Foundation

enum ProcessRunnerError: Error {
    case launchFailed(String)
    case timedOut
}

struct ProcessRunnerResult {
    let output: String
    let exitCode: Int32
}

protocol ProcessRunning {
    func run(executable: URL, arguments: [String], timeout: TimeInterval) throws -> ProcessRunnerResult
}

final class ProcessRunner: ProcessRunning {
    func run(executable: URL, arguments: [String], timeout: TimeInterval = 20) throws -> ProcessRunnerResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.launchFailed(error.localizedDescription)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning {
            if Date() > deadline {
                process.terminate()
                throw ProcessRunnerError.timedOut
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile() + stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        return ProcessRunnerResult(output: output, exitCode: process.terminationStatus)
    }
}
