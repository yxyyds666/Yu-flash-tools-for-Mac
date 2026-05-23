import Foundation

enum FastbootParser {
    static func parseDevices(from output: String) -> [DeviceInfo] {
        output
            .split(separator: "\n")
            .map(String.init)
            .compactMap(parseDeviceLine)
    }

    private static func parseDeviceLine(_ line: String) -> DeviceInfo? {
        let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard parts.count >= 2 else { return nil }

        let serial = parts[0]
        let state = parts[1]
        return DeviceInfo(serial: serial, model: "Fastboot Device", state: state)
    }
}
