import SwiftUI

struct StatsPill: View {
    let text: String

    var body: some View {
        let stats = TextStats(text)
        HStack(spacing: 10) {
            stat(stats.words, "words")
            dot
            stat(stats.characters, "chars")
            dot
            stat(stats.lines, "lines")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect()
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(value.formatted()).foregroundStyle(.primary)
            Text(label)
        }
    }

    private var dot: some View {
        Circle().fill(.tertiary).frame(width: 3, height: 3)
    }
}

struct TextStats {
    let words: Int
    let characters: Int
    let lines: Int

    init(_ text: String) {
        words = text.split(whereSeparator: \.isWhitespace).count
        characters = text.count
        lines = text.isEmpty ? 0 : text.reduce(into: 1) { if $1 == "\n" { $0 += 1 } }
    }
}
