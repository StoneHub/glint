import SwiftUI

/// Dependency-free highlighting for fenced code blocks: comments, strings, numbers and
/// keywords, nothing finer. Each language is a handful of rules; unknown languages get the
/// generic set. Anything a rule doesn't claim keeps the plain text color, so a wrong guess
/// costs nothing but a missed color.
struct SyntaxHighlighter: Sendable {
    let language: Language

    init(languageName: String?) {
        language = Language.named(languageName)
    }

    /// The highlighted code carries only foreground colors; the view supplies the font.
    func highlight(_ code: String) -> AttributedString {
        var result = AttributedString()
        let chars = Array(code)
        var plainStart = 0
        var index = 0

        func claim(upTo end: Int, as token: Token) {
            if plainStart < index {
                result.append(AttributedString(String(chars[plainStart..<index])))
            }
            var piece = AttributedString(String(chars[index..<end]))
            piece.foregroundColor = token.color
            result.append(piece)
            index = end
            plainStart = end
        }

        while index < chars.count {
            let scanner = CodeScanner(chars: chars, index: index, language: language)
            if let end = scanner.commentEnd() {
                claim(upTo: end, as: .comment)
            } else if let end = scanner.stringEnd() {
                claim(upTo: end, as: .string)
            } else if let end = scanner.numberEnd() {
                claim(upTo: end, as: .number)
            } else if let word = scanner.wordEnd() {
                if word.isKeyword { claim(upTo: word.end, as: .keyword) } else { index = word.end }
            } else {
                index += 1
            }
        }
        if plainStart < chars.count {
            result.append(AttributedString(String(chars[plainStart...])))
        }
        return result
    }

    private enum Token {
        case comment, string, number, keyword

        /// System colors, so they read on both the light and the dark code background.
        var color: Color {
            switch self {
            case .comment: .secondary
            case .string: .red
            case .number: .blue
            case .keyword: .purple
            }
        }
    }
}

// MARK: - Scanning

private struct CodeScanner {
    let chars: [Character]
    let index: Int
    let language: SyntaxHighlighter.Language

    /// A `//`-style comment runs to the end of the line; a block comment to its closer or EOF.
    func commentEnd() -> Int? {
        for opener in language.lineComments where hasPrefix(opener, at: index) {
            return lineEnd(from: index)
        }
        for (opener, closer) in language.blockComments where hasPrefix(opener, at: index) {
            return find(closer, from: index + opener.count).map { $0 + closer.count } ?? chars.count
        }
        return nil
    }

    /// Strings honor backslash escapes. Single-line strings give up at a newline so an
    /// unmatched quote doesn't swallow the rest of the block; triple quotes and backticks
    /// may span lines.
    func stringEnd() -> Int? {
        let quote = chars[index]
        guard language.stringQuotes.contains(quote) else { return nil }
        let triple = language.tripleQuotes && hasPrefix(String(repeating: quote, count: 3), at: index)
        let closer = triple ? String(repeating: quote, count: 3) : String(quote)
        let multiline = triple || quote == "`"
        var cursor = index + closer.count
        while cursor < chars.count {
            let char = chars[cursor]
            if char == "\\" {
                cursor += 2
            } else if hasPrefix(closer, at: cursor) {
                return cursor + closer.count
            } else if char == "\n", !multiline {
                return cursor
            } else {
                cursor += 1
            }
        }
        return chars.count
    }

    /// A digit that doesn't continue a word starts a number: `0x1F`, `3.5`, `1_000`, `1e9`, `10px`.
    func numberEnd() -> Int? {
        guard chars[index].isNumber, !isWordChar(at: index - 1) else { return nil }
        var cursor = index + 1
        while cursor < chars.count, isWordChar(at: cursor) || chars[cursor] == "." {
            cursor += 1
        }
        return cursor
    }

    /// An identifier, with whether the language calls it a keyword. Markup tag names,
    /// `@rules` and YAML-style `key:` labels count as keywords where the language says so.
    func wordEnd() -> (end: Int, isKeyword: Bool)? {
        let char = chars[index]
        if language.tags, char == "<" {
            var cursor = index + 1
            if cursor < chars.count, chars[cursor] == "/" { cursor += 1 }
            guard cursor < chars.count, chars[cursor].isLetter else { return nil }
            return (wordEnd(from: cursor), true)
        }
        if language.sigils.contains(char), index + 1 < chars.count, chars[index + 1].isLetter {
            return (wordEnd(from: index + 1), true)
        }
        guard char.isLetter || char == "_", !isWordChar(at: index - 1) else { return nil }
        let end = wordEnd(from: index)
        if language.keyLabels, end < chars.count, chars[end] == ":", atLineStart(index) {
            return (end, true)
        }
        var word = String(chars[index..<end])
        if language.caseInsensitive { word = word.lowercased() }
        return (end, language.keywords.contains(word))
    }

