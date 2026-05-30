import Testing
@testable import AndroidToolbox

@Test
@MainActor
func appLogStore_keepsOnlyMostRecentEntries() {
    let store = AppLogStore(maxEntries: 3)

    store.append(source: "Test", message: "one")
    store.append(source: "Test", message: "two")
    store.append(source: "Test", message: "three")
    store.append(source: "Test", message: "four")

    #expect(store.entries.count == 3)
    #expect(!store.combinedText.contains("one"))
    #expect(store.combinedText.contains("two"))
    #expect(store.combinedText.contains("four"))
}
