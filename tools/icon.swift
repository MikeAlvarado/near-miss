// Draws the app icon. Run: swift tools/icon.swift App/Assets.xcassets/AppIcon.appiconset/icon.png
import AppKit
import CoreGraphics

let size = 1024
let s = CGFloat(size)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
// No alpha channel: the App Store rejects icons that have one.
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}
let coral = (r: CGFloat(1.0), g: CGFloat(0.42), b: CGFloat(0.36))
let teal = (r: CGFloat(0.21), g: CGFloat(0.82), b: CGFloat(0.75))

func radial(_ center: CGPoint, _ radius: CGFloat, _ colors: [CGColor], _ stops: [CGFloat]) {
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: stops)!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

// Night sky, lighter at the top. CoreGraphics has y pointing up.
let sky = CGGradient(colorsSpace: space, colors: [rgb(0.035, 0.03, 0.06), rgb(0.12, 0.10, 0.21)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: s), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
// Each side of the city is lit by the one who walks there.
radial(CGPoint(x: 200, y: 240), 620, [rgb(coral.r, coral.g, coral.b, 0.30), rgb(coral.r, coral.g, coral.b, 0)], [0, 1])
radial(CGPoint(x: 824, y: 784), 620, [rgb(teal.r, teal.g, teal.b, 0.26), rgb(teal.r, teal.g, teal.b, 0)], [0, 1])

// City blocks seen from above, a little turned. The streets are the gaps between them.
ctx.saveGState()
ctx.translateBy(x: s / 2, y: s / 2)
ctx.rotate(by: -.pi / 9)
let block: CGFloat = 196, street: CGFloat = 40
for row in -4...4 {
    for col in -4...4 {
        let x = CGFloat(col) * (block + street) - block / 2
        let y = CGFloat(row) * (block + street) - block / 2
        let park = row == 0 && col == 0
        let tone = CGFloat((row * 7 + col * 3 + 40) % 4) * 0.012
        ctx.setFillColor(park ? rgb(0.09, 0.33, 0.30, 0.95) : rgb(1, 1, 1, 0.05 + tone))
        ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: block, height: block), cornerWidth: 26, cornerHeight: 26, transform: nil))
        ctx.fillPath()
    }
}
ctx.restoreGState()

// Darken the corners so the two points carry the icon.
radial(CGPoint(x: s / 2, y: s / 2), s * 0.78, [rgb(0, 0, 0, 0), rgb(0, 0, 0, 0), rgb(0.02, 0.02, 0.04, 0.72)], [0, 0.5, 1])

let mine = CGPoint(x: 300, y: 400)
let theirs = CGPoint(x: 724, y: 624)

// The gap that was never crossed.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 18, color: rgb(1, 1, 1, 0.5))
ctx.setStrokeColor(rgb(1, 1, 1, 0.96))
ctx.setLineWidth(26)
ctx.setLineCap(.round)
ctx.setLineDash(phase: 0, lengths: [0.1, 62])
ctx.move(to: CGPoint(x: mine.x + 106, y: mine.y + 56)); ctx.addLine(to: CGPoint(x: theirs.x - 92, y: theirs.y - 49))
ctx.strokePath()
ctx.restoreGState()

/// Where one of the two stood: a ball of color with a white ring, glowing.
func point(_ c: (r: CGFloat, g: CGFloat, b: CGFloat), _ center: CGPoint) {
    radial(center, 300, [rgb(c.r, c.g, c.b, 0.6), rgb(c.r, c.g, c.b, 0.18), rgb(c.r, c.g, c.b, 0)], [0, 0.5, 1])
    let outer: CGFloat = 122, ring: CGFloat = 26
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: rgb(0, 0, 0, 0.5))
    ctx.setFillColor(rgb(1, 0.985, 0.96))
    ctx.fillEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
    ctx.restoreGState()
    let inner = outer - ring
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
    ctx.clip()
    radial(CGPoint(x: center.x - 26, y: center.y + 34), inner * 1.7, [
        rgb(min(1, c.r + 0.14), min(1, c.g + 0.14), min(1, c.b + 0.14)), rgb(c.r, c.g, c.b), rgb(c.r * 0.7, c.g * 0.7, c.b * 0.7),
    ], [0, 0.45, 1])
    ctx.restoreGState()
}
point(coral, mine)
point(teal, theirs)

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
