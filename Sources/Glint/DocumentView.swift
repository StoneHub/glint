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
        EditorView(text: $document.text, fontSize: Typography.editor * scale)
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

/// A hand-rolled split instead of HSplitView. HSplitView is AppKit-backed and, under the glass
/// toolbar, lays its SwiftUI children out without the toolbar's safe-area inset, so the first
/// lines of the editor land underneath the toolbar. A plain HStack lays out normally.
struct SplitPane<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    /// The leading pane's share of the width, as last dragged.
    @State private var fraction: CGFloat = 0.5
    /// `fraction` when the current drag began; the drag's translation is added to this.
    @State private var dragStartFraction: CGFloat?

    private let minimumWidth: CGFloat = 280
    private let handleWidth: CGFloat = 9
    private let coordinateSpace = "split"

    var body: some View {
        GeometryReader { geometry in
            let total = geometry.size.width
            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth(in: total))
                Divider()
                    .overlay { handle(total: total) }
                trailing()
                    .frame(maxWidth: .infinity)
            }
            .coordinateSpace(name: coordinateSpace)
        }
    }

    /// Both panes keep `minimumWidth`; when the window is too narrow for that, the trailing pane gives way.
    private func leadingWidth(in total: CGFloat) -> CGFloat {
        let widest = max(total - minimumWidth, minimumWidth)
        return min(max(total * fraction, minimumWidth), widest)
    }

    /// An invisible strip over the one-point divider, so there is something to grab.
    /// The drag is measured in the HStack's space: the handle itself moves during the drag,
    /// so its own coordinate space would shift under the pointer.
    private func handle(total: CGFloat) -> some View {
        Color.clear
            .frame(width: handleWidth)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named(coordinateSpace))
                    .onChanged { value in
                        let start = dragStartFraction ?? fraction
                        dragStartFraction = start
                        fraction = min(max(start + value.translation.width / total, 0.15), 0.85)
                    }
                    .onEnded { _ in dragStartFraction = nil }
            )
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
                .font(.system(size: Typography.plainText * scale, design: .monospaced))
                .lineSpacing(2 * scale)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 64)
        }
    }
}
