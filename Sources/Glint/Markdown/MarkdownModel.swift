import Foundation
import SwiftUI

enum MDAlignment: Sendable {
    case leading, center, trailing
}

struct MDListItem: Identifiable, Sendable {
    let id: Int
    let ordinal: Int
    /// nil = ordinary item; true/false = GitHub task list checkbox state
    let task: Bool?
    let blocks: [MDBlock]
}

struct MDBlock: Identifiable, Sendable {
    /// Foundation's block identity for the run, or a negative synthetic id (see `parse`).
    let id: Int
    let content: Content

    indirect enum Content: Sendable {
        case paragraph(AttributedString)
        case heading(level: Int, text: AttributedString, slug: String)
        case code(language: String?, code: String, highlighted: AttributedString)
        case quote([MDBlock])
        case list(ordered: Bool, items: [MDListItem])
        case table(alignments: [MDAlignment], header: [AttributedString], rows: [[AttributedString]])
        case rule
        case image(url: URL, alt: String)
    }
}

/// Turns Foundation's `.full` Markdown parse (block structure as `presentationIntent`
/// paths, innermost first) into a block tree with SwiftUI fonts baked into the runs.
struct MarkdownParser: Sendable {
    let baseURL: URL?
    let bodySize: CGFloat

    func parse(_ markdown: String) -> [MDBlock] {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let attributed = try? AttributedString(markdown: markdown, options: options) else {
            return [MDBlock(id: 0, content: .paragraph(styled(AttributedString(markdown), size: bodySize)))]
        }

        // Each run carries the path of blocks that contain it, innermost first. Walking the
        // path from the outside in and reusing the last child when its identity matches
        // rebuilds the tree; Foundation numbers identities up from 1, once per block.
        let root = Node(kind: nil, id: 0)
        var htmlBlockCount = 0
        for run in attributed.runs {
            var node = root
            for component in (run.presentationIntent?.components ?? []).reversed() {
                node = node.child(for: component)
            }
            if node === root {
                // Raw HTML blocks are the one thing Foundation leaves without a block intent.
                // Gather consecutive ones into a synthetic paragraph so they show as text;
                // a negative id keeps it clear of Foundation's identities.
                if let last = root.children.last, last.id < 0 {
                    node = last
                } else {
                    htmlBlockCount += 1
                    node = Node(kind: .paragraph, id: -htmlBlockCount)
                    root.children.append(node)
                }
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

        func child(for component: PresentationIntent.IntentType) -> Node {
            if let last = children.last, last.id == component.identity {
                return last
            }
            let child = Node(kind: component.kind, id: component.identity)
            children.append(child)
            return child
        }
    }

    private func block(from node: Node) -> MDBlock? {
        content(of: node).map { MDBlock(id: node.id, content: $0) }
    }

    private func content(of node: Node) -> MDBlock.Content? {
        switch node.kind {
        case .paragraph?:
            if let image = soleImage(in: node.text) {
                return .image(url: image.url, alt: image.alt)
            }
            return .paragraph(styled(node.text, size: bodySize))

        case .header(let level)?:
            let size = bodySize * Typography.headingScale(level)
            return .heading(
                level: level,
                text: styled(node.text, size: size, weight: level <= 2 ? .bold : .semibold),
                slug: Self.slug(String(node.text.characters))
            )

        case .codeBlock(let language)?:
            // Foundation keeps the newline before the closing fence; the view adds its own padding.
            var code = String(node.text.characters)
            if code.hasSuffix("\n") { code.removeLast() }
            let highlighted = SyntaxHighlighter(languageName: language).highlight(code)
            return .code(language: language, code: code, highlighted: highlighted)

        case .blockQuote?:
            return .quote(node.children.compactMap(block(from:)))

        case .orderedList?:
            return .list(ordered: true, items: listItems(of: node))

        case .unorderedList?:
            return .list(ordered: false, items: listItems(of: node))

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
                    header = cells.map { styled($0, size: bodySize * Typography.tableRatio, weight: .semibold) }
                case .tableRow?:
                    rows.append(cells.map { styled($0, size: bodySize * Typography.tableRatio) })
                default:
                    break
                }
            }
            let alignments: [MDAlignment] = columns.map {
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

    private func listItems(of list: Node) -> [MDListItem] {
        list.children.compactMap { item in
            guard case .listItem(let ordinal)? = item.kind else { return nil }
            return MDListItem(
                id: item.id,
                ordinal: ordinal,
                task: stripTaskMarker(in: item),
                blocks: item.children.compactMap(block(from:))
            )
        }
    }

    /// Foundation has no task-list syntax, so `- [ ] foo` arrives as a list item whose first
    /// paragraph begins with the literal `[ ] `. Strip that marker and report its state.
    private func stripTaskMarker(in item: Node) -> Bool? {
        guard let first = item.children.first, case .paragraph? = first.kind else { return nil }
        let plain = String(first.text.characters)
        let state: Bool
        if plain.hasPrefix("[ ] ") {
            state = false
        } else if plain.hasPrefix("[x] ") || plain.hasPrefix("[X] ") {
            state = true
        } else {
            return nil
        }
        let end = first.text.index(first.text.startIndex, offsetByCharacters: 4)
        first.text.removeSubrange(first.text.startIndex..<end)
        return state
    }

    /// A paragraph that is nothing but an image becomes an image block. Relative paths resolve
    /// against the document's folder.
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

    /// The inline-style pass: turns each run's `inlinePresentationIntent` into a concrete SwiftUI
    /// font. The intents alone carry no size, so this is where headings get theirs and inline
    /// code its smaller monospaced face and tint.
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
