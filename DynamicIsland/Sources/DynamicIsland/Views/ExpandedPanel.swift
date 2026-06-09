import SwiftUI

struct ExpandedPanel<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var showContent = false

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 6)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2).delay(0.15)) {
                    showContent = true
                }
            }
            .onDisappear { showContent = false }
    }
}
