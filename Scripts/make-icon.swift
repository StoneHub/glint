// Renders the app icon as an .iconset folder. Usage: swift Scripts/make-icon.swift build/AppIcon.iconset
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext

    let s = CGFloat(pixels)
    // Apple's macOS icon grid: the squircle fills ~80% of the canvas.
    let inset = s * 0.1
    let rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.225
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Drop shadow
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03,
                 color: NSColor.black.withAlphaComponent(0.35).cgColor)
    NSColor(calibratedRed: 0.15, green: 0.2, blue: 0.4, alpha: 1).setFill()
    squircle.fill()
    cg.restoreGState()

    // Base gradient: indigo → aqua
    NSGradient(colors: [
        NSColor(calibratedRed: 0.27, green: 0.40, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.72, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.45, green: 0.90, blue: 0.85, alpha: 1),
    ])!.draw(in: squircle, angle: -55)

    // Glass highlight across the top
    cg.saveGState()
    squircle.addClip()
    let highlight = NSBezierPath(ovalIn: NSRect(
        x: rect.minX - rect.width * 0.25, y: rect.midY + rect.height * 0.02,
        width: rect.width * 1.5, height: rect.height * 0.95
    ))
    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.38),
        NSColor.white.withAlphaComponent(0.04),
    ])!.draw(in: highlight, angle: -90)
    // Inner rim
    let rim = NSBezierPath(roundedRect: rect.insetBy(dx: s * 0.012, dy: s * 0.012),
                           xRadius: radius - s * 0.012, yRadius: radius - s * 0.012)
    rim.lineWidth = s * 0.012
    NSColor.white.withAlphaComponent(0.35).setStroke()
    rim.stroke()
    cg.restoreGState()

    // Wordmark: "M↓" (Markdown's mark) in SF Rounded
    let descriptor = NSFont.systemFont(ofSize: rect.width * 0.46, weight: .heavy)
        .fontDescriptor.withDesign(.rounded)!
    let font = NSFont(descriptor: descriptor, size: rect.width * 0.46)!
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = s * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
    let mark = NSAttributedString(string: "M↓", attributes: [
        .font: font, .foregroundColor: NSColor.white, .shadow: shadow, .kern: -rect.width * 0.02,
    ])
    let size = mark.size()
    mark.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2 + s * 0.01))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try render(pixels: points * scale).write(to: outDir.appendingPathComponent(name))
    }
}
print("iconset written to \(outDir.path)")
