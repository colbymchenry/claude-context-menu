import AppKit

struct ExtensionStatus {

    /// Checks if the Finder Sync Extension is currently enabled by querying pluginkit.
    /// pluginkit -m output uses prefixes: "+" = enabled, "-" = disabled, no prefix = registered but not enabled.
    static var isExtensionEnabled: Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-p", "com.apple.FinderSync"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return false
        }

        // Look for our bundle ID with a "+" prefix, which means explicitly enabled.
        // Format: "+    com.anthropic.ClaudeCodeMenu.FinderExtension(1.0.0)"
        for line in output.components(separatedBy: "\n") {
            if line.contains(ScriptInstaller.extensionBundleID) {
                return line.trimmingCharacters(in: .whitespaces).hasPrefix("+")
            }
        }

        return false
    }

    /// Opens System Settings to the Extensions pane where the user can enable the Finder extension.
    static func openExtensionSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!
        NSWorkspace.shared.open(url)
    }
}
