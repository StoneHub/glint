import Quartz
import SwiftUI

/// Hosts the app's Markdown preview in Quick Look: the space bar in Finder, `qlmanage -p`.
///
/// The extension compiles the Markdown folder and TextDocument's decoder from the app target,
/// so what Quick Look shows is what the app shows.
final class PreviewViewController: NSViewController, QLPreviewingController {
    override func loadView() {
        view = NSView()
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = TextDocument.decode(try Data(contentsOf: url))
        let preview = MarkdownPreview(text: text, baseURL: url.deletingLastPathComponent(), scale: 1)
        let hosting = NSHostingView(rootView: preview)
        hosting.frame = view.bounds
        hosting.autoresizingMask = [.width, .height]
        view.addSubview(hosting)
    }
}
