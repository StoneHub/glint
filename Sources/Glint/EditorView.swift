import AppKit
import SwiftUI

/// Thin NSTextView wrapper: proper undo, ⌘F find bar, and no smart-quote/dash mangling of Markdown.
struct EditorView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.textContainerInset = NSSize(width: 20, height: 18)
        textView.drawsBackground = false
        textView.textColor = .textColor
        textView.font = Self.font(size: fontSize)
        textView.string = text

        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selection = textView.selectedRanges
            textView.string = text
            let length = (text as NSString).length
            textView.selectedRanges = selection.compactMap { value in
                let range = value.rangeValue
                guard range.location <= length else { return nil }
                return NSValue(range: NSRange(location: range.location, length: min(range.length, length - range.location)))
            }
        }

        let font = Self.font(size: fontSize)
        if textView.font != font {
            textView.font = font
        }
    }

    private static func font(size: CGFloat) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
