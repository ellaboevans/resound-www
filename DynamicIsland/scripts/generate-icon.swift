import Cocoa

// ─── Resound App Icon Generator ─────────────────────────────────────
// Uses CGContext directly for exact pixel control (no retina scaling)

func renderIcon(size: Int) -> CGImage {
    let w = size, h = size
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: w, height: h,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    )!

    let scale = CGFloat(size) / 1024.0

    // Flip so y=0 is at the top (matches spec coordinates)
    context.translateBy(x: 0, y: CGFloat(h))
    context.scaleBy(x: 1, y: -1)

    // ── Background gradient ──
    let colors = [
        CGColor(red: 0, green: 0, blue: 0, alpha: 1),          // #000 bottom
        CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1),  // #333 top
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    context.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: CGFloat(h)),
                               end: CGPoint(x: 0, y: 0),
                               options: [])

    // ── Pill geometry (at 1024 scale) ──
    let pillW: CGFloat = 520 * scale
    let pillH: CGFloat = 180 * scale
    let pillR: CGFloat = 28 * scale
    let pillCX = CGFloat(w) / 2
    let pillCY: CGFloat = 460 * scale
    let pillX = pillCX - pillW / 2
    let pillY = pillCY - pillH / 2

    let lineW = max(1, ceil(4 * scale))

    // ── Pill outline path ──
    let pillPath = CGMutablePath()
    pillPath.move(to: CGPoint(x: pillX, y: pillY))
    pillPath.addLine(to: CGPoint(x: pillX + pillW, y: pillY))
    pillPath.addLine(to: CGPoint(x: pillX + pillW, y: pillY + pillH - pillR))
    pillPath.addArc(tangent1End: CGPoint(x: pillX + pillW, y: pillY + pillH),
                    tangent2End: CGPoint(x: pillX + pillW - pillR, y: pillY + pillH),
                    radius: pillR)
    pillPath.addLine(to: CGPoint(x: pillX + pillR, y: pillY + pillH))
    pillPath.addArc(tangent1End: CGPoint(x: pillX, y: pillY + pillH),
                    tangent2End: CGPoint(x: pillX, y: pillY + pillH - pillR),
                    radius: pillR)
    pillPath.addLine(to: CGPoint(x: pillX, y: pillY))
    pillPath.closeSubpath()

    // Draw pill outline
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(lineW)
    context.setLineJoin(.round)
    context.addPath(pillPath)
    context.strokePath()

    // ── Waveform bars ──
    struct Bar {
        let x: CGFloat  // relative to pill center
        let y: CGFloat  // from pill top
        let width: CGFloat
        let height: CGFloat
        let alpha: CGFloat
    }

    let bars: [Bar] = [
        Bar(x: -225, y: 40, width: 18, height: 100, alpha: 0.4),
        Bar(x: -190, y: 20, width: 18, height: 140, alpha: 0.7),
        Bar(x: -155, y: 55, width: 18, height: 80, alpha: 0.5),
        Bar(x: -118, y: 10, width: 22, height: 155, alpha: 1.0),
        Bar(x: -78, y: 30, width: 18, height: 125, alpha: 0.8),
        Bar(x: -43, y: 60, width: 18, height: 70, alpha: 0.45),
        Bar(x: -8, y: 35, width: 18, height: 115, alpha: 0.65),
        Bar(x: 27, y: 15, width: 22, height: 145, alpha: 0.9),
        Bar(x: 67, y: 45, width: 18, height: 95, alpha: 0.55),
        Bar(x: 102, y: 25, width: 18, height: 130, alpha: 0.75),
        Bar(x: 137, y: 50, width: 18, height: 85, alpha: 0.5),
        Bar(x: 172, y: 65, width: 18, height: 60, alpha: 0.35),
    ]

    // Clip to pill interior
    context.saveGState()
    context.addPath(pillPath)
    context.clip()

    for bar in bars {
        let bx = (512 + bar.x) * scale
        let by = (370 + bar.y) * scale
        let bw = bar.width * scale
        let bh = bar.height * scale
        let br = ceil(min(bar.width, bar.height) / 2) * scale

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: bar.alpha))
        let barPath = CGMutablePath()
        barPath.addRoundedRect(in: CGRect(x: bx, y: by, width: bw, height: bh),
                               cornerWidth: br, cornerHeight: br)
        context.addPath(barPath)
        context.fillPath()
    }

    context.restoreGState()

    return context.makeImage()!
}

// ─── Export ─────────────────────────────────────────────────────────
let sizes: [(name: String, w: Int, h: Int)] = [
    ("icon_16x16", 16, 16),
    ("icon_16x16@2x", 32, 32),
    ("icon_32x32", 32, 32),
    ("icon_32x32@2x", 64, 64),
    ("icon_128x128", 128, 128),
    ("icon_128x128@2x", 256, 256),
    ("icon_256x256", 256, 256),
    ("icon_256x256@2x", 512, 512),
    ("icon_512x512", 512, 512),
    ("icon_512x512@2x", 1024, 1024),
]

let iconsetPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/Resound.iconset"

try? FileManager.default.createDirectory(atPath: iconsetPath,
                                          withIntermediateDirectories: true)

for s in sizes {
    let cgImage = renderIcon(size: s.w)
    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(s.name)")
        continue
    }
    let path = "\(iconsetPath)/\(s.name).png"
    try png.write(to: URL(fileURLWithPath: path))
    print("  ✓ \(s.name) (\(s.w)×\(s.h)) — \(png.count) bytes")
}

// ─── Build .icns ────────────────────────────────────────────────────
let icnsPath = (iconsetPath as NSString)
    .deletingLastPathComponent
    .appending("/Resound.icns")
try? FileManager.default.removeItem(atPath: icnsPath)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("\n✓ Created \(icnsPath)")
} else {
    print("\n✗ iconutil failed")
}
