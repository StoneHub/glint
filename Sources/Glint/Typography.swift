import Foundation

/// Point sizes at 100% zoom. Every text size in the app is one of these times the
/// preview scale, so ⌘+ / ⌘- move the editor and both previews together.
enum Typography {
    static let editor: CGFloat = 13
    static let body: CGFloat = 15
    static let code: CGFloat = 13
    static let plainText: CGFloat = 14

    /// Inline code and table cells sit a touch smaller than the prose around them.
    static let inlineCodeRatio: CGFloat = 0.9
    static let tableRatio: CGFloat = 0.93

    /// Column width of the Markdown preview, so long lines stay readable in a wide window.
    static let measure: CGFloat = 760

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
