import Foundation

enum ADBParser {
    static func parseDevices(from output: String) -> [DeviceInfo] {
        output
            .split(separator: "\n")
            .map(String.init)
            .drop { $0.trimmingCharacters(in: .whitespaces).isEmpty || $0.hasPrefix("List of devices attached") }
            .compactMap(parseDeviceLine)
    }

    private static func parseDeviceLine(_ line: String) -> DeviceInfo? {
        let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard parts.count >= 2 else { return nil }

        let serial = parts[0]
        let state = parts[1]
        let model = parts
            .first(where: { $0.hasPrefix("model:") })?
            .replacingOccurrences(of: "model:", with: "") ?? "Unknown"

        return DeviceInfo(serial: serial, model: model, state: state)
    }
}
