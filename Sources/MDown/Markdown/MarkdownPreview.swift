import AppKit
import SwiftUI

struct MarkdownPreview: View {
    let text: String
    let baseURL: URL?
    let scale: Double
    /// Called with a `TaskMarker.index` when a task checkbox is clicked. nil (Quick Look)
    /// leaves the checkboxes as plain images.
    var onToggleTask: (@MainActor (Int) -> Void)? = nil

    @State private var blocks: [MarkdownBlock] = []
    @State private var hasRendered = false

    private struct ParseKey: Equatable {
        let text: String
        let scale: Double
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14 * scale) {
                    ForEach(blocks) { block in
                        MarkdownBlockView(block: block, scale: scale, onToggleTask: onToggleTask)
                    }
                }
                .frame(maxWidth: 760 * scale, alignment: .leading)
                .padding(.horizontal, 36)
                .padding(.top, 28)
                .padding(.bottom, 72)
                .frame(maxWidth: .infinity)
            }
            .environment(\.openURL, OpenURLAction { url in
                // In-document anchors like [Verify](#verify) scroll to the heading.
                if url.scheme == nil, let fragment = url.fragment, !fragment.isEmpty {
                    withAnimation { proxy.scrollTo(fragment, anchor: .top) }
                    return .handled
                }
                return .systemAction
            })
        }
        .task(id: ParseKey(text: text, scale: scale)) {
            if hasRendered {
                try? await Task.sleep(for: .milliseconds(150))
                if Task.isCancelled { return }
            }
            let parser = MarkdownParser(baseURL: baseURL, bodySize: Typography.body * scale)
            let source = text
            let result = await Task.detached(priority: .userInitiated) { parser.parse(source) }.value
            if Task.isCancelled { return }
            blocks = result
            hasRendered = true
        }
    }
}

// MARK: - Blocks

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let scale: Double
    let onToggleTask: (@MainActor (Int) -> Void)?

    var body: some View {
        switch block.kind {
        case .paragraph(let text):
            Text(text)
                .lineSpacing(3 * scale)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

        case .heading(let level, let text, let slug):
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                if level <= 2 {
                    Divider()
                }
            }
            .padding(.top, level <= 2 ? 12 * scale : 4 * scale)
            .id(slug)

        case .code(let language, let code, let highlighted):
            CodeBlockView(language: language, code: code, highlighted: highlighted, scale: scale)

        case .quote(let blocks):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.tint.opacity(0.5))
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 10 * scale) {
                    ForEach(blocks) { MarkdownBlockView(block: $0, scale: scale, onToggleTask: onToggleTask) }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

        case .list(let ordered, let items):
            ListBlockView(ordered: ordered, items: items, scale: scale, onToggleTask: onToggleTask)

        case .table(let alignments, let header, let rows):
            TableBlockView(alignments: alignments, header: header, rows: rows)

        case .rule:
            Divider().padding(.vertical, 6 * scale)

        case .image(let url, let alt):
            ImageBlockView(url: url, alt: alt, scale: scale)
        }
    }
}

struct ImageBlockView: View {
    let url: URL
    let alt: String
    let scale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // AsyncImage stays in its loading phase forever for a local file it can't open,
            // so check up front and say so instead of showing a spinner. "Can't read" is the
            // Quick Look case: the sandbox allows the previewed file only, not its neighbours.
            if url.isFileURL, !FileManager.default.fileExists(atPath: url.path) {
                Label("Missing image: \(url.lastPathComponent)", systemImage: "photo.badge.exclamationmark")
                    .foregroundStyle(.secondary)
            } else if url.isFileURL, !FileManager.default.isReadableFile(atPath: url.path) {
                Label("Can't read \(url.lastPathComponent) here", systemImage: "photo")
                    .foregroundStyle(.secondary)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Label("Couldn't load \(url.lastPathComponent)", systemImage: "photo")
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
                .frame(maxHeight: 640 * scale)
            }
            if !alt.isEmpty {
                Text(alt).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct CodeBlockView: View {
    let language: String?
    let code: String
    let highlighted: AttributedString
    let scale: Double

    @State private var copied = false

    var body: some View {
        ScrollView(.horizontal) {
            Text(highlighted)
                .font(.system(size: Typography.code * scale, design: .monospaced))
                .lineSpacing(2 * scale)
                .textSelection(.enabled)
                .padding(14)
        }
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                if let language, !language.isEmpty {
                    Text(language)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Button {
                    copy()
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .help("Copy code")
            }
            .padding(8)
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}

struct ListBlockView: View {
    let ordered: Bool
    let items: [MarkdownBlock.ListItem]
    let scale: Double
    let onToggleTask: (@MainActor (Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 5 * scale) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    marker(for: item)
                        .font(.system(size: Typography.body * scale))
                        .frame(minWidth: 22, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 6 * scale) {
                        ForEach(item.blocks) { MarkdownBlockView(block: $0, scale: scale, onToggleTask: onToggleTask) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func marker(for item: MarkdownBlock.ListItem) -> some View {
        if let task = item.task {
            let box = Image(systemName: task.done ? "checkmark.square.fill" : "square")
                .foregroundStyle(task.done ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            if let onToggleTask {
                Button { onToggleTask(task.index) } label: { box }
                    .buttonStyle(.plain)
            } else {
                box
            }
        } else if ordered {
            Text("\(item.ordinal).")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        } else {
            Text("•")
                .foregroundStyle(.secondary)
        }
    }
}

struct TableBlockView: View {
    let alignments: [MarkdownBlock.ColumnAlignment]
    let header: [AttributedString]
    let rows: [[AttributedString]]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(header.indices, id: \.self) { column in
                    cell(header[column], column: column)
                }
            }
            .background(.quaternary.opacity(0.5))

            ForEach(rows.indices, id: \.self) { rowIndex in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    ForEach(rows[rowIndex].indices, id: \.self) { column in
                        cell(rows[rowIndex][column], column: column)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private func cell(_ text: AttributedString, column: Int) -> some View {
        let alignment = column < alignments.count ? alignments[column] : .leading
        return Text(text)
            .textSelection(.enabled)
            .multilineTextAlignment(alignment.textAlignment)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
            .gridColumnAlignment(alignment.horizontalAlignment)
    }
}

private extension MarkdownBlock.ColumnAlignment {
    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var frameAlignment: Alignment {
        Alignment(horizontal: horizontalAlignment, vertical: .center)
    }
}
