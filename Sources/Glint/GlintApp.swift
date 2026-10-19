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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // "Run on demand": close the last document and the app goes away.
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
            Button("Zoom In") { scale = min(2.0, (scale + 0.1).rounded(toPlaces: 1)) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { scale = max(0.6, (scale - 0.1).rounded(toPlaces: 1)) }
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

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
