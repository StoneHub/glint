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

    /// Always writes UTF-8, whatever encoding the file arrived in.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    /// Opening a text file must not fail on encoding: UTF-8 first, then Foundation's sniffing
    /// for legacy encodings, and as a last resort UTF-8 with replacement characters.
    /// Shared with the Quick Look extension.
    static func decode(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        var sniffed: NSString?
        let encoding = NSString.stringEncoding(
            for: data, encodingOptions: nil, convertedString: &sniffed, usedLossyConversion: nil
        )
        if encoding != 0, let sniffed {
            return sniffed as String
        }
        return String(decoding: data, as: UTF8.self)
    }
}
