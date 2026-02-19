import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Watch all mounted volumes so the context menu appears everywhere
        let finderSync = FIFinderSyncController.default()
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) {
            finderSync.directoryURLs = Set(mountedVolumes)
        }
        // Also watch for volume mount/unmount to stay current
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(
            self,
            selector: #selector(volumesChanged(_:)),
            name: NSWorkspace.didMountNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(volumesChanged(_:)),
            name: NSWorkspace.didUnmountNotification,
            object: nil
        )
    }

    @objc private func volumesChanged(_ notification: Notification) {
        let finderSync = FIFinderSyncController.default()
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) {
            finderSync.directoryURLs = Set(mountedVolumes)
        }
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "Claude Code")

        let openItem = NSMenuItem(
            title: "Open with Claude Code",
            action: #selector(openWithClaude(_:)),
            keyEquivalent: ""
        )
        openItem.tag = 0
        if let icon = loadClaudeIcon() {
            openItem.image = icon
        }

        let resumeItem = NSMenuItem(
            title: "Resume Chat with Claude",
            action: #selector(resumeWithClaude(_:)),
            keyEquivalent: ""
        )
        resumeItem.tag = 1
        if let icon = loadClaudeIcon() {
            resumeItem.image = icon
        }

        menu.addItem(openItem)
        menu.addItem(resumeItem)

        return menu
    }

    private func loadClaudeIcon() -> NSImage? {
        guard let icon = NSImage(named: "ClaudeIcon") else { return nil }
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }

    // MARK: - Actions

    @objc private func openWithClaude(_ sender: AnyObject?) {
        runScript(named: "open-claude")
    }

    @objc private func resumeWithClaude(_ sender: AnyObject?) {
        runScript(named: "resume-claude")
    }

    // MARK: - Script Execution

    private func resolveTargetDirectory() -> String? {
        let target = FIFinderSyncController.default().targetedURL()
        let selectedItems = FIFinderSyncController.default().selectedItemURLs() ?? []

        if let firstItem = selectedItems.first {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: firstItem.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    return firstItem.path
                } else {
                    return firstItem.deletingLastPathComponent().path
                }
            }
        }

        return target?.path
    }

    private func runScript(named scriptName: String) {
        guard let directoryPath = resolveTargetDirectory() else {
            NSLog("FinderSync: Could not resolve target directory")
            return
        }

        guard let scriptURL = try? FileManager.default.url(
            for: .applicationScriptsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("\(scriptName).scpt") else {
            NSLog("FinderSync: Could not locate script \(scriptName).scpt")
            return
        }

        let task: NSUserAppleScriptTask
        do {
            task = try NSUserAppleScriptTask(url: scriptURL)
        } catch {
            NSLog("FinderSync: Failed to load script \(scriptName): \(error)")
            return
        }

        let event = createAppleEvent(withPath: directoryPath)
        task.execute(withAppleEvent: event) { _, error in
            if let error = error {
                NSLog("FinderSync: Script \(scriptName) failed: \(error)")
            }
        }
    }

    private func createAppleEvent(withPath path: String) -> NSAppleEventDescriptor {
        // Build an "on run {arg}" Apple Event
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
        let event = NSAppleEventDescriptor.appleEvent(
            withEventClass: AEEventClass(kCoreEventClass),
            eventID: AEEventID(kAEOpenApplication),
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        let params = NSAppleEventDescriptor.list()
        params.insert(NSAppleEventDescriptor(string: path), at: 1)
        event.setDescriptor(params, forKeyword: keyDirectObject)
        return event
    }
}
