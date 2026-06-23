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
        case .combat, .draft, .ringChoice, .ringIngress, .sealedRoom, .levelUp, .shop, .ascension: return true
        case .title, .oathSelect, .defeat, .victory: return false
        }
    }

    var body: some View {
        ZStack {
            Theme.background
            switch engine.phase {
            case .title:
                TitleView()
            case .oathSelect:
                OathSelectView()
            case .combat:
                CombatView()
            case .draft:
                DraftView()
            case .ringChoice:
                RingChoiceView()
            case .ringIngress:
                RingIngressView()
            case .sealedRoom:
                SealedRoomView()
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
                RunTopBar(onSettings: { showSettings = true })
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let id = engine.pendingAchievementUnlock {
                AchievementUnlockToast(achievementID: id) {
                    engine.dismissAchievementUnlockToast()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
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
        .sheet(item: achievementBackfillBinding) { wrapper in
            AchievementBackfillSummaryView(count: wrapper.count) {
                engine.dismissAchievementBackfillSummary()
            }
        }

        .animation(.easeInOut(duration: 0.25), value: engine.pendingAchievementUnlock)
    }

    private var achievementBackfillBinding: Binding<BackfillCountWrapper?> {
        Binding(
            get: {
                guard engine.offlineReport == nil else { return nil }
                return engine.achievementBackfillCount.map { BackfillCountWrapper(count: $0) }
            },
            set: { _ in engine.dismissAchievementBackfillSummary() }
        )
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
        case .oathSelect:              return .title
        case .combat, .draft, .ringChoice, .ringIngress, .sealedRoom, .levelUp, .shop, .ascension: return .combat
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
    @State private var showCodex = false
    @State private var showSigils = false
    @State private var showOnboarding = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollFit(showsIndicators: false) {
            Group {
                if AccessibilityLayout.usesSideBySideLayout(
                    isLandscape: isLandscape,
                    dynamicTypeSize: dynamicTypeSize
                ) {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(spacing: 16) {
                            heroSection
                            campHubSection
                        }
                        .frame(maxWidth: 300)
                        formSection
                            .frame(maxWidth: 300)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .padding(.bottom, 12)
                } else {
                    VStack(spacing: 20) {
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 8)
                        }
                        heroSection
                        campHubSection
                        formSection
                        if !dynamicTypeSize.ashvaultUsesAccessibilityLayout {
                            Spacer(minLength: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TitleTopBar(onSettings: { showSettings = true })
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
        VStack(spacing: isLandscape ? 10 : 14) {
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
                .foregroundStyle(.primary.opacity(0.78))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if engine.best.hasRecord || engine.totalShards > 0 {
                statsStrip
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsStrip: some View {
        HStack(spacing: 8) {
            if engine.best.hasRecord {
                Label {
                    Text("Ring \(engine.best.layer) · Lv \(engine.best.level)")
                        .font(.caption.weight(.semibold))
                } icon: {
                    Image(systemName: "trophy.fill")
                }
                .foregroundStyle(Theme.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.gold.opacity(0.12), in: Capsule())
            }
            if engine.totalShards > 0 {
                Label {
                    Text("\(engine.availableShards) shards")
                        .font(.caption.weight(.semibold))
                } icon: {
                    Image(systemName: "sparkles")
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var campHubSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: Narrative.Term.shrine, systemImage: "tent.fill")

            let columns = AccessibilityLayout.metaGridColumnCount(
                isLandscape: isLandscape,
                dynamicTypeSize: dynamicTypeSize,
                portraitColumns: 2,
                landscapeColumns: 1
            )
            let spansFullWidth = columns == 2 && !dynamicTypeSize.ashvaultUsesAccessibilityLayout
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns),
                spacing: 10
            ) {
                if engine.totalShards > 0 {
                    Button { showTree = true } label: {
                        CampHubTile(
                            title: Narrative.Term.ashTree,
                            subtitle: "\(engine.availableShards) \(Narrative.Term.ashShards)",
                            systemImage: "tree.fill",
                            tint: .purple
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .sheet(isPresented: $showTree) { SkillTreeView() }
                } else {
                    CampHubTile(
                        title: Narrative.Term.ashTree,
                        subtitle: "Unlock on first withdrawal",
                        systemImage: "tree.fill",
                        tint: .purple,
                        locked: true
                    )
                    .accessibilityLabel("\(Narrative.Term.ashTree), locked until first withdrawal")
                }
                Button { showMuseum = true } label: {
                    let found = engine.discoveredRelics.count
                    CampHubTile(
                        title: Narrative.Term.ashGallery,
                        subtitle: found > 0
                            ? "\(found)/\(Relic.allCases.count) relics"
                            : nil,
                        systemImage: "archivebox.fill",
                        tint: .secondary
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .sheet(isPresented: $showMuseum) { RelicMuseumView() }

                Button { showAchievements = true } label: {
                    let unlocked = engine.achievementState.unlocked.count
                    let total = AchievementEvaluator.shared.catalog.count
                    CampHubTile(
                        title: Narrative.Term.shrineRecords,
                        subtitle: "\(unlocked)/\(total) trophies",
                        systemImage: "rosette",
                        tint: engine.achievementState.hasUnread ? Theme.gold : .secondary,
                        showsBadge: engine.achievementState.hasUnread
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint(engine.achievementState.hasUnread
                                   ? "New trophies recorded since your last visit"
                                   : "View Camp Records trophies")
                .sheet(isPresented: $showAchievements) {
                    AchievementsView()
                }

                Button { showCodex = true } label: {
                    let unlocked = engine.discoveredCodex.count
                    let total = Codex.catalog.count
                    CampHubTile(
                        title: "Codex",
                        subtitle: "\(unlocked)/\(total) entries",
                        systemImage: "book.closed.fill",
                        tint: unlocked > 0 ? Theme.mana : .secondary
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .sheet(isPresented: $showCodex) {
                    CodexView()
                }

                Button { showSigils = true } label: {
                    CampHubTile(
                        title: Narrative.Term.sigilBench,
                        systemImage: "wand.and.stars",
                        tint: Theme.mana
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .gridCellColumns(spansFullWidth ? 2 : 1)
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
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "New Descent", systemImage: "figure.walk",
                          subtitle: "Name your delver and begin below the seal.")
            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    AccessibleNameField(placeholder: "Delver",
                                            label: "Delver name",
                                            text: $name,
                                            isFocused: $focused)
                            .onSubmit(start)
                }
            }

            Button(action: start) {
                Text(Narrative.Term.beginCrawl)
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 12 : 16)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Starts a new dungeon run")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isLandscape ? 0 : 4)
    }

    private func start() {
        engine.startGame(named: name.trimmingCharacters(in: .whitespaces))
    }
}
