import Foundation
import Observation

@MainActor
@Observable
final class AppLogStore {
    var entries: [String] = []

    var combinedText: String {
        entries.joined(separator: "\n")
    }

    func append(source: String, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let normalized = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        entries.append("[\(timestamp)] [\(source)] \(normalized)")
    }

    func clear() {
        entries.removeAll()
    }
}
