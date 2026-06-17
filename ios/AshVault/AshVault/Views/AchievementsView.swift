import SwiftUI

/// Trophy gallery — goals and stories behind lifetime stats.
struct AchievementsView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 10

    private var catalog: [AchievementDefinition] {
        AchievementEvaluator.shared.catalog
    }

    private var unlockedCount: Int {
        engine.achievementState.unlocked.count
    }

    private var gridColumns: [GridItem] {
        let count = AccessibilityLayout.metaGridColumnCount(
            isLandscape: isLandscape,
            dynamicTypeSize: dynamicTypeSize,
            portraitColumns: 1,
            landscapeColumns: 2
        )
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollFit {
                VStack(spacing: 16) {
                    summaryHeader
                    ForEach(AchievementCategory.displayOrder, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding()
            }
            .navigationTitle(Narrative.Term.shrineRecords)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                engine.markAchievementsViewed()
            }
        }
    }

    private var summaryHeader: some View {
        Panel {
            VStack(spacing: 8) {
                Text("\(unlockedCount)/\(catalog.count) trophies")
                    .font(.headline)
                if let bonus = Narrative.Term.achievementBonusSummary(
                    goldPercent: engine.achievementState.bonusGoldPercent,
                    hpPercent: engine.achievementState.bonusStartingHpPercent
                ) {
                    Text(bonus)
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                }
                Text("The Shrine remembers what you've done in the Vault.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private func categorySection(_ category: AchievementCategory) -> some View {
        let items = catalog.filter { $0.category == category }
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(category.title)
                    .font(.subheadline.bold())
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(items) { def in
                        achievementCard(def)
                    }
                }
            }
        }
    }

    private func achievementCard(_ def: AchievementDefinition) -> some View {
        let unlocked = engine.achievementState.contains(def.achievementID)
        let progress = engine.achievementProgress(for: def.achievementID)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Image(systemName: unlocked ? def.icon : "lock.fill")
                        .font(.title2)
                        .foregroundStyle(unlocked ? Theme.gold : .secondary)
                }
                .accessibilityDecorative()
                Spacer()
                if let badge = def.reward.badgeLabel, unlocked {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(unlocked ? def.name : (def.secret ? "???" : def.name))
                .font(.subheadline.bold())
                .foregroundStyle(unlocked ? .primary : .secondary)

            if unlocked {
                Text(def.lore)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = engine.achievementState.unlockedAt[def.achievementID.rawValue] {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text(def.secret ? "???" : def.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let progress {
                    ProgressView(value: Double(progress.current), total: Double(progress.target))
                        .tint(Theme.gold)
                    Text("\(progress.current) / \(progress.target)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(cardPadding)
        .background(unlocked ? Theme.gold.opacity(0.12) : Theme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(unlocked ? Theme.gold : Theme.panelStroke, lineWidth: unlocked ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(unlocked ? 1 : 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            unlocked
                ? "\(def.name). \(def.lore)"
                : Narrative.Achievement.lockedAccessibilityLabel(
                    name: def.secret ? "Hidden trophy" : def.name,
                    progress: progress
                )
        )
    }
}

/// One-time summary when veterans gain backfilled trophies (no toast spam).
struct AchievementBackfillSummaryView: View {
    let count: Int
    let onDismiss: () -> Void
    @Environment(\.isLandscapeLayout) private var isLandscape

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rosette")
                .font(.system(size: isLandscape ? 40 : 48))
                .foregroundStyle(Theme.gold)
                .accessibilityDecorative()
            Text(Narrative.Term.achievementBackfillTitle)
                .font(isLandscape ? .title2.bold() : .title2.bold())
                .foregroundStyle(Theme.gold)
            Text(Narrative.Term.achievementBackfillBody)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Text("\(count) trophies recorded")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Button(action: onDismiss) {
                Text("View \(Narrative.Term.shrineRecords)")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 12 : 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            Button("Later", action: onDismiss)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .presentationDetents(isLandscape ? [.fraction(0.45)] : [.height(380)])
    }
}

/// Compact in-run unlock banner — tap or auto-dismiss.
struct AchievementUnlockToast: View {
    let achievementID: AchievementID
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var def: AchievementDefinition? {
        AchievementEvaluator.shared.definition(for: achievementID)
    }

    var body: some View {
        if let def {
            Button(action: onDismiss) {
                HStack(spacing: 12) {
                    Image(systemName: def.icon)
                        .font(.title2)
                        .foregroundStyle(Theme.gold)
                        .accessibilityDecorative()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Narrative.Term.achievementUnlockToastTitle)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(def.name)
                            .font(.subheadline.bold())
                        Text(def.lore)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.gold.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Trophy earned: \(def.name). \(def.lore)")
            .onAppear {
                guard !reduceMotion else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onDismiss()
                }
            }
        }
    }
}
