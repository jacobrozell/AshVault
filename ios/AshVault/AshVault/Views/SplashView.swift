import SwiftUI

/// Brief in-app splash that mirrors the static launch screen for a seamless handoff.
struct SplashView: View {
    @Environment(\.isLandscapeLayout) private var isLandscape

    private var logoSide: CGFloat {
        isLandscape ? 120 : 200
    }

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSide, height: logoSide)
                .accessibilityDecorative()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Narrative.appName)
    }
}
