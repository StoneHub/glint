import AppKit
import UniformTypeIdentifiers

enum DefaultOpener {
    static let types: [UTType] = [.markdownText, .plainText]

    @MainActor
    static func makeDefault() async {
        var failures: [String] = []
        for type in types {
            do {
                try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: type)
            } catch {
                failures.append("\(type.preferredFilenameExtension ?? type.identifier): \(error.localizedDescription)")
            }
        }

        let alert = NSAlert()
        if failures.isEmpty {
            alert.messageText = "M↓ is now the default for .md and .txt"
            alert.informativeText = "Double-clicking Markdown or plain-text files in Finder opens them here."
        } else {
            alert.alertStyle = .warning
            alert.messageText = "Couldn't set M↓ as the default"
            alert.informativeText = failures.joined(separator: "\n")
                + "\n\nFallback: Finder › Get Info on a file › Open With › M↓ › Change All…"
        }
        alert.runModal()
    }
}
