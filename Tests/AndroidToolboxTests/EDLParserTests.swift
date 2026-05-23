import Testing
@testable import AndroidToolbox

@Test
func parseIOReg_detectsQualcomm9008() {
    let sample = """
    +-o QUSB_BULK_CID:123 <class AppleUSBDevice, id 0x100000abc, registered, matched, active, busy 0 (1 ms), retain 18>
      {
        \"idVendor\" = 0x05c6
        \"idProduct\" = 0x9008
        \"USB Serial Number\" = \"SER12345\"
      }
    """

    let devices = EDLParser.parseIOReg(sample)

    #expect(devices.count == 1)
    #expect(devices[0].serial == "SER12345")
    #expect(devices[0].state == "edl")
}
