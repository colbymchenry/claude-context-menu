import SwiftUI

struct ContentView: View {
    @State private var scriptsInstalled = ScriptInstaller.scriptsAreInstalled
    @State private var extensionEnabled = ExtensionStatus.isExtensionEnabled

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("Claude Code Menu")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Adds \"Open with Claude Code\" to Finder's right-click menu.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Status rows
            VStack(spacing: 12) {
                StatusRow(
                    title: "Helper Scripts",
                    isReady: scriptsInstalled,
                    readyText: "Installed",
                    notReadyText: "Not installed"
                )

                StatusRow(
                    title: "Finder Extension",
                    isReady: extensionEnabled,
                    readyText: "Enabled",
                    notReadyText: "Not enabled"
                )
            }

            Divider()

            // Action buttons
            VStack(spacing: 10) {
                if !scriptsInstalled {
                    Button("Install Helper Scripts") {
                        ScriptInstaller.installScripts()
                        scriptsInstalled = ScriptInstaller.scriptsAreInstalled
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !extensionEnabled {
                    Button("Enable Finder Extension in System Settings") {
                        ExtensionStatus.openExtensionSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if scriptsInstalled && extensionEnabled {
                    Label("All set! Right-click any file or folder in Finder.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.body)
                }
            }
        }
        .padding(30)
        .frame(width: 420)
        .onReceive(timer) { _ in
            scriptsInstalled = ScriptInstaller.scriptsAreInstalled
            extensionEnabled = ExtensionStatus.isExtensionEnabled
        }
    }
}

struct StatusRow: View {
    let title: String
    let isReady: Bool
    let readyText: String
    let notReadyText: String

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 140, alignment: .leading)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isReady ? .green : .orange)
                Text(isReady ? readyText : notReadyText)
                    .foregroundColor(isReady ? .primary : .orange)
            }
        }
    }
}
