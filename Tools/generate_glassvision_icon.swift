import AppKit
import CoreGraphics
import Foundation

let fileManager = FileManager.default
let basePath = "/Users/maxcaro/Library/Mobile Documents/com~apple~CloudDocs/VisionOs copy/GlassVision/GlassVision/Assets.xcassets/AppIcon.solidimagestack"
let size = CGSize(width: 1024, height: 1024)

enum Layer: String, CaseIterable {
    case front = "Front"
    case middle = "Middle"
    case back = "Back"

    var outputPath: String {
        "\(basePath)/\(rawValue).solidimagestacklayer/Content.imageset/\(rawValue).png"
    }
}

let previewPath = "\(basePath)/AppIconPreview.png"

struct Palette {
    static let dusk = NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1)
    static let portalBlue = NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.84, alpha: 1)
    static let portalCyan = NSColor(calibratedRed: 0.36, green: 0.84, blue: 0.98, alpha: 1)
    static let brassDark = NSColor(calibratedRed: 0.39, green: 0.25, blue: 0.08, alpha: 1)
    static let brass = NSColor(calibratedRed: 0.77, green: 0.58, blue: 0.23, alpha: 1)
    static let brassHighlight = NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.52, alpha: 1)
    static let ember = NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.22, alpha: 1)
    static let parchment = NSColor(calibratedRed: 0.96, green: 0.91, blue: 0.76, alpha: 1)
}

func savePNG(at path: String, drawing: (CGContext) -> Void) throws {
    let width = Int(size.width)
    let height = Int(size.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(domain: "GlassVisionIcon", code: 1)
    }

    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)

    drawing(context)

    guard let image = context.makeImage() else {
        throw NSError(domain: "GlassVisionIcon", code: 2)
    }

    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GlassVisionIcon", code: 3)
    }

    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

func save(layer: Layer, drawing: (CGContext) -> Void) throws {
    try savePNG(at: layer.outputPath, drawing: drawing)
}

func radialGradient(
    in context: CGContext,
    center: CGPoint,
    startRadius: CGFloat,
    endRadius: CGFloat,
    colors: [NSColor],
    locations: [CGFloat]
) {
    let cgColors = colors.map(\.cgColor) as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) else {
        return
    }
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: startRadius,
        endCenter: center,
        endRadius: endRadius,
        options: [.drawsAfterEndLocation]
    )
}

func fillRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, colors: [NSColor], locations: [CGFloat], angle: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.addPath(path)
    context.clip()

    let cgColors = colors.map(\.cgColor) as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) else {
        context.restoreGState()
        return
    }

    let start = CGPoint(x: rect.midX - cos(angle) * rect.width * 0.6, y: rect.midY - sin(angle) * rect.height * 0.6)
    let end = CGPoint(x: rect.midX + cos(angle) * rect.width * 0.6, y: rect.midY + sin(angle) * rect.height * 0.6)
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

func addSparkles(_ context: CGContext, points: [CGPoint], radius: CGFloat, color: NSColor, alpha: CGFloat) {
    context.saveGState()
    context.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
    context.setLineWidth(6)
    context.setLineCap(.round)

    for point in points {
        context.move(to: CGPoint(x: point.x - radius, y: point.y))
        context.addLine(to: CGPoint(x: point.x + radius, y: point.y))
        context.move(to: CGPoint(x: point.x, y: point.y - radius))
        context.addLine(to: CGPoint(x: point.x, y: point.y + radius))
        context.strokePath()
    }

    context.restoreGState()
}

func drawBack(_ context: CGContext) {
    let rect = CGRect(origin: .zero, size: size)
    fillRoundedRect(
        context,
        rect: rect,
        radius: 0,
        colors: [
            NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.14, alpha: 1),
            NSColor(calibratedRed: 0.12, green: 0.11, blue: 0.14, alpha: 1)
        ],
        locations: [0, 1],
        angle: .pi / 4
    )

    fillRoundedRect(
        context,
        rect: rect,
        radius: 240,
        colors: [
            Palette.dusk,
            NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.19, alpha: 1),
            NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.11, alpha: 1)
        ],
        locations: [0, 0.55, 1],
        angle: .pi / 4
    )

    radialGradient(
        in: context,
        center: CGPoint(x: 520, y: 590),
        startRadius: 0,
        endRadius: 360,
        colors: [
            Palette.portalCyan.withAlphaComponent(0.96),
            Palette.portalBlue.withAlphaComponent(0.94),
            NSColor(calibratedRed: 0.05, green: 0.15, blue: 0.28, alpha: 0.95),
            NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.09, alpha: 0)
        ],
        locations: [0.0, 0.35, 0.72, 1.0]
    )

    radialGradient(
        in: context,
        center: CGPoint(x: 500, y: 540),
        startRadius: 0,
        endRadius: 200,
        colors: [
            Palette.parchment.withAlphaComponent(0.46),
            Palette.ember.withAlphaComponent(0.18),
            NSColor.clear
        ],
        locations: [0, 0.5, 1]
    )

    let starPoints = [
        CGPoint(x: 360, y: 740),
        CGPoint(x: 670, y: 715),
        CGPoint(x: 702, y: 470),
        CGPoint(x: 328, y: 500),
        CGPoint(x: 596, y: 330)
    ]
    addSparkles(context, points: starPoints, radius: 18, color: Palette.parchment, alpha: 0.65)

    context.setFillColor(Palette.parchment.withAlphaComponent(0.1).cgColor)
    for point in [CGPoint(x: 268, y: 624), CGPoint(x: 758, y: 614), CGPoint(x: 612, y: 804), CGPoint(x: 452, y: 284)] {
        context.fillEllipse(in: CGRect(x: point.x - 9, y: point.y - 9, width: 18, height: 18))
    }
}

