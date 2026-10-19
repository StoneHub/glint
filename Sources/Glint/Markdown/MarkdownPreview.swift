import AppKit
import SwiftUI

struct MarkdownPreview: View {
    let text: String
    let baseURL: URL?
    let scale: Double

    @State private var blocks: [MDBlock] = []
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
                        MDBlockView(block: block, scale: scale)
                    }
                }
                .frame(maxWidth: Typography.measure * scale, alignment: .leading)
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

struct MDBlockView: View {
    let block: MDBlock
    let scale: Double

    var body: some View {
        switch block.content {
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

        case .code(let language, let code):
            CodeBlockView(language: language, code: code, scale: scale)

        case .quote(let blocks):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.tint.opacity(0.5))
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 10 * scale) {
                    ForEach(blocks) { MDBlockView(block: $0, scale: scale) }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

        case .list(let ordered, let items):
            ListBlockView(ordered: ordered, items: items, scale: scale)

        case .table(let alignments, let header, let rows):
            TableBlockView(alignments: alignments, header: header, rows: rows)

        case .rule:
            Divider().padding(.vertical, 6 * scale)

        case .image(let url, let alt):
            VStack(alignment: .leading, spacing: 6) {
                if url.isFileURL, !FileManager.default.fileExists(atPath: url.path) {
                    // AsyncImage never resolves for a missing local file; say so instead of spinning.
                    Label("Missing image: \(url.lastPathComponent)", systemImage: "photo.badge.exclamationmark")
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
}

struct CodeBlockView: View {
    let language: String?
    let code: String
    let scale: Double

    @State private var copied = false

    var body: some View {
        ScrollView(.horizontal) {
            Text(verbatim: code)
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
    let items: [MDListItem]
    let scale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5 * scale) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    marker(for: item)
                        .font(.system(size: Typography.body * scale))
                        .frame(minWidth: 22, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 6 * scale) {
                        ForEach(item.blocks) { MDBlockView(block: $0, scale: scale) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func marker(for item: MDListItem) -> some View {
        if let done = item.task {
            Image(systemName: done ? "checkmark.square.fill" : "square")
                .foregroundStyle(done ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
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
    let alignments: [MDAlignment]
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

private extension MDAlignment {
    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var frameAlignment: Alignment {
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
}
