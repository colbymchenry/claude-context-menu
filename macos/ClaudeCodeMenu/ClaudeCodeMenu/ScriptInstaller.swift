import Foundation

struct ScriptInstaller {

    static let extensionBundleID = "com.anthropic.ClaudeCodeMenu.FinderExtension"

    static var scriptsDirectoryURL: URL {
        let appScriptsDir = FileManager.default.urls(
            for: .applicationScriptsDirectory,
            in: .userDomainMask
        ).first!
        // applicationScriptsDirectory returns the host app's scripts dir.
        // We need the extension's scripts dir instead.
        return appScriptsDir
            .deletingLastPathComponent()
            .appendingPathComponent(extensionBundleID)
    }

    static var scriptNames: [String] {
        ["open-claude", "resume-claude"]
    }

    static var scriptsAreInstalled: Bool {
        let fm = FileManager.default
        for name in scriptNames {
            let dest = scriptsDirectoryURL.appendingPathComponent("\(name).scpt")
            if !fm.fileExists(atPath: dest.path) {
                return false
            }
        }
        return true
    }

    /// Installs compiled .scpt files from the app bundle's Resources into
    /// ~/Library/Application Scripts/<extension-bundle-id>/
    @discardableResult
    static func installScripts() -> Bool {
        let fm = FileManager.default
        let destDir = scriptsDirectoryURL

        // Create the scripts directory if it doesn't exist
        do {
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        } catch {
            NSLog("ScriptInstaller: Failed to create scripts directory: \(error)")
            return false
        }

        var allSucceeded = true
        for name in scriptNames {
            guard let sourceURL = Bundle.main.url(forResource: name, withExtension: "scpt") else {
                NSLog("ScriptInstaller: Could not find \(name).scpt in app bundle")
                allSucceeded = false
                continue
            }
            let destURL = destDir.appendingPathComponent("\(name).scpt")

            do {
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                try fm.copyItem(at: sourceURL, to: destURL)
                NSLog("ScriptInstaller: Installed \(name).scpt")
            } catch {
                NSLog("ScriptInstaller: Failed to install \(name).scpt: \(error)")
                allSucceeded = false
            }
        }

        return allSucceeded
    }
}
