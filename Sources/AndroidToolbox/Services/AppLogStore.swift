import Foundation
import Observation

@MainActor
@Observable
final class AppLogStore {
    var entries: [String] = []
    private let maxEntries: Int
    private let formatter: DateFormatter

    init(maxEntries: Int = 500) {
        self.maxEntries = maxEntries
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.formatter = formatter
    }

    var combinedText: String {
        entries.joined(separator: "\n")
    }

    func append(source: String, message: String) {
        let timestamp = formatter.string(from: Date())
        let normalized = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        entries.append("[\(timestamp)] [\(source)] \(normalized)")
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }
}
