import AppKit
import SwiftUI

/// Colors comments, strings, numbers and keywords in a fenced code block. It is a tokenizer,
/// not a parser: enough to make code readable in a document viewer, with no dependencies.
/// Every token starts at an ASCII byte, so scanning the UTF-8 view never splits a scalar.
struct SyntaxHighlighter: Sendable {
    enum Token {
        case comment, string, number, keyword

        var color: Color {
            switch self {
            case .comment: Color(nsColor: .secondaryLabelColor)
            case .string: Color(nsColor: .systemRed)
            case .number: Color(nsColor: .systemBlue)
            case .keyword: Color(nsColor: .systemPurple)
            }
        }
    }

    struct Language: Sendable {
        var lineComments: [String] = []
        var blockComment: (open: String, close: String)?
        /// Longest first. One-character delimiters end at the line; longer ones (`"""`) and backticks may span lines.
        var strings: [String] = ["\"", "'"]
        var keywords: Set<String> = []
        var caseInsensitiveKeywords = false
        /// `<name` and `</name` read as keywords (HTML).
        var tags = false
        /// `name:` at the start of a line reads as a keyword (YAML).
        var keys = false
    }

    let language: Language

    /// nil for a fence with no language: that is often output or prose, so it stays plain.
    /// Unknown names get a generic C-style treatment.
    init?(languageNamed name: String?) {
        guard let name, !name.isEmpty else { return nil }
        language = Self.languages[name.lowercased()] ?? Self.generic
    }

    func highlight(_ code: String) -> AttributedString {
        var scanner = Scanner(code: code, language: language)
        var result = AttributedString()
        var plainStart = code.utf8.startIndex

        func flushPlain(upTo index: String.Index) {
            if plainStart < index {
                result.append(AttributedString(String(decoding: code.utf8[plainStart..<index], as: UTF8.self)))
            }
        }

        while let (range, token) = scanner.nextToken() {
            flushPlain(upTo: range.lowerBound)
            var piece = AttributedString(String(decoding: code.utf8[range], as: UTF8.self))
            piece.foregroundColor = token.color
            result.append(piece)
            plainStart = range.upperBound
        }
        flushPlain(upTo: code.utf8.endIndex)
        return result
    }

    // MARK: Scanner

    private struct Scanner {
        let code: String
        let language: Language
        var index: String.Index
        /// True until something other than indentation or a list dash has been seen on the line.
        var atLineStart = true

        init(code: String, language: Language) {
            self.code = code
            self.language = language
            index = code.utf8.startIndex
        }

        private var bytes: String.UTF8View { code.utf8 }