    // MARK: Helpers

    private func hasPrefix(_ prefix: String, at position: Int) -> Bool {
        var cursor = position
        for char in prefix {
            guard cursor < chars.count, chars[cursor] == char else { return false }
            cursor += 1
        }
        return true
    }

    private func find(_ needle: String, from position: Int) -> Int? {
        var cursor = position
        while cursor < chars.count {
            if hasPrefix(needle, at: cursor) { return cursor }
            cursor += 1
        }
        return nil
    }

    private func lineEnd(from position: Int) -> Int {
        var cursor = position
        while cursor < chars.count, chars[cursor] != "\n" { cursor += 1 }
        return cursor
    }

    private func wordEnd(from position: Int) -> Int {
        var cursor = position
        while cursor < chars.count, isWordChar(at: cursor) { cursor += 1 }
        return cursor
    }

    private func isWordChar(at position: Int) -> Bool {
        guard position >= 0, position < chars.count else { return false }
        let char = chars[position]
        return char.isLetter || char.isNumber || char == "_"
    }

    /// True when only indentation and list dashes precede `position` on its line.
    private func atLineStart(_ position: Int) -> Bool {
        var cursor = position - 1
        while cursor >= 0, chars[cursor] != "\n" {
            guard chars[cursor] == " " || chars[cursor] == "\t" || chars[cursor] == "-" else { return false }
            cursor -= 1
        }
        return true
    }
}

// MARK: - Languages

extension SyntaxHighlighter {
    struct Language: Sendable {
        var lineComments: [String] = []
        var blockComments: [(String, String)] = []
        var stringQuotes: Set<Character> = ["\""]
        var tripleQuotes = false
        var keywords: Set<String> = []
        var caseInsensitive = false
        /// Color `<tag` and `</tag` names.
        var tags = false
        /// Characters that make the following word a keyword, such as `@` for CSS at-rules.
        var sigils: Set<Character> = []
        /// Color `key:` labels at the start of a line (YAML).
        var keyLabels = false

        /// Picks the rules for a fence's info string (`swift`, `js`, `sh {.foo}`), falling back
        /// to the generic set.
        static func named(_ name: String?) -> Language {
            let key = name?.lowercased().split { !$0.isLetter && !$0.isNumber && $0 != "+" && $0 != "#" }.first
            return key.flatMap { byName[String($0)] } ?? generic
        }

        private static let byName: [String: Language] = {
            var table: [String: Language] = [:]
            for (names, language) in registry {
                for name in names { table[name] = language }
            }
            return table
        }()

        private static let registry: [([String], Language)] = [
            (["swift"], swift),
            (["python", "py"], python),
            (["ruby", "rb"], ruby),
            (["javascript", "js", "jsx", "typescript", "ts", "tsx"], javascript),
            (["json", "jsonc"], json),
            (["bash", "sh", "shell", "zsh", "console"], shell),
            (["yaml", "yml"], yaml),
            (["html", "xml", "svg"], html),
            (["css", "scss"], css),
            (["sql", "mysql", "postgresql", "psql", "sqlite"], sql),
            (["c", "cpp", "c++", "h", "objc", "java", "kotlin", "go", "rust", "rs", "cs", "c#", "csharp"], cFamily),
        ]

        static let generic = Language(lineComments: ["//"], blockComments: [("/*", "*/")])

        static let swift = Language(
            lineComments: ["//"], blockComments: [("/*", "*/")], tripleQuotes: true,
            keywords: [
                "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch", "class",
                "continue", "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
                "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "indirect", "init",
                "inout", "internal", "is", "let", "macro", "nil", "nonisolated", "open", "operator",
                "override", "package", "private", "protocol", "public", "repeat", "rethrows", "return",
                "self", "Self", "some", "static", "struct", "subscript", "super", "switch", "throw",
                "throws", "true", "try", "typealias", "var", "where", "while",
            ]
        )

