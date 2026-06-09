import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        PillView(trackTitle: "Blinding Lights", artistName: "The Weeknd", isPlaying: true)
            .contentShape(Capsule())
            .onTapGesture {
                isExpanded.toggle()
                onToggle(isExpanded)
            }
    }
}
