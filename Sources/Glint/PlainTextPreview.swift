import SwiftUI

struct PlainTextPreview: View {
    let text: String
    let scale: Double

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(.system(size: Typography.plainText * scale, design: .monospaced))
                .lineSpacing(2 * scale)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 64)
        }
    }
}
