import Foundation

/// UserDefaults keys and the defaults that go with them. Views bind through
/// `@AppStorage`; non-view code reads through the static accessors here.
enum Preferences {
    enum Key {
        static let previewScale = "previewScale"
        static let quitWhenLastWindowCloses = "quitWhenLastWindowCloses"
        static let markdownMode = "markdownMode"
        static let plainTextMode = "plainTextMode"
    }

    /// Mirrors the extensions declared for `net.daringfireball.markdown` in Info.plist.
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdtext", "mdtxt"]

    static var quitWhenLastWindowCloses: Bool {
        UserDefaults.standard.object(forKey: Key.quitWhenLastWindowCloses) as? Bool ?? true
    }

    static func isMarkdown(_ url: URL?) -> Bool {
        guard let url else { return true } // untitled documents are Markdown
        return markdownExtensions.contains(url.pathExtension.lowercased())
    }

    static func defaultMode(for url: URL?) -> ViewMode {
        guard let url else { return .edit } // a new document has nothing to preview
        let markdown = isMarkdown(url)
        let key = markdown ? Key.markdownMode : Key.plainTextMode
        let stored = UserDefaults.standard.string(forKey: key).flatMap(ViewMode.init(rawValue:))
        return stored ?? (markdown ? .preview : .edit)
    }
}
