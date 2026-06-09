import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        Text(isExpanded ? "Expanded" : "Collapsed")
            .foregroundColor(.white)
            .padding()
            .onTapGesture {
                isExpanded.toggle()
                onToggle(isExpanded)
            }
    }
}
