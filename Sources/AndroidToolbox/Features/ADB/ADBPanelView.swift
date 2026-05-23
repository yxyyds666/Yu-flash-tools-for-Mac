import SwiftUI

enum ADBPanelRoute: Hashable {
    case home
    case fileManager
    case appManagement
    case scrcpy
}

struct ADBPanelView: View {
    @Bindable var viewModel: ADBViewModel
    @State private var route: ADBPanelRoute = .home

    private let rebootColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private let featureColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            switch route {
            case .home:
                homeContent
            case .fileManager:
                fileManagementSection
            case .appManagement:
                appManagementSection
            case .scrcpy:
                scrcpySection
            }
        }
        .padding(20)
        .background(LiquidGlassTheme.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.shadow, radius: 18, y: 8)
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: route) { _, newRoute in
            if newRoute == .fileManager {
                viewModel.prepareFileManager()
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            if route != .home {
                Button {
                    route = .home
                } label: {
                    Label("返回", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(titleForRoute(route))
                    .font(.largeTitle.bold())

                switch route {
                case .home:
                    Text("ADB 主界面")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .fileManager:
                    Text("浏览与传输设备文件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .appManagement:
                    Text("安装与卸载应用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .scrcpy:
                    Text("通过 scrcpy 进行设备投屏")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.isAutoRefreshing {
                Label("搜索设备中", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Button("刷新设备") {
                viewModel.refreshDevices()
            }
        }
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            rebootSection

            featureEntrySection

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var featureEntrySection: some View {
        GroupBox("ADB 功能") {
            LazyVGrid(columns: featureColumns, spacing: 12) {
                featureTile(
                    title: "文件管理",
                    subtitle: "可视化文件浏览",
                    systemImage: "folder.fill",
                    tint: .yellow,
                    action: { route = .fileManager }
                )

                featureTile(
                    title: "应用管理",
                    subtitle: "安装与卸载应用",
                    systemImage: "square.and.arrow.down.fill",
                    tint: .green,
                    action: { route = .appManagement }
                )

                featureTile(
                    title: "投屏",
                    subtitle: "scrcpy 实时投屏",
                    systemImage: "display.2",
                    tint: .blue,
                    action: { route = .scrcpy }
                )
            }
        }
    }

    private var scrcpySection: some View {
        VStack {
            GroupBox("scrcpy 投屏") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Button("流畅") {
                            viewModel.scrcpyMaxSize = 1024
                            viewModel.scrcpyBitRate = 6
                            viewModel.scrcpyMaxFPS = 30
                        }
                        .buttonStyle(.bordered)
                        Button("均衡") {
                            viewModel.scrcpyMaxSize = 1440
                            viewModel.scrcpyBitRate = 10
                            viewModel.scrcpyMaxFPS = 60
                        }
                        .buttonStyle(.bordered)
                        Button("高清") {
                            viewModel.scrcpyMaxSize = 1920
                            viewModel.scrcpyBitRate = 16
                            viewModel.scrcpyMaxFPS = 60
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }

                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Stepper("分辨率：\(viewModel.scrcpyMaxSize)", value: $viewModel.scrcpyMaxSize, in: 640...2560, step: 64)
                            Stepper("码率：\(viewModel.scrcpyBitRate) Mbps", value: $viewModel.scrcpyBitRate, in: 2...32)
                            Stepper("帧率：\(viewModel.scrcpyMaxFPS) FPS", value: $viewModel.scrcpyMaxFPS, in: 15...120, step: 5)

                            TextField("窗口标题", text: $viewModel.scrcpyWindowTitle)
                                .textFieldStyle(.roundedBorder)

                            HStack(spacing: 10) {
                                Button {
                                    viewModel.startScrcpy()
                                } label: {
                                    Label("启动投屏", systemImage: "play.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.isScrcpyRunning)

                                Button {
                                    viewModel.stopScrcpy()
                                } label: {
                                    Label("停止投屏", systemImage: "stop.fill")
                                }
                                .buttonStyle(.bordered)
                                .disabled(!viewModel.isScrcpyRunning)
                            }

                            Text(viewModel.isScrcpyRunning ? "状态：投屏中" : "状态：未启动")
                                .font(.caption)
                                .foregroundStyle(viewModel.isScrcpyRunning ? .green : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("关闭手机屏幕", isOn: $viewModel.scrcpyTurnScreenOff)
                            Toggle("全屏启动", isOn: $viewModel.scrcpyFullscreen)
                            Toggle("窗口置顶", isOn: $viewModel.scrcpyAlwaysOnTop)
                            Toggle("禁用音频", isOn: $viewModel.scrcpyNoAudio)
                            Toggle("只读模式（禁控制）", isOn: $viewModel.scrcpyNoControl)
                            Toggle("显示触摸点", isOn: $viewModel.scrcpyShowTouches)
                        }
                        .toggleStyle(.checkbox)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: 940)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureTile(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .center)
            .padding(10)
            .background(LiquidGlassTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: LiquidGlassTheme.shadow, radius: 8, y: 2)
        }
        .buttonStyle(AnimatedGlassButtonStyle())
    }

    private var appManagementSection: some View {
        HStack(alignment: .top, spacing: 16) {
            installSection
            uninstallSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var installSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .padding(.top, 4)

                Text("安装 APK")
                    .font(.headline)

                HStack(spacing: 10) {
                    TextField("选择 APK 文件", text: $viewModel.apkPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("浏览…") {
                        viewModel.pickApkFile()
                    }
                    .buttonStyle(.bordered)
                }

                if !viewModel.apkPath.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(URL(fileURLWithPath: viewModel.apkPath).lastPathComponent)
                            .font(.caption.weight(.medium))
                    }
                }

                Button(action: { viewModel.installApk() }) {
                    Label("安装", systemImage: "arrow.down.to.line")
                        .frame(maxWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.apkPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var uninstallSection: some View {
        GroupBox {
            VStack(spacing: 14) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
                    .padding(.top, 4)

                Text("卸载应用")
                    .font(.headline)

                HStack(spacing: 10) {
                    TextField("输入包名（如 com.example.app）", text: $viewModel.uninstallPackageName)
                        .textFieldStyle(.roundedBorder)

                    Button(action: { viewModel.uninstallApp() }) {
                        Label("卸载", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(viewModel.uninstallPackageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("已安装应用")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("刷新列表") {
                            viewModel.refreshInstalledPackages()
                        }
                        .controlSize(.small)
                    }

                    if viewModel.installedApps.isEmpty {
                        Text("点击刷新加载已安装应用列表")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.installedApps) { app in
                                    Button {
                                        viewModel.uninstallPackageName = app.packageName
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "app.fill")
                                                .font(.caption)
                                                .foregroundStyle(.blue)

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(app.appName)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                Text(app.packageName)
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(viewModel.uninstallPackageName == app.packageName ? LiquidGlassTheme.cardBackground : AnyShapeStyle(Color.clear))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(AnimatedGlassButtonStyle())
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(10)
                .background(LiquidGlassTheme.panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileManagementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            fileColumn(
                title: "本地文件",
                currentPath: viewModel.localCurrentPath,
                entries: viewModel.localEntries,
                selectedPath: viewModel.selectedLocalPath,
                onOpenParent: viewModel.openLocalParent,
                onOpenDirectory: viewModel.openLocalDirectory,
                onSelectEntry: viewModel.selectLocalEntry
            )

            transferControlSection
                .frame(width: 190)

            fileColumn(
                title: "设备文件",
                currentPath: viewModel.remoteCurrentPath,
                entries: viewModel.remoteEntries,
                selectedPath: viewModel.selectedRemotePath,
                onOpenParent: viewModel.openRemoteParent,
                onOpenDirectory: viewModel.openRemoteDirectory,
                onSelectEntry: viewModel.selectRemoteEntry
            )
        }
        .frame(maxHeight: .infinity)
    }

    private func fileColumn(
        title: String,
        currentPath: String,
        entries: [ADBFileEntry],
        selectedPath: String,
        onOpenParent: @escaping () -> Void,
        onOpenDirectory: @escaping (ADBFileEntry) -> Void,
        onSelectEntry: @escaping (ADBFileEntry) -> Void
    ) -> some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button("上一级") {
                        onOpenParent()
                    }
                    .buttonStyle(.bordered)

                    Text(currentPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if entries.isEmpty {
                    Text("当前目录为空")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(entries) { entry in
                                Button {
                                    if entry.isDirectory {
                                        onOpenDirectory(entry)
                                    } else {
                                        onSelectEntry(entry)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                                            .foregroundStyle(entry.isDirectory ? Color.yellow : Color.blue)
                                        Text(entry.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(selectedPath == entry.path ? LiquidGlassTheme.cardBackground : AnyShapeStyle(Color.clear))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(selectedPath == entry.path ? LiquidGlassTheme.stroke : Color.clear, lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(AnimatedGlassButtonStyle())
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var transferControlSection: some View {
        GroupBox("传输") {
            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { viewModel.isRootModeEnabled },
                    set: { viewModel.setRootModeEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Root 浏览")
                            .font(.subheadline.weight(.semibold))
                        Text("开启后通过 su 浏览 / 与受保护目录")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Text("以 Root 权限浏览")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                Button("选择本地目录") {
                    viewModel.pickLocalDirectory()
                }
                .buttonStyle(.bordered)

                Button("刷新设备目录") {
                    viewModel.refreshRemoteDirectory()
                }
                .buttonStyle(.bordered)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("本地选中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.selectedLocalPath.isEmpty ? "未选择" : viewModel.selectedLocalPath)
                        .font(.caption2)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("设备选中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.selectedRemotePath.isEmpty ? "未选择" : viewModel.selectedRemotePath)
                        .font(.caption2)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                Divider()

                Button("Push 到设备 →") {
                    viewModel.pushSelected()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canPushSelected)

                Button("← Pull 到本地") {
                    viewModel.pullSelected()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canPullSelected)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
    }

    private var deviceListSection: some View {
        GroupBox("设备列表") {
            VStack(spacing: 8) {
                if viewModel.devices.isEmpty {
                    Text("未检测到设备")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                } else {
                    ForEach(viewModel.devices) { device in
                        deviceRow(device)
                    }
                }
            }
        }
    }

    private var rebootSection: some View {
        GroupBox("快速重启") {
            LazyVGrid(columns: rebootColumns, spacing: 10) {
                ForEach(viewModel.rebootActions) { action in
                    rebootTile(for: action)
                }
            }
        }
    }

    private func deviceRow(_ device: DeviceInfo) -> some View {
        Button {
            viewModel.selectDevice(device)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(device.isOnline ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.model)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(device.serial)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(stateText(for: device.state))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected(device) ? LiquidGlassTheme.cardBackground : AnyShapeStyle(Color.clear))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected(device) ? LiquidGlassTheme.stroke : Color.clear, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(AnimatedGlassButtonStyle())
    }

    private func rebootTile(for action: ADBRebootAction) -> some View {
        Button {
            viewModel.reboot(to: action.target, label: action.title)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: iconName(for: action.target))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(action.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
            .padding(10)
            .background(LiquidGlassTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                    .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
            .shadow(color: LiquidGlassTheme.shadow, radius: 8, y: 2)
        }
        .buttonStyle(AnimatedGlassButtonStyle())
    }

    private func titleForRoute(_ route: ADBPanelRoute) -> String {
        switch route {
        case .home:
            return "ADB"
        case .fileManager:
            return "ADB · 文件管理"
        case .appManagement:
            return "ADB · 应用管理"
        case .scrcpy:
            return "ADB · 投屏"
        }
    }

    private func isSelected(_ device: DeviceInfo) -> Bool {
        viewModel.selectedDevice.serial == device.serial
    }

    private func stateText(for state: String) -> String {
        switch state {
        case "device":
            return "在线"
        case "offline":
            return "离线"
        case "unauthorized":
            return "未授权"
        default:
            return state
        }
    }

    private func iconName(for target: ADBRebootTarget) -> String {
        switch target {
        case .system:
            return "power"
        case .fastboot:
            return "hare.fill"
        case .bootloader:
            return "gearshape.2.fill"
        case .edl:
            return "bolt.fill"
        case .recovery:
            return "cross.case.fill"
        case .sideload:
            return "arrow.down.circle.fill"
        }
    }
}
