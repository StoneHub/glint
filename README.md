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

### Quick Look extension (optional, needs Xcode and XcodeGen)

```bash
brew install xcodegen
Scripts/build.sh quicklook && Scripts/build.sh install
```

App extensions need an Xcode target, so `project.yml` is an XcodeGen spec for that one target.
`quicklook` builds the app as usual, generates `Glint.xcodeproj` (gitignored) from the spec,
builds `GlintQuickLook.appex` with `xcodebuild` (ad-hoc signed, sandboxed), embeds it under
`Contents/PlugIns`, and re-signs the app. `install` then registers it with `pluginkit`, after
which Finder's space-bar preview and `qlmanage -p file.md` render Markdown the way Glint does.
A plain `Scripts/build.sh` keeps whatever extension is already in `build/Glint.app` and says so.

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
| Settings | ⌘, |

Markdown files open in Preview, plain text in Edit; change the defaults in Settings. The
floating pill shows words / characters / lines. Links open in your browser; `[text](#heading)`
anchors scroll within the document.

The preview renders headings, paragraphs, nested lists, task lists, block quotes, tables with
alignment, rules, images (with a "missing image" note for a local file that isn't there), and
fenced code blocks with a copy button and syntax highlighting for swift, python, ruby,
javascript/typescript, json, bash/shell, yaml, html/css and sql (unknown languages get a
generic pass; a fence with no language stays plain). GitHub-style `:emoji:` shortcodes become
emoji in prose, never inside code. The editor shows the literal text.

Settings (⌘,): default mode per file type, quit when the last window closes (on by default),
and the default-opener button.

## How it works

- `TextDocument` is a `FileDocument`; `DocumentGroup` provides open/save/autosave/undo.
  `String.decodingTextFile` reads UTF-8 first, sniffs other encodings, never refuses a file;
  saving always writes UTF-8.
- `EditorView` wraps `NSTextView` (find bar, undo, smart quotes and dashes off).
- `MarkdownParser` uses Foundation's `AttributedString(markdown:)` in `.full` mode and walks
  the `presentationIntent` paths into a `MarkdownBlock` tree. Its inline pass bakes SwiftUI
  fonts into the runs and swaps emoji shortcodes; `SyntaxHighlighter` colors fenced code.
  No third-party dependencies.
- `MarkdownPreview` renders that tree with SwiftUI `Text`, `Grid`, and glass controls.
  `Typography` holds the point sizes and ratios.
- Rendering runs off the main actor and is debounced while typing in Split mode.
- `SplitPane` is a hand-rolled split: `HSplitView` lays SwiftUI children out under the glass
  toolbar.
- `AppDelegate.applicationShouldTerminateAfterLastWindowClosed` is consulted by
  `DocumentGroup` and backs the Settings toggle.
- `QuickLook/PreviewViewController` hosts `MarkdownPreview` for the Quick Look extension; it
  shares the `Markdown/` sources, `Typography` and the text decoder with the app.

## Not done yet

- Images next to a Markdown file can't be read inside the Quick Look preview (the extension's
  sandbox covers only the previewed file); the preview says "Can't read X here" in their place.
- The Quick Look extension is only built by `Scripts/build.sh quicklook`; the package-only
  build can't produce an app extension.
