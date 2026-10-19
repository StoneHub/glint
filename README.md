# Glint

A small, run-on-demand Markdown and plain-text viewer/editor for macOS 26+, built with
SwiftUI and Liquid Glass. Open a `.md` or `.txt`, read it rendered, flip to the editor, save,
close — the app quits with its last window.

## Build and install

```bash
Scripts/build.sh install
```

That compiles the Swift package in release mode, assembles `build/Glint.app` (Info.plist,
generated icon, ad-hoc signature), copies it to `~/Applications/Glint.app`, and registers it
with Launch Services. No Xcode project; `swift build` is the whole toolchain.

Other commands: `Scripts/build.sh` (build only), `Scripts/build.sh run file.md`,
`Scripts/build.sh icon` (regenerate the icon from `Scripts/make-icon.swift`).

## Make it the default opener

In Glint: **Glint menu → Make Glint the Default for Markdown & Text…** (also in Settings, ⌘,).
This calls `NSWorkspace.setDefaultApplication` for `net.daringfireball.markdown` and
`public.plain-text`. Fallback: Finder › Get Info on a file › Open With › Glint › Change All…

## Using it

| Action | Shortcut |
|---|---|
| Edit / Split / Preview | ⌘1 / ⌘2 / ⌘3, or the toolbar segment |
| Zoom in / out / reset | ⌘+ / ⌘- / ⌘0 |
| Find in editor | ⌘F (native find bar) |
| New / Open / Save | ⌘N / ⌘O / ⌘S (standard document commands) |

Markdown files open in Preview, plain text in Edit; change the defaults in Settings. The
floating pill shows words / characters / lines. Code blocks have a copy button. Links open in
your browser; `[text](#heading)` anchors scroll within the document.

## How it works

- `TextDocument` is a `FileDocument`; `DocumentGroup` provides open/save/autosave/undo.
- `EditorView` wraps `NSTextView` (find bar, undo, smart quotes and dashes off).
- `MarkdownParser` uses Foundation's `AttributedString(markdown:)` in `.full` mode and walks
  the `presentationIntent` paths into a block tree (headings, paragraphs, code, quotes,
  nested lists, task lists, tables with alignment, rules, images). No third-party dependencies.
- `MarkdownPreview` renders that tree with SwiftUI `Text`, `Grid`, and glass controls.
- Rendering runs off the main actor and is debounced while typing in Split mode.

## Not done yet

- Syntax highlighting inside code blocks.
- `:emoji:` shortcodes (literal emoji render fine).
- A Quick Look extension (needs an Xcode app-extension target).
