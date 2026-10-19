import Foundation

extension String {
    /// Never refuses a text file: UTF-8 first, then Foundation's encoding sniff, and as a
    /// last resort UTF-8 with undecodable bytes replaced by U+FFFD.
    static func decodingTextFile(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        var sniffed: NSString?
        let encoding = NSString.stringEncoding(
            for: data, encodingOptions: nil, convertedString: &sniffed, usedLossyConversion: nil
        )
        if encoding != 0, let sniffed { return sniffed as String } // 0 means "couldn't tell"
        return String(decoding: data, as: UTF8.self)
    }
}
