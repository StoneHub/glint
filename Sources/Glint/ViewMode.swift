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
