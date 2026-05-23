import Testing
@testable import AndroidToolbox

@Test
func parseFastbootDevices_extractsSerialAndState() {
    let output = """
    1234567890ABCDEF	fastboot
    ZX1G22	fastboot
    """

    let devices = FastbootParser.parseDevices(from: output)

    #expect(devices.count == 2)
    #expect(devices[0].serial == "1234567890ABCDEF")
    #expect(devices[0].state == "fastboot")
    #expect(devices[1].model == "Fastboot Device")
}
