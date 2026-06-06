import Foundation

enum ADBShell {
    /// Wraps a value in POSIX single quotes so that the on-device `sh -c`
    /// reassembles it as a single literal argument, even when the value
    /// contains spaces, `$`, backticks, `\`, `'`, newlines, or other
    /// metacharacters.
    ///
    /// `adb shell` joins its argv with spaces and re-parses the result with
    /// the device's shell. Without quoting, a path like `/sdcard/My Docs`
    /// becomes two tokens, and a path like `; rm -rf /` becomes a command.
    static func quote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
