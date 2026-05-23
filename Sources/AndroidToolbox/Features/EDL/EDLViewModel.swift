import Foundation
import Observation

@Observable
@MainActor
final class EDLViewModel {
    var devices: [DeviceInfo] = []
    var selectedDevice: DeviceInfo = .disconnected
    var rawCommand: String = ""
    var logs: String = ""

    private let service: EDLService
    private let appLogStore: AppLogStore

    init(service: EDLService = EDLService(), appLogStore: AppLogStore = AppLogStore()) {
        self.service = service
        self.appLogStore = appLogStore
    }

    func refreshDevices() {
        let list = service.probe()
        devices = list
        selectedDevice = list.first ?? .disconnected
        appendLog("[edl probe] refreshed: \(list.count) device(s)")
    }

    func runRawCommand() {
        guard !rawCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let output = try service.runRawCommand(rawCommand)
            appendLog("[edl] \(rawCommand)\n\(output)")
        } catch {
            appendLog("[edl] error: \(error.localizedDescription)")
        }
    }

    private func appendLog(_ entry: String) {
        logs = logs.isEmpty ? entry : logs + "\n\n" + entry
        appLogStore.append(source: "EDL", message: entry)
    }
}
