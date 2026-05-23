import SwiftUI

struct AnimatedGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.16), radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 1 : 4)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
