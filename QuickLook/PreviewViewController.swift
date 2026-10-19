import AppKit
import QuickLookUI
import SwiftUI

/// Quick Look preview for Markdown files: the app's own MarkdownPreview in an NSHostingView.
/// The extension is sandboxed, so images next to the file won't load; the text renders fully.
final class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        view = NSView()
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = String.decodingTextFile(try Data(contentsOf: url))
        let preview = MarkdownPreview(text: text, baseURL: url.deletingLastPathComponent(), scale: 1)
        let hosting = NSHostingView(rootView: preview)
        hosting.frame = view.bounds
        hosting.autoresizingMask = [.width, .height]
        view.addSubview(hosting)
    }
}
