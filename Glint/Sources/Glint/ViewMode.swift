import SwiftUI

enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case edit, split, preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .edit: "Edit"
        case .split: "Split"
        case .preview: "Preview"
        }
    }

    var symbol: String {
        switch self {
        case .edit: "pencil"
        case .split: "rectangle.split.2x1"
        case .preview: "doc.richtext"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .edit: "1"
        case .split: "2"
        case .preview: "3"
        }
    }
}

struct ViewModeFocusedKey: FocusedValueKey {
    typealias Value = Binding<ViewMode>
}

extension FocusedValues {
    var viewMode: Binding<ViewMode>? {
        get { self[ViewModeFocusedKey.self] }
        set { self[ViewModeFocusedKey.self] = newValue }
    }
}

enum Preferences {
    enum Key {
        static let previewScale = "previewScale"
        static let quitWhenLastWindowCloses = "quitWhenLastWindowCloses"
        static let markdownMode = "markdownMode"
        static let plainTextMode = "plainTextMode"
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