        mutating func nextToken() -> (Range<String.Index>, Token)? {
            while index < bytes.endIndex {
                let start = index
                let byte = bytes[index]
                let wasLineStart = atLineStart
                atLineStart = byte == UInt8(ascii: "\n")
                    || (wasLineStart && (byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") || isListDash()))

                if let pair = language.blockComment, matches(pair.open) {
                    advance(by: pair.open.utf8.count)
                    skipThrough(pair.close)
                    return (start..<index, .comment)
                }
                if let comment = language.lineComments.first(where: matches) {
                    advance(by: comment.utf8.count)
                    skipToEndOfLine()
                    return (start..<index, .comment)
                }
                if let delimiter = language.strings.first(where: matches) {
                    advance(by: delimiter.utf8.count)
                    skipString(closedBy: delimiter)
                    return (start..<index, .string)
                }
                if language.tags, byte == UInt8(ascii: "<"), let next = peek(1),
                   next == UInt8(ascii: "/") || next.isASCIILetter {
                    advance(by: next == UInt8(ascii: "/") ? 2 : 1)
                    skipWhile { $0.isASCIILetter || $0.isASCIIDigit || $0 == UInt8(ascii: "-") }
                    return (start..<index, .keyword)
                }
                if byte.isASCIIDigit {
                    skipWhile { $0.isASCIILetter || $0.isASCIIDigit || $0 == UInt8(ascii: "_") || $0 == UInt8(ascii: ".") }
                    return (start..<index, .number)
                }
                if byte.isASCIILetter || byte == UInt8(ascii: "_") {
                    skipWhile { $0.isASCIILetter || $0.isASCIIDigit || $0 == UInt8(ascii: "_") || $0 == UInt8(ascii: "-") }
                    if language.keys, wasLineStart, peek() == UInt8(ascii: ":") {
                        return (start..<index, .keyword)
                    }
                    let word = String(decoding: bytes[start..<index], as: UTF8.self)
                    let key = language.caseInsensitiveKeywords ? word.lowercased() : word
                    if language.keywords.contains(key) {
                        return (start..<index, .keyword)
                    }
                    continue
                }
                advance(by: 1)
            }
            return nil
        }

        // MARK: Cursor helpers

        private func peek(_ offset: Int = 0) -> UInt8? {
            guard let at = bytes.index(index, offsetBy: offset, limitedBy: bytes.endIndex), at < bytes.endIndex else { return nil }
            return bytes[at]
        }

        private func matches(_ literal: String) -> Bool {
            bytes[index...].starts(with: literal.utf8)
        }

        private func isListDash() -> Bool {
            bytes[index] == UInt8(ascii: "-") && peek(1) == UInt8(ascii: " ")
        }

        private mutating func advance(by count: Int) {
            index = bytes.index(index, offsetBy: count, limitedBy: bytes.endIndex) ?? bytes.endIndex
        }

        private mutating func skipWhile(_ keep: (UInt8) -> Bool) {
            while index < bytes.endIndex, keep(bytes[index]) {
                index = bytes.index(after: index)
            }
        }

        private mutating func skipToEndOfLine() {
            skipWhile { $0 != UInt8(ascii: "\n") }
        }

        private mutating func skipThrough(_ close: String) {
            while index < bytes.endIndex {
                if matches(close) {
                    advance(by: close.utf8.count)
                    return
                }
                index = bytes.index(after: index)
            }
        }

        private mutating func skipString(closedBy delimiter: String) {
            let multiline = delimiter.utf8.count > 1 || delimiter == "`"
            while index < bytes.endIndex {
                let byte = bytes[index]
                if byte == UInt8(ascii: "\\") {
                    advance(by: 2)
                    continue
                }
                if !multiline, byte == UInt8(ascii: "\n") { return }
                if matches(delimiter) {
                    advance(by: delimiter.utf8.count)
                    return
                }
                index = bytes.index(after: index)
            }
        }
    }

    // MARK: Languages

    private static let generic = Language(
        lineComments: ["//", "#"],
        blockComment: ("/*", "*/")
    )

    private static let cFamilyComments = Language(lineComments: ["//"], blockComment: ("/*", "*/"))

    private static let languages: [String: Language] = {
        var swift = cFamilyComments
        swift.strings = ["\"\"\"", "\""]
        swift.keywords = [
            "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch", "class",
            "continue", "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
            "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout",
            "internal", "is", "let", "macro", "nil", "nonisolated", "open", "operator", "override",
            "private", "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "some",
            "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
            "typealias", "var", "where", "while",
        ]

        var python = Language(lineComments: ["#"], strings: ["\"\"\"", "'''", "\"", "'"])
        python.keywords = [
            "False", "None", "True", "and", "as", "assert", "async", "await", "break", "case", "class",
            "continue", "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if",
            "import", "in", "is", "lambda", "match", "nonlocal", "not", "or", "pass", "raise", "return",
            "self", "try", "while", "with", "yield",
        ]

        var ruby = Language(lineComments: ["#"], blockComment: ("=begin", "=end"))
        ruby.keywords = [
            "alias", "and", "attr_accessor", "attr_reader", "attr_writer", "begin", "break", "case",
            "class", "def", "do", "else", "elsif", "end", "ensure", "extend", "false", "for", "if", "in",
            "include", "module", "next", "nil", "not", "or", "private", "protected", "public", "raise",
            "redo", "require", "require_relative", "rescue", "retry", "return", "self", "super", "then",
            "true", "undef", "unless", "until", "when", "while", "yield",
        ]

        var javascript = cFamilyComments
        javascript.strings = ["\"", "'", "`"]
        javascript.keywords = [
            "abstract", "any", "as", "async", "await", "boolean", "break", "case", "catch", "class",
            "const", "constructor", "continue", "debugger", "declare", "default", "delete", "do", "else",
            "enum", "export", "extends", "false", "finally", "for", "from", "function", "get", "if",
            "implements", "import", "in", "instanceof", "interface", "let", "namespace", "never", "new",
            "null", "number", "of", "private", "protected", "public", "readonly", "return", "set",
            "static", "string", "super", "switch", "this", "throw", "true", "try", "type", "typeof",
            "undefined", "unknown", "var", "void", "while", "with", "yield",
        ]

        let json = Language(strings: ["\""], keywords: ["true", "false", "null"])

        var shell = Language(lineComments: ["#"])
        shell.keywords = [
            "alias", "case", "cd", "declare", "do", "done", "echo", "elif", "else", "esac", "exit",
            "export", "false", "fi", "for", "function", "if", "in", "local", "printf", "read",
            "readonly", "return", "select", "set", "shift", "source", "then", "true", "unset", "until",
            "while",
        ]

        var yaml = Language(lineComments: ["#"])
        yaml.keywords = ["true", "false", "null", "yes", "no", "on", "off"]
        yaml.keys = true

        var html = Language(blockComment: ("<!--", "-->"), strings: ["\""])
        html.tags = true

        var css = cFamilyComments
        css.lineComments = []

        var sql = Language(lineComments: ["--"], blockComment: ("/*", "*/"))
        sql.caseInsensitiveKeywords = true
        sql.keywords = [
            "add", "all", "alter", "and", "as", "asc", "begin", "between", "by", "case", "check",
            "commit", "constraint", "count", "create", "default", "delete", "desc", "distinct", "drop",
            "else", "end", "exists", "false", "foreign", "from", "group", "having", "in", "index",
            "inner", "insert", "into", "is", "join", "key", "left", "like", "limit", "not", "null",
            "offset", "on", "or", "order", "outer", "primary", "references", "returning", "right",
            "rollback", "select", "set", "table", "then", "transaction", "true", "union", "unique",
            "update", "values", "view", "when", "where", "with",
        ]

        return [
            "swift": swift,
            "python": python, "py": python,
            "ruby": ruby, "rb": ruby,
            "javascript": javascript, "js": javascript, "jsx": javascript,
            "typescript": javascript, "ts": javascript, "tsx": javascript,
            "json": json,
            "bash": shell, "sh": shell, "shell": shell, "zsh": shell,
            "yaml": yaml, "yml": yaml,
            "html": html, "xml": html, "svg": html,
            "css": css, "scss": css,
            "sql": sql,
        ]
    }()
}

private extension UInt8 {
    var isASCIILetter: Bool {
        (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(self) || (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(self)
    }

    var isASCIIDigit: Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(self)
    }
}
