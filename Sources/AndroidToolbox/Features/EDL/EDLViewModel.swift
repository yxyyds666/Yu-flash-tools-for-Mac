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
        let service = service
        Task { [weak self] in
            let list = await service.probe()
            guard let self else { return }
            self.devices = list
            self.selectedDevice = list.first ?? .disconnected
            self.appendLog("[edl probe] refreshed: \(list.count) device(s)")
        }
    }

    func runRawCommand() {
        let command = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        let service = service
        Task { [weak self] in
            do {
                let output = try await service.runRawCommand(command)
                self?.appendLog("[edl] \(command)\n\(output)")
            } catch {
                self?.appendLog("[edl] error: \(error.localizedDescription)")
            }
        }
    }

    private func appendLog(_ entry: String) {
        logs = logs.isEmpty ? entry : logs + "\n\n" + entry
        appLogStore.append(source: "EDL", message: entry)
    }
}
