import Testing
@testable import AndroidToolbox

@Test
func toolboxMode_edlIsUnavailableForPublicRelease() {
    #expect(ToolboxMode.edl.isAvailable == false)
}
