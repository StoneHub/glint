import SwiftUI

struct SettingsView: View {
    @AppStorage(Preferences.Key.quitWhenLastWindowCloses) private var quitOnClose = true
    @AppStorage(Preferences.Key.markdownMode) private var markdownMode: ViewMode = .preview
    @AppStorage(Preferences.Key.plainTextMode) private var plainTextMode: ViewMode = .edit

    var body: some View {
        Form {
            Section("Open files in") {
                Picker("Markdown", selection: $markdownMode) {
                    ForEach(ViewMode.allCases) { Text($0.title).tag($0) }
                }
                Picker("Plain text", selection: $plainTextMode) {
                    ForEach(ViewMode.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("Behavior") {
                Toggle("Quit when the last window closes", isOn: $quitOnClose)
            }
            Section("Finder") {
                Button("Make Glint the default app for .md and .txt") {
                    Task { await DefaultOpener.makeDefault() }
                }
                Text("Or use Finder › Get Info › Open With › Change All… on any .md or .txt file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}
