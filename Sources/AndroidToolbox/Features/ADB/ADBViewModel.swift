import Foundation
import Observation
import AppKit

struct ADBRebootAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let target: ADBRebootTarget
}

struct ADBFileEntry: Identifiable {
    let path: String
    let name: String
    let isDirectory: Bool

    var id: String { path }
}

struct InstalledApp: Identifiable {
    let packageName: String
    let appName: String
    var id: String { packageName }
}

enum ScrcpyPreset {
    case smooth
    case balanced
    case highDefinition
}

@Observable
@MainActor
final class ADBViewModel {
    var devices: [DeviceInfo] = []
    var selectedDevice: DeviceInfo = .disconnected
    var shellCommand: String = ""
    var apkPath: String = ""
    var uninstallPackageName: String = ""
    var installedApps: [InstalledApp] = []
    var pullRemotePath: String = ""
    var pullLocalPath: String = ""
    var pushLocalPath: String = ""
    var pushRemotePath: String = ""
    var logs: String = ""
    var isAutoRefreshing: Bool = false
    var isScrcpyRunning: Bool = false
    var scrcpyMaxSize: Int = 1024
    var scrcpyBitRate: Int = 8
    var scrcpyTurnScreenOff: Bool = false
    var scrcpyMaxFPS: Int = 60
    var scrcpyFullscreen: Bool = false
    var scrcpyAlwaysOnTop: Bool = false
    var scrcpyNoAudio: Bool = false
    var scrcpyNoControl: Bool = false
    var scrcpyShowTouches: Bool = false
    var scrcpyWindowTitle: String = "Yu 工具箱"

    var localCurrentPath: String = NSHomeDirectory()
    var remoteCurrentPath: String = "/sdcard"
    var localEntries: [ADBFileEntry] = []
    var remoteEntries: [ADBFileEntry] = []
    var selectedLocalPath: String = ""
    var selectedRemotePath: String = ""
    var isRootModeEnabled: Bool = false

    var canPushSelected: Bool {
        guard !selectedLocalPath.isEmpty else { return false }
        return localEntries.first(where: { $0.path == selectedLocalPath })?.isDirectory == false
    }

    var canPullSelected: Bool {
        guard !selectedRemotePath.isEmpty else { return false }
        return remoteEntries.first(where: { $0.path == selectedRemotePath })?.isDirectory == false
    }

    let rebootActions: [ADBRebootAction] = [
        .init(title: "重启系统", subtitle: "adb reboot", target: .system),
        .init(title: "重启 Fastboot", subtitle: "adb reboot fastboot", target: .fastboot),
        .init(title: "重启 Bootloader", subtitle: "adb reboot bootloader", target: .bootloader),
        .init(title: "重启 EDL", subtitle: "adb reboot edl", target: .edl),
        .init(title: "重启 Recovery", subtitle: "adb reboot recovery", target: .recovery),
        .init(title: "重启 Sideload", subtitle: "adb reboot sideload", target: .sideload)
    ]

    private let service: ADBService
    private let scrcpyService: ScrcpyService
    private let scrcpyShortcutPanelController = ScrcpyShortcutPanelController()
    private var refreshTimer: Timer?
    private var isRefreshingDevices = false
    private let appLogStore: AppLogStore

    private var selectedADBSerial: String? {
        let serial = selectedDevice.serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return serial.isEmpty || serial == "-" ? nil : serial
    }

    init(service: ADBService = ADBService(), scrcpyService: ScrcpyService = ScrcpyService(), appLogStore: AppLogStore = AppLogStore()) {
        self.service = service
        self.scrcpyService = scrcpyService
        self.appLogStore = appLogStore
    }

    func refreshDevices() {
        refreshDevices(showLog: true)
    }

