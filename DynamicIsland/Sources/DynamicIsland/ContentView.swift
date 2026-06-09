import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        PillView(trackTitle: "Blinding Lights", isPlaying: true)
            .onTapGesture {
                isExpanded.toggle()
                onToggle(isExpanded)
            }
    }
}
