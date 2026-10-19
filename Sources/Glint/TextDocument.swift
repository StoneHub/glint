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

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    /// UTF-8 first; otherwise let Foundation sniff the encoding; never fail to open a text file.
    private static func decode(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        var converted: NSString?
        let encoding = NSString.stringEncoding(
            for: data, encodingOptions: nil, convertedString: &converted, usedLossyConversion: nil
        )
        if encoding != 0, let converted { return converted as String }
        return String(decoding: data, as: UTF8.self)
    }
}
