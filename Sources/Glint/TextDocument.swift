import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Declared in Info.plist (UTImportedTypeDeclarations) so Finder can map .md/.markdown to us.
    static let markdownText = UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
}

struct TextDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.markdownText, .plainText, .text]
    static let writableContentTypes: [UTType] = [.markdownText, .plainText]

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = Self.decode(data)
    }

    /// Always written as UTF-8, whatever encoding the file was read in.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    /// Never refuses a text file: UTF-8 first, then Foundation's encoding sniff, and as a
    /// last resort UTF-8 with undecodable bytes replaced by U+FFFD.
    private static func decode(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        var sniffed: NSString?
        let encoding = NSString.stringEncoding(
            for: data, encodingOptions: nil, convertedString: &sniffed, usedLossyConversion: nil
        )
        if encoding != 0, let sniffed { return sniffed as String } // 0 means "couldn't tell"
        return String(decoding: data, as: UTF8.self)
    }
}
