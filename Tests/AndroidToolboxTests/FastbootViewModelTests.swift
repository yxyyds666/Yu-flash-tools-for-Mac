import Testing
@testable import AndroidToolbox

@Test
@MainActor
func fastbootViewModel_genericFlashCommandPreview_usesPlaceholdersWhenEmpty() {
    let viewModel = FastbootViewModel(appLogStore: AppLogStore())
    viewModel.customImagePath = ""
    viewModel.customPartitionText = ""

    #expect(viewModel.genericFlashImageFileName == "未选择镜像")
    #expect(viewModel.genericFlashCommandPreview == "fastboot -s <serial> flash <partition> <image>")
}

@Test
@MainActor
func fastbootViewModel_genericFlashCommandPreview_usesSerialPartitionAndFullImagePath() {
    let viewModel = FastbootViewModel(appLogStore: AppLogStore())
    viewModel.selectedDevice = DeviceInfo(serial: "ABC123", model: "Pixel", state: "fastboot")
    viewModel.customImagePath = "/Users/test/boot.img"
    viewModel.customPartitionText = "boot"

    #expect(viewModel.genericFlashImageFileName == "boot.img")
    #expect(viewModel.genericFlashCommandPreview == "fastboot -s ABC123 flash boot /Users/test/boot.img")
}
