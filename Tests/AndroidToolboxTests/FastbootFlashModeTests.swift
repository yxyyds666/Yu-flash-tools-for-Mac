import Testing
@testable import AndroidToolbox

@Test
func fastbootFlashMode_containsRequiredEntries() {
    let modes = FastbootFlashMode.allCases

    #expect(modes.map(\.title) == ["通用刷机", "小米机型刷写", "欧加真机型刷写"])
    #expect(modes.map(\.id) == ["generic", "xiaomi", "oplusRealme"])
}
