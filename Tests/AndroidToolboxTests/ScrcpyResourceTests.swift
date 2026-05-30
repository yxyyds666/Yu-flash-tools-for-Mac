import Foundation
import Testing
@testable import AndroidToolbox

@Test
func scrcpyIconResource_isBundled() {
    let url = Bundle.module.url(forResource: "scrcpy", withExtension: "svg", subdirectory: "Resources")

    #expect(url != nil)
}
