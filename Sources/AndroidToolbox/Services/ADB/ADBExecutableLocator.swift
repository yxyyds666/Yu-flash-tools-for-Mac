import Foundation

enum ADBExecutableLocator {
    static func locate() -> URL? {
        if let bundled = Bundle.module.url(forResource: "adb", withExtension: nil, subdirectory: "Tools") {
            return bundled
        }

        let fileManager = FileManager.default
        let fallbackCandidates = [
            "/usr/bin/adb",
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb"
        ]

        for candidate in fallbackCandidates {
            if fileManager.isExecutableFile(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }

        if let pathValue = ProcessInfo.processInfo.environment["PATH"] {
            for directory in pathValue.split(separator: ":").map(String.init) {
                let candidate = URL(fileURLWithPath: directory).appendingPathComponent("adb").path
                if fileManager.isExecutableFile(atPath: candidate) {
                    return URL(fileURLWithPath: candidate)
                }
            }
        }

        return nil
    }
}
