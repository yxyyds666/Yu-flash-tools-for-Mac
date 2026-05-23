import Testing
@testable import AndroidToolbox

@Test
func deviceInfo_onlineStateReflectsADBState() {
    let online = DeviceInfo(serial: "abc", model: "Pixel", state: "device")
    let offline = DeviceInfo(serial: "xyz", model: "Pixel", state: "offline")

    #expect(online.isOnline)
    #expect(!offline.isOnline)
}
