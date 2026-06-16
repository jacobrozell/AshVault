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
                Image(systemName: item.symbol)
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.gold)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 12)
                    .accessibilityHidden(true)

                Text(item.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(item.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(item.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Theme.gold)
                                    .padding(.top, 6)
                                    .accessibilityHidden(true)
                                Text(bullet)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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
        if marksComplete { OnboardingSettings.markCompleted() }
        Haptics.play(.success)
        onDismiss()
    }
}
