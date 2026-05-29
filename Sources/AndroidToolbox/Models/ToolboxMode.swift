import Foundation

enum ToolboxMode: String, CaseIterable, Identifiable {
    case adb = "ADB 模式"
    case fastboot = "Fastboot 模式"
    case edl = "EDL 模式 (9008)"

    var id: String { rawValue }

    var isAvailable: Bool {
        switch self {
        case .adb, .fastboot:
            return true
        case .edl:
            return false
        }
    }
}
