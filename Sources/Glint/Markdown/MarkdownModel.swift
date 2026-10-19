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

indirect enum MDBlock: Identifiable, Sendable {
    case paragraph(id: Int, text: AttributedString)
    case heading(id: Int, level: Int, text: AttributedString, slug: String)
    case code(id: Int, language: String?, code: String)
    case quote(id: Int, blocks: [MDBlock])
    case list(id: Int, ordered: Bool, items: [MDListItem])
    case table(id: Int, alignments: [MDAlignment], header: [AttributedString], rows: [[AttributedString]])
    case rule(id: Int)
    case image(id: Int, url: URL, alt: String)

    var id: Int {
        switch self {
        case .paragraph(let id, _), .heading(let id, _, _, _), .code(let id, _, _),
             .quote(let id, _), .list(let id, _, _), .table(let id, _, _, _),
             .rule(let id), .image(let id, _, _):
            id
        }
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
            return [.paragraph(id: 0, text: styled(AttributedString(markdown), size: bodySize))]
        }

        let root = Node(kind: nil, id: -1)
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
                // Inline-only content with no block intent: treat as a paragraph.
                if let last = root.children.last, last.id < -1 {
                    node = last
                } else {
                    orphanCount += 1
                    let child = Node(kind: .paragraph, id: -1 - orphanCount)
                    root.children.append(child)
                    node = child
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
    }

    private func block(from node: Node) -> MDBlock? {
        switch node.kind {
        case .paragraph?:
            if let image = soleImage(in: node.text) {
                return .image(id: node.id, url: image.url, alt: image.alt)
            }
            return .paragraph(id: node.id, text: styled(node.text, size: bodySize))

        case .header(let level)?:
            let size = bodySize * Self.headingScale(level)
            let plain = String(node.text.characters)
            return .heading(
                id: node.id,
                level: level,
                text: styled(node.text, size: size, weight: level <= 2 ? .bold : .semibold),
                slug: Self.slug(plain)
            )

        case .codeBlock(let language)?:
            var code = String(node.text.characters)
            if code.hasSuffix("\n") { code.removeLast() }
            return .code(id: node.id, language: language, code: code)

        case .blockQuote?:
            return .quote(id: node.id, blocks: node.children.compactMap(block(from:)))

        case .orderedList?, .unorderedList?:
            var ordered = false
            if case .orderedList? = node.kind { ordered = true }
            let items = node.children.compactMap { item -> MDListItem? in
                guard case .listItem(let ordinal)? = item.kind else { return nil }
                let task = stripTaskMarker(in: item)
                return MDListItem(id: item.id, ordinal: ordinal, task: task, blocks: item.children.compactMap(block(from:)))
            }
            return .list(id: node.id, ordered: ordered, items: items)

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
                    header = cells.map { styled($0, size: bodySize * 0.93, weight: .semibold) }
                case .tableRow?:
                    rows.append(cells.map { styled($0, size: bodySize * 0.93) })
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
            return .table(id: node.id, alignments: alignments, header: header, rows: rows)

        case .thematicBreak?:
            return .rule(id: node.id)

        default:
            return nil
        }
    }

    // MARK: Helpers

    /// `- [ ] foo` / `- [x] foo` are not parsed by Foundation; detect and strip the marker.
    private func stripTaskMarker(in item: Node) -> Bool? {
        guard let first = item.children.first, case .paragraph? = first.kind else { return nil }
        let plain = String(first.text.characters)
        let state: Bool?
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
                font = .system(size: size * 0.9, weight: weight, design: .monospaced)
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

    private static func headingScale(_ level: Int) -> CGFloat {
        switch level {
        case 1: 2.0
        case 2: 1.5
        case 3: 1.25
        case 4: 1.1
        case 5: 1.0
        default: 0.9
        }
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
