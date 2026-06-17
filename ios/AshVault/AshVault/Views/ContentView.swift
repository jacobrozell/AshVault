import SwiftUI

/// Routes between the game's phases.
struct ContentView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var vSizeClass
    @State private var showSplash = true
    @State private var showSettings = false
    @State private var isLandscapeLayout = false

    private var showsRunSettings: Bool {
        switch engine.phase {
        case .combat, .draft, .ringChoice, .ringIngress, .levelUp, .shop, .ascension: return true
        case .title, .defeat, .victory: return false
        }
    }

    var body: some View {
        ZStack {
            Theme.background
            switch engine.phase {
            case .title:
                TitleView()
            case .combat:
                CombatView()
            case .draft:
                DraftView()
            case .ringChoice:
                RingChoiceView()
            case .ringIngress:
                RingIngressView()
            case .levelUp:
                LevelUpView()
            case .shop:
                ShopView()
            case .ascension:
                AscensionView()
            case .victory:
                GameOverView(won: true)
            case .defeat:
                GameOverView(won: false)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .preference(key: WideLayoutKey.self,
                                value: AdaptiveLayout.prefersWideLayout(vertical: vSizeClass,
                                                                        size: geo.size))
            }
        }
        .onPreferenceChange(WideLayoutKey.self) { isLandscapeLayout = $0 }
        .environment(\.isLandscapeLayout, isLandscapeLayout)
        .safeAreaInset(edge: .top, spacing: 0) {
            if showsRunSettings {
                HStack {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens settings and abandon run")
                    Spacer()
                }
                .padding(.horizontal, 6)
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .animation(.easeInOut(duration: 0.25), value: engine.phase)
        .onAppear {
            dismissSplashIfNeeded()
            SoundManager.shared.playMusic(Self.track(for: engine.phase))
        }
        .onChange(of: engine.phase) { newPhase in
            SoundManager.shared.playMusic(Self.track(for: newPhase))
        }
        .onChange(of: scenePhase) { newScene in
            if newScene == .active { engine.foregrounded() }
            else { engine.backgrounded() }
        }
        .sheet(item: Binding(get: { engine.offlineReport },
                             set: { engine.offlineReport = $0 })) { report in
            OfflineReportView(report: report)
        }
        .sheet(item: Binding(
            get: { engine.achievementBackfillCount.map { BackfillCountWrapper(count: $0) } },
            set: { _ in engine.dismissAchievementBackfillSummary() }
        )) { wrapper in
            AchievementBackfillSummaryView(count: wrapper.count) {
                engine.dismissAchievementBackfillSummary()
            }
        }
        .overlay(alignment: .bottom) {
            if let id = engine.pendingAchievementUnlock {
                AchievementUnlockToast(achievementID: id) {
                    engine.dismissAchievementUnlockToast()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: engine.pendingAchievementUnlock)
    }

    private func dismissSplashIfNeeded() {
        guard showSplash else { return }
        let dismiss = {
            if reduceMotion {
                showSplash = false
            } else {
                withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: dismiss)
    }

    /// Map a game phase to its background track.
    private static func track(for phase: Phase) -> MusicTrack {
        switch phase {
        case .title:                   return .title
        case .combat, .draft, .ringChoice, .ringIngress, .levelUp, .shop, .ascension: return .combat
        case .victory:                 return .victory
        case .defeat:                  return .gameover
        }
    }
}

private struct BackfillCountWrapper: Identifiable {
    let count: Int
    var id: Int { count }
}

private struct WideLayoutKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct TitleView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var name = ""
    @State private var pulse = false
    @State private var showSettings = false
    @State private var showTree = false
    @State private var showMuseum = false
    @State private var showAchievements = false
    @State private var showSigils = false
    @State private var showOnboarding = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollFit(showsIndicators: isLandscape) {
            Group {
                if AccessibilityLayout.usesSideBySideLayout(
                    isLandscape: isLandscape,
                    dynamicTypeSize: dynamicTypeSize
                ) {
                    HStack(alignment: .center, spacing: 20) {
                        heroSection
                            .frame(maxWidth: 280)
                        formSection
                            .frame(maxWidth: 320)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .padding(.bottom, 12)
                } else {
                    VStack(spacing: 24) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                        heroSection
                        formSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 12)
                        }
                    }
                    .padding()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .foregroundStyle(.secondary)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens audio settings")
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { showOnboarding = false }
        }
        .onAppear {
            if !reduceMotion { pulse = true }
            if !OnboardingSettings.hasCompleted { showOnboarding = true }
        }
    }

    private var heroSection: some View {
        VStack(spacing: isLandscape ? 8 : 24) {
            if !isLandscape { Spacer(minLength: 12) }
            ScaledEmoji("🗡️", style: isLandscape ? .title2 : .largeTitle)
                .scaleEffect(reduceMotion ? 1 : (pulse ? 1.08 : 0.96))
                .rotationEffect(.degrees(reduceMotion ? 0 : (pulse ? 4 : -4)))
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                           value: pulse)
            Text("ASH\nVAULT")
                .font(.gameDisplay(compactHeight: isLandscape))
                .adaptiveMinimumScaleFactor(0.7, dynamicTypeSize: dynamicTypeSize)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.gold)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                .fixedSize(horizontal: false, vertical: true)
            Text(Narrative.Term.titleSubtitle)
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if engine.best.hasRecord {
                Label("Best: Layer \(engine.best.layer) · Lv \(engine.best.level) · \(Formatting.short(engine.best.gold))g",
                      systemImage: "trophy.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.gold)
                    .multilineTextAlignment(.center)
            }
            if engine.totalShards > 0 {
                Button { showTree = true } label: {
                    Label(Narrative.Term.ashShardsAndTree(available: engine.availableShards),
                          systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                }
                .sheet(isPresented: $showTree) { SkillTreeView() }
            }
            Button { showMuseum = true } label: {
                let found = engine.discoveredRelics.count
                Label(found > 0
                      ? Narrative.Term.ashGalleryProgress(found: found, total: Relic.allCases.count)
                      : Narrative.Term.ashGallery,
                      systemImage: "archivebox.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .sheet(isPresented: $showMuseum) { RelicMuseumView() }
            Button { showAchievements = true } label: {
                let unlocked = engine.achievementState.unlocked.count
                let total = AchievementEvaluator.shared.catalog.count
                Label(Narrative.Term.shrineRecordsProgress(unlocked: unlocked, total: total),
                      systemImage: "rosette")
                    .font(.caption.bold())
                    .foregroundStyle(engine.achievementState.hasUnread ? Theme.gold : .secondary)
                    .overlay(alignment: .topTrailing) {
                        if engine.achievementState.hasUnread {
                            Circle()
                                .fill(Theme.gold)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                                .accessibilityHidden(true)
                        }
                    }
            }
            .accessibilityHint(engine.achievementState.hasUnread
                               ? "New trophies recorded since your last visit"
                               : "View Shrine Records trophies")
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            Button { showSigils = true } label: {
                Label(Narrative.Term.sigilBench, systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.mana)
            }
            .sheet(isPresented: $showSigils) {
                NavigationStack {
                    ScrollFit {
                        SigilLoadoutView()
                            .padding()
                    }
                    .navigationTitle(Narrative.Term.sigilBench)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSigils = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            if !isLandscape { Spacer(minLength: 12) }
        }
        .frame(maxWidth: .infinity)
    }

    private var formSection: some View {
        VStack(spacing: 12) {
            Panel {
                VStack(spacing: 12) {
                    Text("What is your name, crawler?")
                        .font(.headline)
                    AccessibleNameField(placeholder: "Crawler",
                                            label: "Crawler name",
                                            text: $name,
                                            isFocused: $focused)
                            .onSubmit(start)
                }
            }

            Button(action: start) {
                Text(Narrative.Term.beginCrawl)
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 12 : 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Starts a new dungeon run")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isLandscape ? 0 : 30)
    }

    private func start() {
        engine.startGame(named: name.trimmingCharacters(in: .whitespaces))
    }
}
