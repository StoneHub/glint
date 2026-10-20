import Foundation

/// Point sizes at zoom 1.0. Views multiply by the preview scale (⌘+ / ⌘-).
enum Typography {
    static let editor: CGFloat = 13
    static let plainText: CGFloat = 14
    static let body: CGFloat = 15
    static let code: CGFloat = 13

    /// Inline `code` sits a little below the surrounding text so the monospace glyphs don't look oversized.
    static let inlineCodeRatio: CGFloat = 0.9
    /// Table cells are a touch smaller than body text.
    static let tableCellRatio: CGFloat = 0.93

    static func headingScale(_ level: Int) -> CGFloat {
        switch level {
        case 1: 2.0
        case 2: 1.5
        case 3: 1.25
        case 4: 1.1
        case 5: 1.0
        default: 0.9
        }
    }
}
