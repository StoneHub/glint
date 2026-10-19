import AppKit
import SwiftUI

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { configuration in
            DocumentView(document: configuration.$document, fileURL: configuration.fileURL)
        }
        .defaultSize(width: 980, height: 740)
        .commands {
            ViewModeCommands()
            ZoomCommands()
            DefaultOpenerCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

/// "Run on demand": close the last document and the app goes away.
///
/// DocumentGroup does consult this through the delegate adaptor: with the preference on, the
/// process exits as the last window closes; with it off, the app stays up with no windows.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        Preferences.quitWhenLastWindowCloses
    }
}

// MARK: - Menu commands

struct ViewModeCommands: Commands {
    @FocusedBinding(\.viewMode) private var viewMode: ViewMode?

    var body: some Commands {
        CommandGroup(before: .toolbar) {
            ForEach(ViewMode.allCases) { mode in
                Toggle(mode.title, isOn: Binding(
                    get: { viewMode == mode },
                    set: { if $0 { viewMode = mode } }
                ))
                .keyboardShortcut(mode.shortcut, modifiers: .command)
            }
            Divider()
        }
    }
}

struct ZoomCommands: Commands {
    @AppStorage(Preferences.Key.previewScale) private var scale = 1.0

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Actual Size") { scale = 1.0 }
                .keyboardShortcut("0", modifiers: .command)
            Button("Zoom In") { scale = Zoom.stepped(scale, by: 1) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { scale = Zoom.stepped(scale, by: -1) }
                .keyboardShortcut("-", modifiers: .command)
            Divider()
        }
    }
}

struct DefaultOpenerCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Make Glint the Default for Markdown & Text…") {
                Task { await DefaultOpener.makeDefault() }
            }
        }
    }
}

/// Zoom moves in 10% steps between 60% and 200%. Counting whole steps and dividing back
/// keeps the stored scale at clean values (0.7, not 0.7000000000000001).
enum Zoom {
    static let range = 0.6...2.0
    static let stepsPerUnit = 10.0

    static func stepped(_ scale: Double, by direction: Int) -> Double {
        let steps = (scale * stepsPerUnit).rounded() + Double(direction)
        return min(max(steps / stepsPerUnit, range.lowerBound), range.upperBound)
    }
}

// MARK: - Settings

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
