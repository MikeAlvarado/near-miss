// Draws the app icon. Run: swift tools/icon.swift App/Assets.xcassets/AppIcon.appiconset/icon.png
// Two people circle the same spot, each leaving a trail that fades before it reaches the other.
// Orange and blue on warm white.
import AppKit
import CoreGraphics

let size = 1024
let s = CGFloat(size)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
// No alpha channel: the App Store rejects icons that have one.
// Drawn four times larger and scaled down at the end, so the trails come out smooth.
let over = 4
let ctx = CGContext(
    data: nil, width: size * over, height: size * over, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
ctx.scaleBy(x: CGFloat(over), y: CGFloat(over))

typealias Tone = (r: CGFloat, g: CGFloat, b: CGFloat)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

func radial(_ center: CGPoint, _ radius: CGFloat, _ colors: [CGColor], _ stops: [CGFloat]) {
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: stops)!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

// Warm white paper, a little warmer toward the bottom right. CoreGraphics has y pointing up.
let paper = CGGradient(
    colorsSpace: space,
    colors: [rgb(1.0, 0.995, 0.985), rgb(1.0, 0.955, 0.915)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(paper, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

let center = CGPoint(x: s / 2, y: s / 2)
let orbit: CGFloat = 222
let ball: CGFloat = 124

func place(_ degrees: CGFloat, _ radius: CGFloat) -> CGPoint {
    let a = degrees * .pi / 180
    return CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
}

/// A trail behind the ball: as wide as the ball where it starts, thinning to nothing.
func trail(from start: CGFloat, _ tone: Tone, strength: CGFloat) {
    let sweep: CGFloat = 168
    let slices = 900
    // Slices that do not blend at their edges leave no seams.
    ctx.setShouldAntialias(false)
    defer { ctx.setShouldAntialias(true) }
    for i in 0..<slices {
        let t0 = CGFloat(i) / CGFloat(slices)
        let t1 = CGFloat(i + 1) / CGFloat(slices)
        let w0 = ball * pow(1 - t0, 0.85)
        let w1 = ball * pow(1 - t1 < 0 ? 0 : 1 - t1, 0.85)
        let a0 = start - sweep * t0
        let a1 = start - sweep * t1
        ctx.beginPath()
        ctx.move(to: place(a0, orbit + w0))
        ctx.addLine(to: place(a1, orbit + w1))
        ctx.addLine(to: place(a1, orbit - w1))
        ctx.addLine(to: place(a0, orbit - w0))
        ctx.closePath()
        ctx.setFillColor(rgb(tone.r, tone.g, tone.b, strength * pow(1 - t0, 1.5)))
        ctx.fillPath()
    }
}

func orb(at degrees: CGFloat, _ tone: Tone, light: Tone, dark: Tone) {
    let c = place(degrees, orbit)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 44, color: rgb(0.30, 0.16, 0.08, 0.28))
    ctx.setFillColor(rgb(tone.r, tone.g, tone.b))
    ctx.fillEllipse(in: CGRect(x: c.x - ball, y: c.y - ball, width: ball * 2, height: ball * 2))
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - ball, y: c.y - ball, width: ball * 2, height: ball * 2))
    ctx.clip()
    radial(CGPoint(x: c.x - ball * 0.34, y: c.y + ball * 0.4), ball * 1.75, [
        rgb(light.r, light.g, light.b), rgb(tone.r, tone.g, tone.b), rgb(dark.r, dark.g, dark.b),
    ], [0, 0.5, 1])
    ctx.restoreGState()
}

let orange: Tone = (1.0, 0.36, 0.12)
let blue: Tone = (0.16, 0.50, 0.98)

trail(from: 52, blue, strength: 0.5)
trail(from: 232, orange, strength: 0.5)
orb(at: 52, blue, light: (0.50, 0.76, 1.0), dark: (0.05, 0.30, 0.82))
orb(at: 232, orange, light: (1.0, 0.66, 0.38), dark: (0.88, 0.20, 0.02))

let final = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
final.interpolationQuality = .high
final.draw(ctx.makeImage()!, in: CGRect(x: 0, y: 0, width: size, height: size))
let image = final.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
