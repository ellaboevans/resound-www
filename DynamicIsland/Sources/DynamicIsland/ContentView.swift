import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false

    var body: some View {
        Text(isExpanded ? "Expanded" : "Collapsed")
            .foregroundColor(.white)
            .padding()
            .onTapGesture {
                isExpanded.toggle()
            }
    }
}
