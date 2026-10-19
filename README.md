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

### With the Quick Look extension

```bash
Scripts/build.sh xcode install
```

App extensions need Xcode, so this path generates `Glint.xcodeproj` from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), builds the app
and `GlintQuickLook.appex` with `xcodebuild`, ad-hoc signed, and installs
`build/Xcode/Glint.app`. The generated project is not checked in. The plain `install` still
works without Xcode; it just ships no Quick Look.

## Make it the default opener

In Glint: **Glint menu → Make Glint the Default for Markdown & Text…** (also in Settings, ⌘,).
This calls `NSWorkspace.setDefaultApplication` for `net.daringfireball.markdown` and
`public.plain-text`. Fallback: Finder › Get Info on a file › Open With › Glint › Change All…

## Using it

| Action | Shortcut |
|---|---|
| Edit / Split / Preview | ⌘1 / ⌘2 / ⌘3, or the toolbar segment |
| Zoom in / out / reset | ⌘+ / ⌘- / ⌘0 (10% steps, 60–200%) |
| Find in editor | ⌘F (native find bar) |
| New / Open / Save | ⌘N / ⌘O / ⌘S (standard document commands) |
| Settings | ⌘, |

Markdown files open in Preview, plain text in Edit; change the defaults in Settings, along
with whether the app quits when its last window closes. The floating pill shows words /
characters / lines.

The preview renders headings, paragraphs, nested and task lists, block quotes, tables with
column alignment, rules, images and links. Links open in your browser; `[text](#heading)`
anchors scroll within the document. Fenced code blocks have a copy button and syntax
highlighting for comments, strings, numbers and keywords in Swift, Python, Ruby,
JavaScript/TypeScript, JSON, shell, YAML, HTML, CSS, SQL and the C family (C, C++, Java,
Kotlin, Go, Rust, C#); other languages get comments, strings and numbers. GitHub
`:emoji:` shortcodes render in prose, headings, lists and tables, never inside code; unknown
names stay literal.

## Quick Look

With the Xcode build installed, pressing the space bar on a `.md` file in Finder (or
`qlmanage -p file.md`) shows the same rendered preview. The extension compiles the app's
Markdown code, so the two cannot drift. Limits: the extension's sandbox sees only the file
being previewed, so images next to it show as missing, and the copy button does nothing
there.

## How it works

- `TextDocument` is a `FileDocument`; `DocumentGroup` provides open/save/autosave/undo.
  Files are decoded as UTF-8, then by Foundation's encoding sniffing, and always saved as UTF-8.
- `EditorView` wraps `NSTextView` (find bar, undo, smart quotes and dashes off).
- `MarkdownParser` uses Foundation's `AttributedString(markdown:)` in `.full` mode and walks
  the `presentationIntent` paths into a block tree. It adds what Foundation lacks: task-list
  markers, image blocks, emoji shortcodes (`EmojiShortcodes`) and code highlighting
  (`SyntaxHighlighter`, a small tokenizer with a rule set per language). No third-party
  dependencies.
- `MarkdownPreview` renders that tree with SwiftUI `Text`, `Grid`, and glass controls.
  `Typography` holds the type sizes; everything scales from them with ⌘+ / ⌘-.
- Rendering runs off the main actor and is debounced while typing in Split mode.
- `AppDelegate` quits the app after the last window closes when the setting is on.
- `Sources/GlintQuickLook` is the Quick Look extension: a `QLPreviewingController` hosting
  `MarkdownPreview` in an `NSHostingView`.

## Not done yet

- Task-list checkboxes in the preview are display only; clicking one does not edit the file.
- Highlighting is token level: no nested languages (script inside HTML) and no nested Swift
  comments.
- HTML blocks and HTML comments in Markdown show as literal text.
- Quick Look cannot load images beside the file (sandbox), and the extension needs the Xcode
  build; the SwiftPM build ships without it.
