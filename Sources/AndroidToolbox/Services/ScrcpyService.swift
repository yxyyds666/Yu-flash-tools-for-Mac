import Foundation

enum ScrcpyServiceError: Error {
    case executableMissing
    case launchFailed(String)
}

final class ScrcpyService: Sendable {
    private let state = ScrcpyState()

    var isRunning: Bool {
        state.isRunning
    }

    func locate() -> URL? {
        if let bundled = Bundle.main.url(forResource: "scrcpy", withExtension: nil, subdirectory: "Tools") {
            return bundled
        }

        let candidates = [
            "/opt/homebrew/bin/scrcpy",
            "/usr/local/bin/scrcpy",
            "/usr/bin/scrcpy"
        ]

        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }

        if let pathValue = ProcessInfo.processInfo.environment["PATH"] {
            for directory in pathValue.split(separator: ":").map(String.init) {
                let candidate = URL(fileURLWithPath: directory).appendingPathComponent("scrcpy").path
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return URL(fileURLWithPath: candidate)
                }
            }
        }

        return nil
    }

    func start(
        deviceSerial: String? = nil,
        maxSize: Int? = nil,
        bitRate: Int? = nil,
        turnScreenOff: Bool = false,
        maxFPS: Int? = nil,
        fullscreen: Bool = false,
        alwaysOnTop: Bool = false,
        noAudio: Bool = false,
        noControl: Bool = false,
        showTouches: Bool = false,
        windowTitle: String? = nil,
        onTerminate: (@Sendable (Int32, String) -> Void)? = nil
    ) async throws {
        guard let executable = locate() else {
            throw ScrcpyServiceError.executableMissing
        }

        if state.isRunning {
            return
        }

        var args: [String] = []
        if let deviceSerial, !deviceSerial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args += ["-s", deviceSerial]
        }
        if let maxSize {
            args += ["--max-size", "\(maxSize)"]
        }
        if let bitRate {
            args += ["--video-bit-rate", "\(bitRate)M"]
        }
        if turnScreenOff {
            args.append("--turn-screen-off")
        }
        if let maxFPS {
            args += ["--max-fps", "\(maxFPS)"]
        }
        if fullscreen {
            args.append("--fullscreen")
        }
        if alwaysOnTop {
            args.append("--always-on-top")
        }
        if noAudio {
            args.append("--no-audio")
        }
        if noControl {
            args.append("--no-control")
        }
        if showTouches {
            args.append("--show-touches")
        }
        if let windowTitle, !windowTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args += ["--window-title", windowTitle]
        }
        if !noControl {
            args.append("--stay-awake")
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = args

        if let bundledServer = Bundle.main.url(forResource: "scrcpy-server", withExtension: nil, subdirectory: "Tools") {
            var env = ProcessInfo.processInfo.environment
            env["SCRCPY_SERVER_PATH"] = bundledServer.path
            process.environment = env
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Buffer output via readabilityHandler so termination can flush a
        // useful tail back to the caller without risking pipe buffer deadlock.
        let buffer = OutputBuffer()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            buffer.append(chunk)
        }

        process.terminationHandler = { [state] proc in
            pipe.fileHandleForReading.readabilityHandler = nil
            if let tail = try? pipe.fileHandleForReading.readToEnd(), !tail.isEmpty {
                buffer.append(tail)
            }
            state.clear()
            onTerminate?(proc.terminationStatus, buffer.snapshot())
        }

        do {
            try process.run()
        } catch {
            throw ScrcpyServiceError.launchFailed(error.localizedDescription)
        }

        state.set(process: process)

        // Give scrcpy a brief moment to fail-fast (missing device, bad args,
        // missing scrcpy-server). 350ms matches the prior threshold.
        try? await Task.sleep(nanoseconds: 350_000_000)

        if !process.isRunning {
            let output = buffer.snapshot()
            throw ScrcpyServiceError.launchFailed(output.isEmpty ? "scrcpy exited immediately" : output)
        }
    }

    func stop() {
        state.terminate()
    }
}

private final class ScrcpyState: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return process?.isRunning ?? false
    }

    func set(process: Process) {
        lock.lock(); defer { lock.unlock() }
        self.process = process
    }

    func clear() {
        lock.lock(); defer { lock.unlock() }
        process = nil
    }

    func terminate() {
        lock.lock()
        let p = process
        process = nil
        lock.unlock()
        p?.terminate()
    }
}

private final class OutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock(); defer { lock.unlock() }
        data.append(chunk)
    }

    func snapshot() -> String {
        lock.lock(); defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }
}
