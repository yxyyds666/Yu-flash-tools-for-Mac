import Foundation
import Observation

struct FastbootRebootAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let target: FastbootRebootTarget
}

enum FastbootFlashMode: String, CaseIterable, Identifiable {
    case generic
    case xiaomi
    case oplusRealme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .generic:
            return "通用刷机"
        case .xiaomi:
            return "小米机型刷写"
        case .oplusRealme:
            return "欧加真机型刷写"
        }
    }

    var subtitle: String {
        switch self {
        case .generic:
            return "适合标准 fastboot 分区刷写流程"
        case .xiaomi:
            return "面向小米 / Redmi / POCO 常见包结构"
        case .oplusRealme:
            return "面向 OPPO / OnePlus / realme 真机刷写流程"
        }
    }

    var systemImage: String {
        switch self {
        case .generic:
            return "shippingbox.fill"
        case .xiaomi:
            return "bolt.horizontal.circle.fill"
        case .oplusRealme:
            return "cpu.fill"
        }
    }
}

@Observable
@MainActor
final class FastbootViewModel {
    var devices: [DeviceInfo] = []
    var selectedDevice: DeviceInfo = .disconnected
    var varKey: String = "product"
    var logs: String = ""
    var isAutoRefreshing: Bool = false
    var isBusy: Bool = false

    // MARK: - Generic flash state
    var customImagePath: String = ""
    var customPartitionText: String = "boot"

    let genericPartitions: [String] = [
        "boot", "vendor_boot", "dtbo", "vbmeta", "super",
        "recovery", "init_boot", "vendor_kernel_boot", "system", "odm"
    ]

    var canFlashGeneric: Bool {
        !customImagePath.trimmingCharacters(in: .whitespaces).isEmpty
            && !customPartitionText.trimmingCharacters(in: .whitespaces).isEmpty
            && canExecuteCommand
    }

    var genericFlashImageFileName: String {
        let path = customImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return "未选择镜像" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    var genericFlashCommandPreview: String {
        let partition = customPartitionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = customImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let serial = selectedDevice.serial == "-" ? "<serial>" : selectedDevice.serial
        return "fastboot -s \(serial) flash \(partition.isEmpty ? "<partition>" : partition) \(image.isEmpty ? "<image>" : image)"
    }

    let rebootActions: [FastbootRebootAction] = [
        .init(title: "重启系统", subtitle: "fastboot reboot", target: .system),
        .init(title: "重启 Bootloader", subtitle: "fastboot reboot-bootloader", target: .bootloader),
        .init(title: "重启 Fastbootd", subtitle: "fastboot reboot fastboot", target: .fastbootd),
        .init(title: "重启 Recovery", subtitle: "fastboot reboot recovery", target: .recovery)
    ]

    let flashModes = FastbootFlashMode.allCases

    var canExecuteCommand: Bool {
        selectedDevice.serial != "-" && selectedDevice.state == "fastboot"
    }

    private let service: FastbootService
    private var refreshTimer: Timer?
    private var isRefreshingDevices = false
    private let appLogStore: AppLogStore

    private var selectedFastbootSerial: String? {
        let serial = selectedDevice.serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return serial.isEmpty || serial == "-" ? nil : serial
    }

    init(service: FastbootService = FastbootService(), appLogStore: AppLogStore = AppLogStore()) {
        self.service = service
        self.appLogStore = appLogStore
    }

    func refreshDevices() {
        Task { await refreshDevices(showLog: true) }
    }

    func startAutoRefresh() {
        guard refreshTimer == nil else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshDevices(showLog: false)
            }
        }
        timer.tolerance = 0.2
        refreshTimer = timer
        isAutoRefreshing = true

        Task { await refreshDevices(showLog: false) }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        isAutoRefreshing = false
    }

    func selectDevice(_ device: DeviceInfo) {
        selectedDevice = device
        appendLog("[设备] 已切换：\(device.serial)（\(device.model)）")
    }

    func readVar() {
        guard !varKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard ensureDeviceReady() else { return }

        let service = service
        let key = varKey
        let serial = selectedFastbootSerial
        Task { [weak self] in
            self?.isBusy = true
            defer { self?.isBusy = false }
            do {
                let result = try await service.getVar(key, serial: serial)
                self?.appendLog("[getvar] \(key)\n\(result)")
            } catch {
                self?.appendLog("[getvar] 失败：\(error.localizedDescription)")
            }
        }
    }

    func reboot(to target: FastbootRebootTarget, label: String) {
        guard ensureDeviceReady() else { return }

        let service = service
        let serial = selectedFastbootSerial
        Task { [weak self] in
            self?.isBusy = true
            defer { self?.isBusy = false }
            do {
                let result = try await service.reboot(target, serial: serial)
                self?.appendLog("[重启] \(label)\n\(result)")
            } catch {
                self?.appendLog("[重启] \(label) 失败：\(error.localizedDescription)")
            }
        }
    }

    func flashGeneric(imagePath: String, partition: String) {
        guard ensureDeviceReady() else { return }

        switch GenericFastbootFlashValidation.validate(imagePath: imagePath, partition: partition) {
        case .valid:
            break
        case .invalid(let message):
            appendLog("[刷写] 失败：\(message)")
            return
        }

        let service = service
        let serial = selectedFastbootSerial
        let deviceSerial = selectedDevice.serial
        Task { [weak self] in
            self?.isBusy = true
            defer { self?.isBusy = false }
            do {
                let url = URL(fileURLWithPath: imagePath)
                self?.appendLog("[刷写] 开始\n设备：\(deviceSerial)\n分区：\(partition)\n镜像：\(imagePath)")
                let result = try await service.flash(partition: partition, image: url, serial: serial)
                self?.appendLog("[刷写] 分区「\(partition)」刷入完成\n\(result)")
            } catch {
                self?.appendLog("[刷写] 分区「\(partition)」刷入失败：\(error.localizedDescription)")
            }
        }
    }

    private func ensureDeviceReady() -> Bool {
        guard canExecuteCommand else {
            appendLog("[Fastboot] 失败：请先连接并选择一台 fastboot 设备")
            return false
        }
        return true
    }

    private func refreshDevices(showLog: Bool) async {
        guard !isRefreshingDevices else { return }
        isRefreshingDevices = true
        defer { isRefreshingDevices = false }

        do {
            let list = try await service.listDevices(serial: selectedFastbootSerial)
            devices = list

            if let matched = list.first(where: { $0.serial == selectedDevice.serial }) {
                selectedDevice = matched
            } else {
                selectedDevice = list.first ?? .disconnected
            }

            if showLog {
                appendLog("[fastboot devices] 刷新完成：共 \(list.count) 台")
            }
        } catch {
            if showLog {
                appendLog("[fastboot devices] 刷新失败：\(error.localizedDescription)")
            }
        }
    }

    private func appendLog(_ entry: String) {
        logs = logs.isEmpty ? entry : logs + "\n\n" + entry
        appLogStore.append(source: "Fastboot", message: entry)
    }
}
