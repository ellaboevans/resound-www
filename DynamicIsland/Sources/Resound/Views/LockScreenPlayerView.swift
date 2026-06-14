import SwiftUI

struct LockScreenPlayerView: View {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let artwork: NSImage?
    let elapsed: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let isEmpty: Bool

    var body: some View {
        VStack(spacing: 14) {
            if isEmpty {
                emptyState
            } else {
                trackRow
                progressBar
                transportControls
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                VisualEffectView(material: .dark, blendingMode: .withinWindow)
                    .opacity(0.3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Text("♪")
                .font(.title2)
                .foregroundColor(.white.opacity(0.3))
            Text("Nothing playing")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 20)
    }

    private var trackRow: some View {
        HStack(spacing: 14) {
            if let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text("♪")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(trackTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(artistName)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                Text(albumTitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                    .lineLimit(1)
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text(formatTime(elapsed))
                .font(.system(size: 10, design: .monospaced).monospacedDigit())
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 32, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            Text(formatTime(duration))
                .font(.system(size: 10, design: .monospaced).monospacedDigit())
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 32)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button(action: {}) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 36, height: 36)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
    }

    private var progress: Double {
        duration > 0 ? min(max(elapsed / duration, 0), 1) : 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