func drawMiddle(_ context: CGContext) {
    context.saveGState()
    context.translateBy(x: 495, y: 540)
    context.rotate(by: -.pi / 5.5)

    let handleRect = CGRect(x: -42, y: -390, width: 84, height: 360)
    let handlePath = CGPath(roundedRect: handleRect, cornerWidth: 42, cornerHeight: 42, transform: nil)

    context.setShadow(offset: CGSize(width: 0, height: -22), blur: 36, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    context.addPath(handlePath)
    context.setFillColor(Palette.brassDark.cgColor)
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)

    fillRoundedRect(
        context,
        rect: handleRect,
        radius: 42,
        colors: [Palette.brassHighlight, Palette.brass, Palette.brassDark],
        locations: [0, 0.5, 1],
        angle: .pi / 2
    )

    let ringOuter = CGRect(x: -236, y: -136, width: 472, height: 472)
    let ringInner = CGRect(x: -172, y: -72, width: 344, height: 344)

    let outerPath = CGMutablePath()
    outerPath.addEllipse(in: ringOuter)
    outerPath.addEllipse(in: ringInner)

    context.addPath(outerPath)
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 38, color: NSColor.black.withAlphaComponent(0.26).cgColor)
    context.setFillColor(Palette.brassDark.cgColor)
    context.drawPath(using: .eoFill)
    context.setShadow(offset: .zero, blur: 0, color: nil)

    let brassColors = [Palette.brassHighlight.cgColor, Palette.brass.cgColor, Palette.brassDark.cgColor] as CFArray
    let brassLocations: [CGFloat] = [0, 0.48, 1]
    guard let brassGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: brassColors, locations: brassLocations) else {
        return
    }
    context.saveGState()
    context.addPath(outerPath)
    context.clip(using: .evenOdd)
    context.drawLinearGradient(
        brassGradient,
        start: CGPoint(x: -250, y: 330),
        end: CGPoint(x: 230, y: -120),
        options: []
    )
    context.restoreGState()

    let innerGlowPath = CGPath(ellipseIn: CGRect(x: -184, y: -84, width: 368, height: 368), transform: nil)
    context.addPath(innerGlowPath)
    context.setLineWidth(16)
    context.setStrokeColor(Palette.parchment.withAlphaComponent(0.22).cgColor)
    context.strokePath()

    let handleCapRect = CGRect(x: -60, y: -432, width: 120, height: 92)
    fillRoundedRect(
        context,
        rect: handleCapRect,
        radius: 42,
        colors: [Palette.brassHighlight, Palette.brass, Palette.brassDark],
        locations: [0, 0.45, 1],
        angle: .pi / 2
    )

    context.restoreGState()
}

func drawFront(_ context: CGContext) {
    context.saveGState()
    context.translateBy(x: 495, y: 540)
    context.rotate(by: -.pi / 5.5)

    context.setLineWidth(10)
    context.setStrokeColor(Palette.parchment.withAlphaComponent(0.6).cgColor)
    context.strokeEllipse(in: CGRect(x: -205, y: -105, width: 410, height: 410))

    context.setLineWidth(6)
    context.setStrokeColor(Palette.portalCyan.withAlphaComponent(0.45).cgColor)
    context.strokeEllipse(in: CGRect(x: -164, y: -64, width: 328, height: 328))

    context.setFillColor(Palette.parchment.withAlphaComponent(0.22).cgColor)
    context.fillEllipse(in: CGRect(x: 66, y: 138, width: 56, height: 18))
    context.fillEllipse(in: CGRect(x: -32, y: 178, width: 140, height: 22))

    addSparkles(
        context,
        points: [
            CGPoint(x: 114, y: 122),
            CGPoint(x: -110, y: 52),
            CGPoint(x: 22, y: -42)
        ],
        radius: 15,
        color: Palette.parchment,
        alpha: 0.88
    )

    context.setStrokeColor(Palette.brassHighlight.withAlphaComponent(0.65).cgColor)
    context.setLineWidth(8)
    context.move(to: CGPoint(x: -18, y: -360))
    context.addLine(to: CGPoint(x: 20, y: -388))
    context.strokePath()

    context.restoreGState()
}

func updateContentsJSON(for layer: Layer) throws {
    let url = URL(fileURLWithPath: "\(basePath)/\(layer.rawValue).solidimagestacklayer/Content.imageset/Contents.json")
    let data = try Data(contentsOf: url)
    guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          var images = object["images"] as? [[String: Any]],
          !images.isEmpty else {
        throw NSError(domain: "GlassVisionIcon", code: 4)
    }

    images[0]["filename"] = "\(layer.rawValue).png"
    object["images"] = images

    let updatedData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try updatedData.write(to: url, options: .atomic)
}

do {
    try fileManager.createDirectory(atPath: "\(basePath)/Front.solidimagestacklayer/Content.imageset", withIntermediateDirectories: true)
    try fileManager.createDirectory(atPath: "\(basePath)/Middle.solidimagestacklayer/Content.imageset", withIntermediateDirectories: true)
    try fileManager.createDirectory(atPath: "\(basePath)/Back.solidimagestacklayer/Content.imageset", withIntermediateDirectories: true)

    try save(layer: .back, drawing: drawBack)
    try save(layer: .middle, drawing: drawMiddle)
    try save(layer: .front, drawing: drawFront)
    try savePNG(at: previewPath) { context in
        drawBack(context)
        drawMiddle(context)
        drawFront(context)
    }

    for layer in Layer.allCases {
        try updateContentsJSON(for: layer)
    }

    print("Generated Glass Vision icon layers.")
} catch {
    fputs("Failed to generate icon: \(error)\n", stderr)
    exit(1)
}
