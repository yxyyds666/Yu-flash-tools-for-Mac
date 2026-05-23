# Yu 工具箱

中文 | [English](#english)

面向 macOS 的 Android 设备工具箱，聚焦常用刷机与调试流程，提供统一、开箱即用的桌面体验。

> 当前覆盖能力：**ADB / Fastboot / Qualcomm EDL (9008 入口)**

![Yu 工具箱 App Icon](Sources/AndroidToolbox/Resources/app-icon.png)

---

## 中文

### 项目简介

**Yu 工具箱** 是一个用于 macOS 的 Android 设备管理与调试工具，围绕高频操作进行整合，降低命令行门槛，提升日常效率。

### 核心功能

- **ADB 一站式操作**：设备管理、重启矩阵、文件浏览与传输、应用安装与卸载
- **ADB 投屏**：内置 `scrcpy`，支持分辨率、码率、FPS、全屏、置顶、静音、只读控制等参数
- **Fastboot 基础能力**：设备检测与常用控制命令
- **EDL (9008) 模式入口**：界面入口已预留（当前版本显示开发中）
- **统一日志视图**：集中展示运行过程与执行输出，便于排查问题

### 平台与依赖

- macOS 15+
- Swift 6.2+
- `scrcpy` 已内置（包含 `scrcpy` 与 `scrcpy-server`）

可选：如需系统兜底版本，可手动安装。

```bash
brew install scrcpy
```

### 快速开始

```bash
swift build
swift run AndroidToolbox
```

### 运行测试

```bash
swift test
```

### 许可证

本项目使用 **Apache-2.0** 协议，详见 `LICENSE`。

---

## English

### Overview

**Yu Toolbox** is a macOS toolbox for Android device management and debugging workflows. It consolidates common operations into a single desktop app to reduce command-line overhead and improve daily productivity.

### Key Features

- **ADB all-in-one workflows**: device management, reboot matrix, file browsing/transfer, app install/uninstall
- **ADB screen mirroring**: bundled `scrcpy` with configurable resolution, bitrate, FPS, fullscreen, always-on-top, mute, and read-only control
- **Fastboot essentials**: device detection and common control commands
- **EDL (9008) entry**: reserved in UI (currently marked as in development)
- **Unified runtime logs**: centralized output for easier troubleshooting

### Platform & Dependencies

- macOS 15+
- Swift 6.2+
- Bundled `scrcpy` (`scrcpy` + `scrcpy-server`)

Optional system fallback:

```bash
brew install scrcpy
```

### Quick Start

```bash
swift build
swift run AndroidToolbox
```

### Tests

```bash
swift test
```

### License

Licensed under **Apache-2.0**. See `LICENSE` for details.
