import SwiftUI

struct DocumentView: View {
    @Binding var document: TextDocument
    let fileURL: URL?

    @State private var mode: ViewMode
    @AppStorage(Preferences.Key.previewScale) private var scale = 1.0

    init(document: Binding<TextDocument>, fileURL: URL?) {
        _document = document
        self.fileURL = fileURL
        _mode = State(initialValue: Preferences.defaultMode(for: fileURL))
    }

    private var isMarkdown: Bool { Preferences.isMarkdown(fileURL) }

    var body: some View {
        content
            .overlay(alignment: .bottomTrailing) {
                StatsPill(text: document.text)
                    .padding(14)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $mode) {
                        ForEach(ViewMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .help("Edit ⌘1 · Split ⌘2 · Preview ⌘3")
                }
            }
            .focusedSceneValue(\.viewMode, $mode)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .edit:
            editor
        case .preview:
            preview
        case .split:
            SplitPane(leading: { editor }, trailing: { preview })
        }
    }

    private var editor: some View {
        EditorView(text: $document.text, fontSize: 13 * scale)
    }

    @ViewBuilder
    private var preview: some View {
        if isMarkdown {
            MarkdownPreview(
                text: document.text,
                baseURL: fileURL?.deletingLastPathComponent(),
                scale: scale
            )
        } else {
            PlainTextPreview(text: document.text, scale: scale)
        }
    }
}

// MARK: - Resizable two-pane split
//
// HSplitView is AppKit-backed and mishandles the glass toolbar's safe area for SwiftUI
// children (content lands under the toolbar). A plain SwiftUI split lays out normally.

struct SplitPane<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    @State private var fraction: CGFloat = 0.5
    @State private var dragStartFraction: CGFloat?

    private let minimumWidth: CGFloat = 280

    var body: some View {
        GeometryReader { geometry in
            let total = geometry.size.width
            let leadingWidth = min(max(total * fraction, minimumWidth), max(total - minimumWidth, minimumWidth))
            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth)
                Divider()
                    .overlay {
                        Color.clear
                            .frame(width: 9)
                            .contentShape(Rectangle())
                            .onHover { inside in
                                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 1, coordinateSpace: .named("split"))
                                    .onChanged { value in
                                        if dragStartFraction == nil { dragStartFraction = fraction }
                                        let start = dragStartFraction ?? fraction
                                        fraction = min(max(start + value.translation.width / total, 0.15), 0.85)
                                    }
                                    .onEnded { _ in dragStartFraction = nil }
                            )
                    }
                trailing()
                    .frame(maxWidth: .infinity)
            }
            .coordinateSpace(name: "split")
        }
    }
}

// MARK: - Floating glass stats

struct StatsPill: View {
    let text: String

    var body: some View {
        let stats = TextStats(text)
        HStack(spacing: 10) {
            stat(stats.words, "words")
            dot
            stat(stats.characters, "chars")
            dot
            stat(stats.lines, "lines")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect()
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(value.formatted()).foregroundStyle(.primary)
            Text(label)
        }
    }

    private var dot: some View {
        Circle().fill(.tertiary).frame(width: 3, height: 3)
    }
}

struct TextStats {
    let words: Int
    let characters: Int
    let lines: Int

    init(_ text: String) {
        words = text.split(whereSeparator: \.isWhitespace).count
        characters = text.count
        lines = text.isEmpty ? 0 : text.reduce(into: 1) { if $1 == "\n" { $0 += 1 } }
    }
}

// MARK: - Plain text reading mode

struct PlainTextPreview: View {
    let text: String
    let scale: Double

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(.system(size: 14 * scale, design: .monospaced))
                .lineSpacing(2 * scale)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 64)
        }
    }
}
