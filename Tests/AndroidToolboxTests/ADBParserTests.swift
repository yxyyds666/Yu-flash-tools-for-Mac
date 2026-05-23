import Testing
@testable import AndroidToolbox

@Test
func parseDevices_extractsOnlineAndModel() {
    let output = """
    List of devices attached
    emulator-5554\tdevice product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 device:emu64xa transport_id:1
    0123456789ABCDEF\toffline transport_id:2
    """

    let devices = ADBParser.parseDevices(from: output)

    #expect(devices.count == 2)
    #expect(devices[0].serial == "emulator-5554")
    #expect(devices[0].model == "sdk_gphone64_x86_64")
    #expect(devices[0].state == "device")
    #expect(devices[1].model == "Unknown")
    #expect(devices[1].state == "offline")
}
