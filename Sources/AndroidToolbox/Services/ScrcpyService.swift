import Foundation

enum ScrcpyServiceError: Error {
    case executableMissing
    case launchFailed(String)
}

final class ScrcpyService {
    private var process: Process?
    private var outputPipe: Pipe?

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    func locate() -> URL? {
        if let bundled = Bundle.module.url(forResource: "scrcpy", withExtension: nil, subdirectory: "Tools") {
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
    ) throws {
        guard let executable = locate() else {
            throw ScrcpyServiceError.executableMissing
        }

        if process?.isRunning == true {
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

        if let bundledServer = Bundle.module.url(forResource: "scrcpy-server", withExtension: nil, subdirectory: "Tools") {
            var env = ProcessInfo.processInfo.environment
            env["SCRCPY_SERVER_PATH"] = bundledServer.path
            process.environment = env
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        outputPipe = pipe

        do {
            try process.run()
            Thread.sleep(forTimeInterval: 0.35)
            if !process.isRunning {
                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outputData, as: UTF8.self)
                throw ScrcpyServiceError.launchFailed(output.isEmpty ? "scrcpy exited immediately" : output)
            }
            self.process = process
            if let onTerminate {
                Thread.detachNewThread {
                    process.waitUntilExit()
                    let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(decoding: outputData, as: UTF8.self)
                    onTerminate(process.terminationStatus, output)
                }
            }
        } catch let error as ScrcpyServiceError {
            throw error
        } catch {
            throw ScrcpyServiceError.launchFailed(error.localizedDescription)
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        outputPipe = nil
    }
}
