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
