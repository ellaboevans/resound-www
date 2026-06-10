import Cocoa

let width = 600
let height = 400
let rect = CGRect(x: 0, y: 0, width: width, height: height)

let image = NSImage(size: rect.size)
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Emerald green gradient background
let colors = [
    CGColor(red: 0.05, green: 0.37, blue: 0.24, alpha: 1),
    CGColor(red: 0.00, green: 0.10, blue: 0.05, alpha: 1),
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(height)), options: [])

// Subtle grid/dots pattern
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.03))
for x in stride(from: 30, to: width, by: 30) {
    for y in stride(from: 30, to: height, by: 30) {
        ctx.fillEllipse(in: CGRect(x: CGFloat(x), y: CGFloat(y), width: 2, height: 2))
    }
}

let iconY: CGFloat = 160
let iconSize: CGFloat = 80
let iconRadius: CGFloat = 14

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
ctx.setLineWidth(2)
ctx.setLineDash(phase: 0, lengths: [6, 4])

// ─── Icon 1: Resound.app (notch pill) ───
let p1x: CGFloat = 70
let pillPath = CGMutablePath()
pillPath.move(to: CGPoint(x: p1x + 4, y: iconY + iconSize))
pillPath.addLine(to: CGPoint(x: p1x + iconSize - 4, y: iconY + iconSize))
pillPath.addArc(tangent1End: CGPoint(x: p1x + iconSize, y: iconY + iconSize), tangent2End: CGPoint(x: p1x + iconSize, y: iconY), radius: iconRadius)
pillPath.addLine(to: CGPoint(x: p1x + iconSize, y: iconY + iconRadius))
pillPath.addArc(tangent1End: CGPoint(x: p1x + iconSize, y: iconY), tangent2End: CGPoint(x: p1x + iconSize - iconRadius, y: iconY), radius: iconRadius)
pillPath.addLine(to: CGPoint(x: p1x + iconRadius, y: iconY))
pillPath.addArc(tangent1End: CGPoint(x: p1x, y: iconY), tangent2End: CGPoint(x: p1x, y: iconY + iconRadius), radius: iconRadius)
pillPath.addLine(to: CGPoint(x: p1x, y: iconY + iconSize - iconRadius))
pillPath.addArc(tangent1End: CGPoint(x: p1x, y: iconY + iconSize), tangent2End: CGPoint(x: p1x + 4, y: iconY + iconSize), radius: iconRadius)
pillPath.closeSubpath()
ctx.addPath(pillPath)
ctx.strokePath()

// ─── Icon 2: Applications (folder) ───
let p2x: CGFloat = 260
let fw = iconSize * 0.75
let fh = iconSize * 0.9
let fx = p2x + (iconSize - fw) / 2
let fy = iconY + (iconSize - fh) / 2

let folderPath = CGMutablePath()
folderPath.move(to: CGPoint(x: fx, y: fy + fh))
folderPath.addLine(to: CGPoint(x: fx + fw, y: fy + fh))
folderPath.addLine(to: CGPoint(x: fx + fw, y: fy + fh * 0.35))
folderPath.addLine(to: CGPoint(x: fx + fw * 0.55, y: fy + fh * 0.35))
folderPath.addLine(to: CGPoint(x: fx + fw * 0.45, y: fy + fh * 0.2))
folderPath.addLine(to: CGPoint(x: fx + fw * 0.1, y: fy + fh * 0.2))
folderPath.closeSubpath()
ctx.addPath(folderPath)
ctx.strokePath()

// ─── Icon 3: Install Resound (rounded rect with play triangle) ───
let p3x: CGFloat = 450
let installRect = CGRect(x: p3x, y: iconY, width: iconSize, height: iconSize)
let installPath = CGPath(roundedRect: installRect, cornerWidth: iconRadius, cornerHeight: iconRadius, transform: nil)
ctx.addPath(installPath)
ctx.strokePath()

// Play triangle inside icon 3
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
ctx.move(to: CGPoint(x: p3x + 28, y: iconY + 18))
ctx.addLine(to: CGPoint(x: p3x + 28, y: iconY + iconSize - 18))
ctx.addLine(to: CGPoint(x: p3x + iconSize - 22, y: iconY + iconSize / 2))
ctx.closePath()
ctx.fillPath()

// ─── Arrows ───
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.setLineWidth(1.5)
ctx.setLineDash(phase: 0, lengths: [])

func drawArrow(from: CGPoint, to: CGPoint) {
    ctx.move(to: from)
    ctx.addLine(to: to)
    ctx.strokePath()
    let arrowLen: CGFloat = 8
    let angle = atan2(to.y - from.y, to.x - from.x)
    ctx.move(to: to)
    ctx.addLine(to: CGPoint(x: to.x - arrowLen * cos(angle - 0.4), y: to.y - arrowLen * sin(angle - 0.4)))
    ctx.move(to: to)
    ctx.addLine(to: CGPoint(x: to.x - arrowLen * cos(angle + 0.4), y: to.y - arrowLen * sin(angle + 0.4)))
    ctx.strokePath()
}

drawArrow(from: CGPoint(x: p1x + iconSize + 10, y: iconY + iconSize / 2),
          to: CGPoint(x: p2x - 10, y: iconY + iconSize / 2))

drawArrow(from: CGPoint(x: p2x + iconSize + 10, y: iconY + iconSize / 2),
          to: CGPoint(x: p3x - 10, y: iconY + iconSize / 2))

// ─── Step labels above each icon ───
let stepAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 9, weight: .semibold),
    .foregroundColor: NSColor(white: 1, alpha: 0.4)
]
let steps = ["1", "2", "3"]
let stepPositions: [CGFloat] = [p1x + iconSize / 2, p2x + iconSize / 2, p3x + iconSize / 2]
for (i, step) in steps.enumerated() {
    let size = (step as NSString).size(withAttributes: stepAttr)
    (step as NSString).draw(at: CGPoint(x: stepPositions[i] - size.width / 2, y: iconY + iconSize + 12), withAttributes: stepAttr)
}

// Instruction text at top
let instruction = "Drag Resound to Applications → double-click Install Resound"
let instrAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.8)
]
let instrSize = (instruction as NSString).size(withAttributes: instrAttr)
(instruction as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - instrSize.width / 2, y: CGFloat(height) - 50), withAttributes: instrAttr)

// Builder credit at bottom center
let credit = "Built by Evans Elabo"
let creditAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.8)
]
let creditSize = (credit as NSString).size(withAttributes: creditAttr)
(credit as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - creditSize.width / 2, y: 55), withAttributes: creditAttr)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate background")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/dmg-background.png"
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Background saved to \(outputPath)")
