import Foundation

enum EDLExecutableLocator {
    static func locate() -> URL? {
        if let bundled = Bundle.module.url(forResource: "edl", withExtension: nil, subdirectory: "Tools") {
            return bundled
        }

        let candidates = [
            "/usr/local/bin/edl",
            "/opt/homebrew/bin/edl",
            "/usr/bin/edl"
        ]

        return candidates
            .map(URL.init(fileURLWithPath:))
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
    }
}
