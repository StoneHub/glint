import AppKit
import SwiftUI

/// A resizable two-pane split, hand-rolled in SwiftUI.
///
/// `HSplitView` is AppKit-backed and mishandles the glass toolbar's safe area for SwiftUI
/// children: content lands under the toolbar. A plain `HStack` with a draggable divider lays
/// out normally, so that is what this is.
struct SplitPane<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    @State private var fraction: CGFloat = 0.5
    @State private var dragStartFraction: CGFloat?

    private let minimumWidth: CGFloat = 280

    var body: some View {
        GeometryReader { geometry in
            let total = geometry.size.width
            let leadingWidth = min(max(total * fraction, minimumWidth), max(total - minimumWidth, minimumWidth))
            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth)
                Divider()
                    .overlay {
                        Color.clear
                            .frame(width: 9)
                            .contentShape(Rectangle())
                            .onHover { inside in
                                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 1, coordinateSpace: .named("split"))
                                    .onChanged { value in
                                        if dragStartFraction == nil { dragStartFraction = fraction }
                                        let start = dragStartFraction ?? fraction
                                        fraction = min(max(start + value.translation.width / total, 0.15), 0.85)
                                    }
                                    .onEnded { _ in dragStartFraction = nil }
                            )
                    }
                trailing()
                    .frame(maxWidth: .infinity)
            }
            .coordinateSpace(name: "split")
        }
    }
}
