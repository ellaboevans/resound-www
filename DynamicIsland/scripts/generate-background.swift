import Cocoa

let width = 600
let height = 400
let rect = CGRect(x: 0, y: 0, width: width, height: height)

let image = NSImage(size: rect.size)
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext

// Emerald green gradient background
let colors = [
    CGColor(red: 0.05, green: 0.37, blue: 0.24, alpha: 1),  // #0D5E3C emerald top
    CGColor(red: 0.00, green: 0.10, blue: 0.05, alpha: 1),  // #001A0D deep green bottom
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(height)), options: [])

// Subtle grid/dots pattern for texture
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.03))
for x in stride(from: 30, to: width, by: 30) {
    for y in stride(from: 30, to: height, by: 30) {
        ctx.fillEllipse(in: CGRect(x: CGFloat(x), y: CGFloat(y), width: 2, height: 2))
    }
}

// App icon zone — left side (notch pill shape outline)
let pillWidth: CGFloat = 120
let pillHeight: CGFloat = 60
let pillX: CGFloat = 140
let pillY: CGFloat = 150
let pillRadius: CGFloat = 14

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
ctx.setLineWidth(2)
ctx.setLineDash(phase: 0, lengths: [6, 4])

let pillPath = CGMutablePath()
pillPath.move(to: CGPoint(x: pillX + 4, y: pillY + pillHeight))
pillPath.addLine(to: CGPoint(x: pillX + pillWidth - 4, y: pillY + pillHeight))
pillPath.addArc(tangent1End: CGPoint(x: pillX + pillWidth, y: pillY + pillHeight),
                tangent2End: CGPoint(x: pillX + pillWidth, y: pillY),
                radius: pillRadius)
pillPath.addLine(to: CGPoint(x: pillX + pillWidth, y: pillY + pillRadius))
pillPath.addArc(tangent1End: CGPoint(x: pillX + pillWidth, y: pillY),
                tangent2End: CGPoint(x: pillX + pillWidth - pillRadius, y: pillY),
                radius: pillRadius)
pillPath.addLine(to: CGPoint(x: pillX + pillRadius, y: pillY))
pillPath.addArc(tangent1End: CGPoint(x: pillX, y: pillY),
                tangent2End: CGPoint(x: pillX, y: pillY + pillRadius),
                radius: pillRadius)
pillPath.addLine(to: CGPoint(x: pillX, y: pillY + pillHeight - pillRadius))
pillPath.addArc(tangent1End: CGPoint(x: pillX, y: pillY + pillHeight),
                tangent2End: CGPoint(x: pillX + 4, y: pillY + pillHeight),
                radius: pillRadius)
pillPath.closeSubpath()
ctx.addPath(pillPath)
ctx.strokePath()

// Applications icon zone — right side (folder outline)
let folderWidth: CGFloat = 90
let folderHeight: CGFloat = 72
let folderX: CGFloat = 370
let folderY: CGFloat = 144

ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
ctx.setLineWidth(2)
ctx.setLineDash(phase: 0, lengths: [6, 4])

let folderPath = CGMutablePath()
folderPath.move(to: CGPoint(x: folderX, y: folderY + folderHeight))
folderPath.addLine(to: CGPoint(x: folderX + folderWidth, y: folderY + folderHeight))
folderPath.addLine(to: CGPoint(x: folderX + folderWidth, y: folderY + folderHeight * 0.35))
folderPath.addLine(to: CGPoint(x: folderX + folderWidth * 0.55, y: folderY + folderHeight * 0.35))
folderPath.addLine(to: CGPoint(x: folderX + folderWidth * 0.45, y: folderY + folderHeight * 0.2))
folderPath.addLine(to: CGPoint(x: folderX + folderWidth * 0.1, y: folderY + folderHeight * 0.2))
folderPath.closeSubpath()
ctx.addPath(folderPath)
ctx.strokePath()

// Arrow connecting them
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.setLineWidth(1.5)
ctx.setLineDash(phase: 0, lengths: [])

let arrowStart = CGPoint(x: pillX + pillWidth + 20, y: pillY + pillHeight / 2)
let arrowEnd = CGPoint(x: folderX - 20, y: folderY + folderHeight / 2)

ctx.move(to: arrowStart)
ctx.addLine(to: arrowEnd)
ctx.strokePath()

// Arrowhead
let arrowLen: CGFloat = 8
let angle = atan2(arrowEnd.y - arrowStart.y, arrowEnd.x - arrowStart.x)
ctx.move(to: arrowEnd)
ctx.addLine(to: CGPoint(x: arrowEnd.x - arrowLen * cos(angle - 0.4), y: arrowEnd.y - arrowLen * sin(angle - 0.4)))
ctx.move(to: arrowEnd)
ctx.addLine(to: CGPoint(x: arrowEnd.x - arrowLen * cos(angle + 0.4), y: arrowEnd.y - arrowLen * sin(angle + 0.4)))
ctx.strokePath()

// Instruction text at top — pure white
let instruction = "Drag Resound to your Applications folder"
let instrAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.8)
]
let instrSize = (instruction as NSString).size(withAttributes: instrAttr)
(instruction as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - instrSize.width / 2, y: CGFloat(height) - 50), withAttributes: instrAttr)

// Gatekeeper note
let gkNote = "If macOS warns about an unidentified developer, run in Terminal:"
let gkNote2 = "sudo xattr -r -d com.apple.quarantine /Applications/Resound.app"
let gkAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 9, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.35)
]
let gkAttr2: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.5)
]
let gkSize = (gkNote as NSString).size(withAttributes: gkAttr)
(gkNote as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - gkSize.width / 2, y: 105), withAttributes: gkAttr)
let gkSize2 = (gkNote2 as NSString).size(withAttributes: gkAttr2)
(gkNote2 as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - gkSize2.width / 2, y: 88), withAttributes: gkAttr2)

// Builder credit at bottom center
let credit = "Built by Evans Elabo"
let creditAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10, weight: .regular),
    .foregroundColor: NSColor(white: 1, alpha: 0.8)
]
let creditSize = (credit as NSString).size(withAttributes: creditAttr)
(credit as NSString).draw(at: CGPoint(x: CGFloat(width) / 2 - creditSize.width / 2, y: 55), withAttributes: creditAttr)

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate background")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/dmg-background.png"
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Background saved to \(outputPath)")
