import AppKit
import SwiftUI

@main
struct MDownApp: App {
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// "Run on demand": close the last document and the app goes away. DocumentGroup does
    /// consult this through NSApplicationDelegateAdaptor; the Settings toggle turns it off.
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
            Button("Zoom In") { zoom(by: Preferences.Zoom.step) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { zoom(by: -Preferences.Zoom.step) }
                .keyboardShortcut("-", modifiers: .command)
            Divider()
        }
    }

    /// Steps in tenths and rounds to one decimal, so repeated zooming never drifts to 1.0999….
    private func zoom(by delta: Double) {
        let stepped = ((scale + delta) * 10).rounded() / 10
        scale = min(max(stepped, Preferences.Zoom.range.lowerBound), Preferences.Zoom.range.upperBound)
    }
}

struct DefaultOpenerCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Make M↓ the Default for Markdown & Text…") {
                Task { await DefaultOpener.makeDefault() }
            }
        }
    }
}
