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

    var shortcut: KeyEquivalent {
        switch self {
        case .edit: "1"
        case .split: "2"
        case .preview: "3"
        }
    }
}

extension FocusedValues {
    /// The front document's mode, so the View menu can read and set it.
    @Entry var viewMode: Binding<ViewMode>?
}