        static let python = Language(
            lineComments: ["#"], stringQuotes: ["\"", "'"], tripleQuotes: true,
            keywords: [
                "False", "None", "True", "and", "as", "assert", "async", "await", "break", "case", "class",
                "continue", "def", "del", "elif", "else", "except", "finally", "for", "from", "global",
                "if", "import", "in", "is", "lambda", "match", "nonlocal", "not", "or", "pass", "raise",
                "return", "self", "try", "while", "with", "yield",
            ]
        )

        static let ruby = Language(
            lineComments: ["#"], blockComments: [("=begin", "=end")], stringQuotes: ["\"", "'", "`"],
            keywords: [
                "alias", "and", "attr_accessor", "attr_reader", "attr_writer", "begin", "break", "case",
                "class", "def", "do", "else", "elsif", "end", "ensure", "extend", "false", "for", "if",
                "include", "in", "lambda", "module", "next", "nil", "not", "or", "private", "proc",
                "protected", "public", "raise", "redo", "require", "require_relative", "rescue", "retry",
                "return", "self", "super", "then", "true", "undef", "unless", "until", "when", "while",
                "yield",
            ]
        )

        static let javascript = Language(
            lineComments: ["//"], blockComments: [("/*", "*/")], stringQuotes: ["\"", "'", "`"],
            keywords: [
                "abstract", "any", "as", "async", "await", "boolean", "break", "case", "catch", "class",
                "const", "constructor", "continue", "debugger", "declare", "default", "delete", "do",
                "else", "enum", "export", "extends", "false", "finally", "for", "from", "function", "get",
                "if", "implements", "import", "in", "instanceof", "interface", "keyof", "let", "namespace",
                "never", "new", "null", "number", "of", "package", "private", "protected", "public",
                "readonly", "return", "set", "static", "string", "super", "switch", "this", "throw",
                "true", "try", "type", "typeof", "undefined", "unknown", "var", "void", "while", "with",
                "yield",
            ]
        )

        static let json = Language(
            lineComments: ["//"], blockComments: [("/*", "*/")],
            keywords: ["true", "false", "null"]
        )

        static let shell = Language(
            lineComments: ["#"], stringQuotes: ["\"", "'"],
            keywords: [
                "alias", "break", "case", "cd", "continue", "declare", "do", "done", "echo", "elif", "else",
                "esac", "eval", "exec", "exit", "export", "fi", "for", "function", "if", "in", "local",
                "readonly", "return", "select", "set", "shift", "source", "then", "trap", "unset", "until",
                "while",
            ]
        )

        static let yaml = Language(
            lineComments: ["#"], stringQuotes: ["\"", "'"],
            keywords: ["true", "false", "null", "yes", "no", "on", "off"],
            keyLabels: true
        )

        static let html = Language(
            blockComments: [("<!--", "-->")], stringQuotes: ["\"", "'"], tags: true
        )

        static let css = Language(
            blockComments: [("/*", "*/")], stringQuotes: ["\"", "'"], sigils: ["@", "!"]
        )

        static let sql = Language(
            lineComments: ["--"], blockComments: [("/*", "*/")], stringQuotes: ["'"],
            keywords: [
                "add", "all", "alter", "and", "as", "asc", "begin", "between", "by", "cascade", "case",
                "check", "column", "commit", "constraint", "create", "default", "delete", "desc",
                "distinct", "drop", "else", "end", "exists", "false", "foreign", "from", "full", "group",
                "having", "if", "in", "index", "inner", "insert", "into", "is", "join", "key", "left",
                "like", "limit", "not", "null", "offset", "on", "or", "order", "outer", "primary",
                "references", "returning", "right", "rollback", "select", "set", "table", "then",
                "transaction", "true", "union", "unique", "update", "values", "view", "when", "where",
                "with",
            ],
            caseInsensitive: true
        )

        static let cFamily = Language(
            lineComments: ["//"], blockComments: [("/*", "*/")], stringQuotes: ["\"", "'"],
            keywords: [
                "abstract", "bool", "break", "case", "catch", "char", "class", "const", "continue",
                "default", "defer", "delete", "do", "double", "else", "enum", "extends", "false", "final",
                "finally", "float", "fn", "for", "func", "fun", "go", "if", "impl", "implements", "import",
                "include", "int", "interface", "let", "long", "match", "mod", "mut", "namespace", "new",
                "nil", "null", "nullptr", "override", "package", "private", "protected", "pub", "public",
                "return", "select", "short", "signed", "sizeof", "static", "struct", "switch", "this",
                "throw", "throws", "trait", "true", "try", "type", "typedef", "union", "unsigned", "use",
                "using", "val", "var", "virtual", "void", "when", "while",
            ]
        )
    }
}
