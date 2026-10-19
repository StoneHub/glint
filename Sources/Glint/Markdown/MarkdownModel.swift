import Foundation
import SwiftUI

/// One block of a parsed document. Ids come from Foundation's presentation intents
/// (orphan paragraphs get negative ones), so they are unique within a parse.
struct MarkdownBlock: Identifiable, Sendable {
    let id: Int
    let kind: Kind

    enum Kind: Sendable {
        case paragraph(AttributedString)
        case heading(level: Int, text: AttributedString, slug: String)
        /// `code` is the raw text (for the copy button); `highlighted` is the same text with token colors.
        case code(language: String?, code: String, highlighted: AttributedString)
        case quote([MarkdownBlock])
        case list(ordered: Bool, items: [ListItem])
        case table(alignments: [ColumnAlignment], header: [AttributedString], rows: [[AttributedString]])
        case rule
        case image(url: URL, alt: String)
    }

    struct ListItem: Identifiable, Sendable {
        let id: Int
        let ordinal: Int
        /// nil = ordinary item; true/false = GitHub task list checkbox state
        let task: Bool?
        let blocks: [MarkdownBlock]
    }

    enum ColumnAlignment: Sendable {
        case leading, center, trailing
    }
}

/// Turns Foundation's `.full` Markdown parse (block structure as `presentationIntent`
/// paths, innermost first) into a block tree with SwiftUI fonts baked into the runs.
struct MarkdownParser: Sendable {
    let baseURL: URL?
    let bodySize: CGFloat

    func parse(_ markdown: String) -> [MarkdownBlock] {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let attributed = try? AttributedString(markdown: markdown, options: options) else {
            return [MarkdownBlock(id: 0, kind: .paragraph(styled(AttributedString(markdown), size: bodySize)))]
        }

        // Each run carries the path of blocks it sits in, innermost first. Walking the path
        // from the outside in, a component whose identity matches the last child continues
        // that block; anything else starts a sibling. Foundation's identities count up from 1.
        let root = Node(kind: nil, id: -1)
        var orphanParagraph: Node?
        var orphanCount = 0
        for run in attributed.runs {
            var node = root
            for component in (run.presentationIntent?.components ?? []).reversed() {
                if let last = node.children.last, last.id == component.identity {
                    node = last
                } else {
                    let child = Node(kind: component.kind, id: component.identity)
                    node.children.append(child)
                    node = child
                }
            }
            if node === root {
                // Inline-only input has no block intent at all; collect it in a synthetic
                // paragraph. Their ids count down from -2 so they never collide with Foundation's.
                if let open = orphanParagraph {
                    node = open
                } else {
                    orphanCount += 1
                    node = Node(kind: .paragraph, id: -1 - orphanCount)
                    root.children.append(node)
                    orphanParagraph = node
                }
            } else {
                orphanParagraph = nil
            }
            var piece = AttributedString(attributed[run.range])
            piece.presentationIntent = nil
            node.text.append(piece)
        }
        return root.children.compactMap(block(from:))
    }

    // MARK: Tree

    private final class Node {
        let kind: PresentationIntent.Kind?
        let id: Int
        var children: [Node] = []
        var text = AttributedString()

        init(kind: PresentationIntent.Kind?, id: Int) {
            self.kind = kind
            self.id = id
        }
    }

    private func block(from node: Node) -> MarkdownBlock? {
        kind(of: node).map { MarkdownBlock(id: node.id, kind: $0) }
    }

