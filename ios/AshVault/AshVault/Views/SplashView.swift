import SwiftUI

/// Brief in-app splash that mirrors the static launch screen for a seamless handoff.
struct SplashView: View {
    @Environment(\.isLandscapeLayout) private var isLandscape
    @ScaledMetric(relativeTo: .largeTitle) private var portraitLogoSide: CGFloat = 200
    @ScaledMetric(relativeTo: .title) private var landscapeLogoSide: CGFloat = 120

    private var logoSide: CGFloat {
        isLandscape ? landscapeLogoSide : portraitLogoSide
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
