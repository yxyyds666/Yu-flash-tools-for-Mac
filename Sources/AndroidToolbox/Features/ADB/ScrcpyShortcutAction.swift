import Foundation

enum ScrcpyShortcutAction: CaseIterable, Identifiable {
    case stop
    case screenshot
    case home
    case back
    case recents
    case power
    case volumeUp
    case volumeDown

    var id: String { title }

    var title: String {
        switch self {
        case .stop:
            return "停止"
        case .screenshot:
            return "截图"
        case .home:
            return "Home"
        case .back:
            return "Back"
        case .recents:
            return "最近"
        case .power:
            return "电源"
        case .volumeUp:
            return "音量+"
        case .volumeDown:
            return "音量-"
        }
    }

    var systemImage: String {
        switch self {
        case .stop:
            return "stop.fill"
        case .screenshot:
            return "camera.fill"
        case .home:
            return "house.fill"
        case .back:
            return "chevron.left"
        case .recents:
            return "square.on.square"
        case .power:
            return "power"
        case .volumeUp:
            return "speaker.wave.2.fill"
        case .volumeDown:
            return "speaker.wave.1.fill"
        }
    }

    var adbKeyEvent: Int? {
        switch self {
        case .home:
            return 3
        case .back:
            return 4
        case .recents:
            return 187
        case .power:
            return 26
        case .volumeUp:
            return 24
        case .volumeDown:
            return 25
        case .stop, .screenshot:
            return nil
        }
    }
}
