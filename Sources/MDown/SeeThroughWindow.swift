import AppKit
import SwiftUI

/// The "See-through glass background" setting: replaces the window's opaque background with
/// Liquid Glass, so the desktop shows through. Off leaves the window exactly as AppKit draws it.
struct SeeThroughWindow: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.containerBackground(for: .window) { GlassBackdrop() }
        } else {
            content
        }
    }
}

/// AppKit's glass view filling the window. It is the system's own glass, so it follows the
/// clear-to-tinted Liquid Glass setting like the toolbar does.
private struct GlassBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        NSGlassEffectView()
    }

    func updateNSView(_ glass: NSGlassEffectView, context: Context) {}
}