    private func kind(of node: Node) -> MarkdownBlock.Kind? {
        switch node.kind {
        case .paragraph?:
            if let image = soleImage(in: node.text) {
                return .image(url: image.url, alt: image.alt)
            }
            return .paragraph(styled(node.text, size: bodySize))

        case .header(let level)?:
            let size = bodySize * Typography.headingScale(level)
            let plain = String(node.text.characters)
            return .heading(
                level: level,
                text: styled(node.text, size: size, weight: level <= 2 ? .bold : .semibold),
                slug: Self.slug(plain)
            )

        case .codeBlock(let language)?:
            var code = String(node.text.characters)
            if code.hasSuffix("\n") { code.removeLast() }
            let highlighted = SyntaxHighlighter(languageNamed: language)?.highlight(code) ?? AttributedString(code)
            return .code(language: language, code: code, highlighted: highlighted)

        case .blockQuote?:
            return .quote(node.children.compactMap(block(from:)))

        case .orderedList?, .unorderedList?:
            let ordered = node.kind == .orderedList
            let items = node.children.compactMap { item -> MarkdownBlock.ListItem? in
                guard case .listItem(let ordinal)? = item.kind else { return nil }
                let task = stripTaskMarker(in: item)
                return MarkdownBlock.ListItem(id: item.id, ordinal: ordinal, task: task, blocks: item.children.compactMap(block(from:)))
            }
            return .list(ordered: ordered, items: items)

        case .table(let columns)?:
            var header: [AttributedString] = []
            var rows: [[AttributedString]] = []
            for row in node.children {
                var cells = row.children.map { $0.text }
                if cells.count < columns.count {
                    cells += Array(repeating: AttributedString(), count: columns.count - cells.count)
                }
                switch row.kind {
                case .tableHeaderRow?:
                    header = cells.map { styled($0, size: bodySize * Typography.tableCellRatio, weight: .semibold) }
                case .tableRow?:
                    rows.append(cells.map { styled($0, size: bodySize * Typography.tableCellRatio) })
                default:
                    break
                }
            }
            let alignments: [MarkdownBlock.ColumnAlignment] = columns.map {
                switch $0.alignment {
                case .center: .center
                case .right: .trailing
                default: .leading
                }
            }
            return .table(alignments: alignments, header: header, rows: rows)

        case .thematicBreak?:
            return .rule

        default:
            return nil
        }
    }

    // MARK: Helpers

    private static let taskMarkers: [(prefix: String, done: Bool)] = [("[ ] ", false), ("[x] ", true), ("[X] ", true)]

    /// Foundation doesn't know GitHub task lists: `- [x] foo` arrives as a list item whose first
    /// paragraph starts with the literal "[x] ". Strip the marker and report its state.
    private func stripTaskMarker(in item: Node) -> Bool? {
        guard let first = item.children.first, case .paragraph? = first.kind else { return nil }
        let plain = String(first.text.characters)
        guard let marker = Self.taskMarkers.first(where: { plain.hasPrefix($0.prefix) }) else { return nil }
        let end = first.text.index(first.text.startIndex, offsetByCharacters: marker.prefix.count)
        first.text.removeSubrange(first.text.startIndex..<end)
        return marker.done
    }

    /// A paragraph that is nothing but one image becomes an image block. Relative paths
    /// resolve against the document's folder.
    private func soleImage(in text: AttributedString) -> (url: URL, alt: String)? {
        let runs = Array(text.runs)
        guard runs.count == 1, let imageURL = runs[0].imageURL else { return nil }
        let resolved: URL
        if imageURL.scheme == nil, let baseURL {
            resolved = baseURL.appending(path: imageURL.path)
        } else {
            resolved = imageURL
        }
        return (resolved, String(text.characters))
    }

    private func styled(_ source: AttributedString, size: CGFloat, weight: Font.Weight = .regular) -> AttributedString {
        var result = source
        for run in source.runs {
            let intent = run.inlinePresentationIntent ?? []
            var font: Font
            if intent.contains(.code) {
                font = .system(size: size * Typography.inlineCodeRatio, weight: weight, design: .monospaced)
                result[run.range].swiftUI.backgroundColor = Color.primary.opacity(0.07)
            } else {
                font = .system(size: size, weight: weight)
            }
            if intent.contains(.stronglyEmphasized) { font = font.bold() }
            if intent.contains(.emphasized) { font = font.italic() }
            if intent.contains(.strikethrough) {
                result[run.range].swiftUI.strikethroughStyle = .single
            }
            result[run.range].swiftUI.font = font
            result[run.range].inlinePresentationIntent = nil
        }
        return result
    }

    /// GitHub-style anchor: lowercase, drop punctuation, spaces → hyphens.
    static func slug(_ text: String) -> String {
        var out = ""
        for ch in text.lowercased() {
            if ch.isLetter || ch.isNumber || ch == "-" || ch == "_" {
                out.append(ch)
            } else if ch == " " {
                out.append("-")
            }
        }
        return out
    }
}
