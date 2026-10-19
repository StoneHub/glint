import Foundation

enum Preferences {
    enum Key {
        static let previewScale = "previewScale"
        static let quitWhenLastWindowCloses = "quitWhenLastWindowCloses"
        static let markdownMode = "markdownMode"
        static let plainTextMode = "plainTextMode"
    }

    enum Zoom {
        static let step = 0.1
        static let range = 0.6...2.0
    }

    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdtext", "mdtxt"]

    static var quitWhenLastWindowCloses: Bool {
        UserDefaults.standard.object(forKey: Key.quitWhenLastWindowCloses) as? Bool ?? true
    }

    static func isMarkdown(_ url: URL?) -> Bool {
        guard let url else { return true } // untitled documents are markdown
        return markdownExtensions.contains(url.pathExtension.lowercased())
    }

    static func defaultMode(for url: URL?) -> ViewMode {
        guard url != nil else { return .edit }
        let markdown = isMarkdown(url)
        let key = markdown ? Key.markdownMode : Key.plainTextMode
        let stored = UserDefaults.standard.string(forKey: key).flatMap(ViewMode.init(rawValue:))
        return stored ?? (markdown ? .preview : .edit)
    }
}
