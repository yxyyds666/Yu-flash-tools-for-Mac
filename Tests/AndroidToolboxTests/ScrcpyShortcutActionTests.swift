import Testing
@testable import AndroidToolbox

@Test
func scrcpyShortcutAction_adbKeyEventsMatchAndroidControls() {
    #expect(ScrcpyShortcutAction.home.adbKeyEvent == 3)
    #expect(ScrcpyShortcutAction.back.adbKeyEvent == 4)
    #expect(ScrcpyShortcutAction.recents.adbKeyEvent == 187)
    #expect(ScrcpyShortcutAction.power.adbKeyEvent == 26)
    #expect(ScrcpyShortcutAction.volumeUp.adbKeyEvent == 24)
    #expect(ScrcpyShortcutAction.volumeDown.adbKeyEvent == 25)
}

@Test
func scrcpyShortcutAction_nonKeyActionsDoNotExposeADBKeyEvents() {
    #expect(ScrcpyShortcutAction.stop.adbKeyEvent == nil)
    #expect(ScrcpyShortcutAction.screenshot.adbKeyEvent == nil)
}
