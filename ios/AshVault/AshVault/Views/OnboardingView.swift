import SwiftUI

/// Simple paged walkthrough explaining AshVault's core loop and actions.
struct OnboardingView: View {
    /// When true, dismiss marks onboarding complete (first-run flow).
    var marksComplete: Bool = true
    var onDismiss: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pages: [Narrative.OnboardingPage] { Narrative.Onboarding.pages }
    private var isLastPage: Bool { page >= pages.count - 1 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                TabView(selection: $page) {
                    ForEach(pages) { onboardingPage($0) }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: page)
                footer
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var headerBar: some View {
        HStack {
            Spacer()
            if !isLastPage {
                Button(Narrative.Onboarding.skip) { finish() }
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .accessibilityHint("Skips the walkthrough")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(minHeight: 44)
    }

    private func onboardingPage(_ item: Narrative.OnboardingPage) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ScaledSymbol(item.symbol, style: .largeTitle)
                    .foregroundStyle(Theme.gold)
                    .padding(.top, 12)

                Text(item.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(item.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(item.bullets, id: \.self) { bullet in
                            OnboardingBulletRow(text: bullet)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .tag(item.id)
    }

    private var footer: some View {
        Button(action: advance) {
            Text(isLastPage ? Narrative.Onboarding.getStarted : Narrative.Onboarding.next)
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.gold)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .accessibilityHint(isLastPage ? "Closes the walkthrough" : "Shows the next page")
    }

    private func advance() {
        if isLastPage {
            finish()
        } else {
            Haptics.play(.light)
            page += 1
        }
    }

    private func finish() {
        if marksComplete {
            OnboardingSettings.markCompleted()
            GameAnalytics.track(.onboardingCompleted)
        }
        Haptics.play(.success)
        onDismiss()
    }
}

private struct OnboardingBulletRow: View {
    let text: String
    @ScaledMetric(relativeTo: .caption) private var bulletSize: CGFloat = 6
    @ScaledMetric(relativeTo: .caption) private var bulletTopInset: CGFloat = 6

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: bulletSize))
                .foregroundStyle(Theme.gold)
                .padding(.top, bulletTopInset)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .lineSpacing(2)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
