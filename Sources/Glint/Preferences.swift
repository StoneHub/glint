import Foundation

enum Preferences {
    enum Key {
        static let previewScale = "previewScale"
        static let quitWhenLastWindowCloses = "quitWhenLastWindowCloses"
        static let markdownMode = "markdownMode"
        static let plainTextMode = "plainTextMode"
    }

    /// Values used until the user changes them in Settings.
    enum Defaults {
        static let markdownMode = ViewMode.preview
        static let plainTextMode = ViewMode.edit
        static let quitWhenLastWindowCloses = true
    }

    enum Zoom {
        static let step = 0.1
        static let range = 0.6...2.0
    }

    /// Mirrors the extensions declared for net.daringfireball.markdown in Info.plist.
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdtext", "mdtxt"]

    static var quitWhenLastWindowCloses: Bool {
        UserDefaults.standard.object(forKey: Key.quitWhenLastWindowCloses) as? Bool ?? Defaults.quitWhenLastWindowCloses
    }

    static func isMarkdown(_ url: URL?) -> Bool {
        guard let url else { return true } // untitled documents are markdown
        return markdownExtensions.contains(url.pathExtension.lowercased())
    }

    /// The mode a document opens in. Untitled documents open in the editor regardless.
    static func defaultMode(for url: URL?) -> ViewMode {
        guard url != nil else { return .edit }
        let stored: String?
        let fallback: ViewMode
        if isMarkdown(url) {
            stored = UserDefaults.standard.string(forKey: Key.markdownMode)
            fallback = Defaults.markdownMode
        } else {
            stored = UserDefaults.standard.string(forKey: Key.plainTextMode)
            fallback = Defaults.plainTextMode
        }
        return stored.flatMap(ViewMode.init(rawValue:)) ?? fallback
    }
}