    func startAutoRefresh() {
        guard refreshTimer == nil else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDevices(showLog: false)
            }
        }
        timer.tolerance = 0.2
        refreshTimer = timer
        isAutoRefreshing = true
        refreshDevices(showLog: false)
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        isAutoRefreshing = false
    }

    func prepareFileManager() {
        refreshLocalDirectory()
        refreshRemoteDirectory()
    }

    func setRootModeEnabled(_ isEnabled: Bool) {
        guard isRootModeEnabled != isEnabled else { return }
        isRootModeEnabled = isEnabled
        remoteCurrentPath = isEnabled ? "/" : "/sdcard"
        selectedRemotePath = ""
        refreshRemoteDirectory()
        appendLog(isEnabled ? "[文件管理] 已开启 Root 浏览模式" : "[文件管理] 已关闭 Root 浏览模式")
    }

    func pickLocalDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "打开"

        if panel.runModal() == .OK, let url = panel.url {
            localCurrentPath = url.path
            refreshLocalDirectory()
        }
    }

    func pickApkFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.init(filenameExtension: "apk")!]
        panel.prompt = "选择 APK"

        if panel.runModal() == .OK, let url = panel.url {
            apkPath = url.path
            appendLog("[安装] 已选择 APK：\(url.lastPathComponent)")
        }
    }

    func refreshLocalDirectory() {
        do {
            localEntries = try loadLocalEntries(path: localCurrentPath)
            if !selectedLocalPath.isEmpty && localEntries.first(where: { $0.path == selectedLocalPath }) == nil {
                selectedLocalPath = ""
            }
        } catch {
            appendLog("[文件管理] 本地目录读取失败：\(error.localizedDescription)")
        }
    }

    func refreshRemoteDirectory() {
        do {
            remoteEntries = try service.listRemoteDirectory(path: remoteCurrentPath, asRoot: isRootModeEnabled, serial: selectedADBSerial)
            if !selectedRemotePath.isEmpty && remoteEntries.first(where: { $0.path == selectedRemotePath }) == nil {
                selectedRemotePath = ""
            }
        } catch {
            appendLog("[文件管理] 设备目录读取失败：\(error.localizedDescription)")
        }
    }

    func openLocalParent() {
        let url = URL(fileURLWithPath: localCurrentPath)
        let parent = url.deletingLastPathComponent().path
        guard parent != localCurrentPath else { return }
        localCurrentPath = parent
        selectedLocalPath = ""
        refreshLocalDirectory()
    }

    func openRemoteParent() {
        guard remoteCurrentPath != "/" else { return }
        let parent = (remoteCurrentPath as NSString).deletingLastPathComponent
        remoteCurrentPath = parent.isEmpty ? "/" : parent
        selectedRemotePath = ""
        refreshRemoteDirectory()
    }

    func openLocalDirectory(_ entry: ADBFileEntry) {
        guard entry.isDirectory else { return }
        localCurrentPath = entry.path
        selectedLocalPath = ""
        refreshLocalDirectory()
    }

    func openRemoteDirectory(_ entry: ADBFileEntry) {
        guard entry.isDirectory else { return }
        remoteCurrentPath = entry.path
        selectedRemotePath = ""
        refreshRemoteDirectory()
    }

    func selectLocalEntry(_ entry: ADBFileEntry) {
        selectedLocalPath = entry.path
    }

    func selectRemoteEntry(_ entry: ADBFileEntry) {
        selectedRemotePath = entry.path
    }

    func pushSelected() {
        guard canPushSelected else { return }
        pushLocalPath = selectedLocalPath
        pushRemotePath = joinRemotePath(base: remoteCurrentPath, name: (selectedLocalPath as NSString).lastPathComponent)
        pushFile()
        refreshRemoteDirectory()
    }

    func pullSelected() {
        guard canPullSelected else { return }
        pullRemotePath = selectedRemotePath
        pullLocalPath = joinLocalPath(base: localCurrentPath, name: (selectedRemotePath as NSString).lastPathComponent)
        pullFile()
        refreshLocalDirectory()
    }

    func selectDevice(_ device: DeviceInfo) {
        selectedDevice = device
        appendLog("[设备] 已切换：\(device.serial)（\(device.model)）")
    }

    func executeShell() {
        guard !shellCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let result = try service.runShell(shellCommand, serial: selectedADBSerial)
            appendLog("[Shell] \(shellCommand)\n\(result)")
        } catch {
            appendLog("[Shell] 执行失败：\(error.localizedDescription)")
        }
    }

    func installApk() {
        guard !apkPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let result = try service.install(apkPath: apkPath, serial: selectedADBSerial)
            appendLog("[安装] \(apkPath)\n\(result)")
        } catch {
            appendLog("[安装] 失败：\(error.localizedDescription)")
        }
    }

    func uninstallApp() {
        let pkg = uninstallPackageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pkg.isEmpty else { return }
        do {
            let result = try service.uninstall(packageName: pkg, serial: selectedADBSerial)
            appendLog("[卸载] \(pkg)\n\(result)")
            refreshInstalledPackages()
        } catch {
            appendLog("[卸载] 失败：\(error.localizedDescription)")
        }
    }

    func refreshInstalledPackages() {
        installedApps = []
        appendLog("[应用列表] 正在加载…")

        let service = service
        let serial = selectedADBSerial
        Task { [weak self, service, serial] in
            let result = await Task.detached {
                Result { try service.listThirdPartyPackages(serial: serial) }
            }.value

            switch result {
            case .success(let apps):
                guard let self else { return }
                    self.installedApps = apps
                    self.appendLog("[应用列表] 已加载 \(apps.count) 个应用")
            case .failure(let error):
                guard let self else { return }
                    self.installedApps = []
                    self.appendLog("[应用列表] 读取失败：\(error.localizedDescription)")
            }
        }
    }

    func startScrcpy() {
        let serial = selectedDevice.serial.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !serial.isEmpty, serial != "-" else {
            appendLog("[投屏] 失败：请先连接并选择一台设备")
            return
        }
        guard selectedDevice.isOnline else {
            appendLog("[投屏] 失败：当前设备不在线（\(selectedDevice.state)）")
            return
        }

        do {
            try scrcpyService.start(
                deviceSerial: serial,
                maxSize: scrcpyMaxSize,
                bitRate: scrcpyBitRate,
                turnScreenOff: scrcpyTurnScreenOff,
                maxFPS: scrcpyMaxFPS,
                fullscreen: scrcpyFullscreen,
                alwaysOnTop: scrcpyAlwaysOnTop,
                noAudio: scrcpyNoAudio,
                noControl: scrcpyNoControl,
                showTouches: scrcpyShowTouches,
                windowTitle: scrcpyWindowTitle,
                onTerminate: { [weak self] status, output in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.isScrcpyRunning = false
                        self.scrcpyShortcutPanelController.close()
                        if status != 0 {
                            let message = output.trimmingCharacters(in: .whitespacesAndNewlines)
                            let finalMessage = message.isEmpty ? "无错误输出" : message
                            self.appendLog("[投屏] 已退出（code=\(status)）\n\(finalMessage)")
                        } else {
                            self.appendLog("[投屏] 已退出")
                        }
                    }
                }
            )
            isScrcpyRunning = true
            scrcpyShortcutPanelController.show(windowTitle: scrcpyWindowTitle) { [weak self] action in
                Task { @MainActor in
                    self?.handleScrcpyShortcut(action)
                }
            }
            appendLog("[投屏] 已启动 scrcpy（\(scrcpyMaxSize)p / \(scrcpyBitRate)Mbps）")
        } catch ScrcpyServiceError.executableMissing {
            appendLog("[投屏] 失败：未找到 scrcpy，请执行 brew install scrcpy")
        } catch ScrcpyServiceError.launchFailed(let detail) {
            let message = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalMessage = message.isEmpty ? "未知错误" : message
            appendLog("[投屏] 启动失败：\(finalMessage)")
        } catch {
            appendLog("[投屏] 启动失败：\(error.localizedDescription)")
        }
    }

    func applyScrcpyPreset(_ preset: ScrcpyPreset) {
        switch preset {
        case .smooth:
            scrcpyMaxSize = 1024
            scrcpyBitRate = 6
            scrcpyMaxFPS = 30
        case .balanced:
            scrcpyMaxSize = 1440
            scrcpyBitRate = 10
            scrcpyMaxFPS = 60
        case .highDefinition:
            scrcpyMaxSize = 1920
            scrcpyBitRate = 16
            scrcpyMaxFPS = 60
        }
    }

    func stopScrcpy() {
        scrcpyService.stop()
        scrcpyShortcutPanelController.close()
        isScrcpyRunning = false
        appendLog("[投屏] 已停止")
    }

    func handleScrcpyShortcut(_ action: ScrcpyShortcutAction) {
        switch action {
        case .stop:
            stopScrcpy()
        case .screenshot:
            captureScrcpyScreenshot()
        case .home, .back, .recents, .power, .volumeUp, .volumeDown:
            guard let keyEvent = action.adbKeyEvent else { return }
            sendScrcpyKeyEvent(keyEvent, label: action.title)
        }
    }

    private func sendScrcpyKeyEvent(_ keyEvent: Int, label: String) {
        guard selectedDevice.isOnline else {
            appendLog("[投屏快捷] \(label) 失败：当前设备不在线")
            return
        }

        let service = service
        let serial = selectedADBSerial
        Task { [weak self, service, serial, keyEvent, label] in
            let result = await Task.detached {
                Result { try service.runShell("input keyevent \(keyEvent)", serial: serial) }
            }.value

            guard let self else { return }
            switch result {
            case .success:
                self.appendLog("[投屏快捷] 已发送：\(label)")
            case .failure(let error):
                self.appendLog("[投屏快捷] \(label) 失败：\(error.localizedDescription)")
            }
        }
    }

    private func captureScrcpyScreenshot() {
        guard selectedDevice.isOnline else {
            appendLog("[投屏快捷] 截图失败：当前设备不在线")
            return
        }

        let fileName = "yu-toolbox-scrcpy-\(Int(Date().timeIntervalSince1970)).png"
        let remotePath = "/sdcard/Pictures/\(fileName)"

        let service = service
        let serial = selectedADBSerial
        Task { [weak self, service, serial, remotePath] in
            let result = await Task.detached {
                Result { try service.runShell("screencap -p \(remotePath)", serial: serial) }
            }.value

            guard let self else { return }
            switch result {
            case .success:
                self.appendLog("[投屏快捷] 已截图到设备：\(remotePath)")
            case .failure(let error):
                self.appendLog("[投屏快捷] 截图失败：\(error.localizedDescription)")
            }
        }
    }

    func pullFile() {
        guard !pullRemotePath.isEmpty, !pullLocalPath.isEmpty else { return }
        do {
            let result = try service.pull(remotePath: pullRemotePath, localPath: pullLocalPath, serial: selectedADBSerial)
            appendLog("[拉取] \(pullRemotePath) -> \(pullLocalPath)\n\(result)")
        } catch {
            appendLog("[拉取] 失败：\(error.localizedDescription)")
        }
    }

    func pushFile() {
        guard !pushLocalPath.isEmpty, !pushRemotePath.isEmpty else { return }
        do {
            let result = try service.push(localPath: pushLocalPath, remotePath: pushRemotePath, serial: selectedADBSerial)
            appendLog("[推送] \(pushLocalPath) -> \(pushRemotePath)\n\(result)")
        } catch {
            appendLog("[推送] 失败：\(error.localizedDescription)")
        }
    }

    func reboot(to target: ADBRebootTarget, label: String) {
        do {
            let result = try service.reboot(target, serial: selectedADBSerial)
            appendLog("[重启] \(label)\n\(result)")
        } catch {
            appendLog("[重启] \(label) 失败：\(error.localizedDescription)")
        }
    }

    private func refreshDevices(showLog: Bool) {
        guard !isRefreshingDevices else { return }
        isRefreshingDevices = true

        let service = service
        Task { [weak self, service, showLog] in
            let result = await Task.detached {
                Result { try service.listDevices() }
            }.value

            guard let self else { return }
            self.isRefreshingDevices = false

            switch result {
            case .success(let list):
                self.devices = list.devices
                if let matched = list.devices.first(where: { $0.serial == self.selectedDevice.serial }) {
                    self.selectedDevice = matched
                } else {
                    self.selectedDevice = list.devices.first ?? .disconnected
                }
                if showLog {
                    self.appendLog("[设备] 刷新完成：共 \(list.devices.count) 台")
                }
            case .failure(let error):
                if showLog {
                    self.appendLog("[设备] 刷新失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func loadLocalEntries(path: String) throws -> [ADBFileEntry] {
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let urls = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])

        return urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let isDirectory = values?.isDirectory ?? false
            return ADBFileEntry(path: url.path, name: url.lastPathComponent, isDirectory: isDirectory)
        }
        .sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func joinRemotePath(base: String, name: String) -> String {
        if base == "/" {
            return "/\(name)"
        }
        return base.hasSuffix("/") ? base + name : base + "/" + name
    }

    private func joinLocalPath(base: String, name: String) -> String {
        URL(fileURLWithPath: base).appendingPathComponent(name).path
    }

    private func appendLog(_ entry: String) {
        logs = logs.isEmpty ? entry : logs + "\n\n" + entry
        appLogStore.append(source: "ADB", message: entry)
    }
}
