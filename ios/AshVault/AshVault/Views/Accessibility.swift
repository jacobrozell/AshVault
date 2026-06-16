import SwiftUI

extension View {
    /// Hide decorative visuals from VoiceOver while keeping them on screen.
    func accessibilityDecorative() -> some View {
        accessibilityHidden(true)
    }
}
