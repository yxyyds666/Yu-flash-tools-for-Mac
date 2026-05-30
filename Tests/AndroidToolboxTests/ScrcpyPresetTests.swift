import Testing
@testable import AndroidToolbox

@Test
@MainActor
func adbViewModel_applyScrcpyPreset_updatesQualitySettings() {
    let viewModel = ADBViewModel()

    viewModel.applyScrcpyPreset(.balanced)

    #expect(viewModel.scrcpyMaxSize == 1440)
    #expect(viewModel.scrcpyBitRate == 10)
    #expect(viewModel.scrcpyMaxFPS == 60)
}
