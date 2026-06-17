import SwiftUI

/// "While you were away…" summary shown on resume when offline progress accrued.
struct OfflineReportView: View {
    let report: OfflineReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var sideBySide: Bool {
        AccessibilityLayout.usesSideBySideLayout(isLandscape: isLandscape, dynamicTypeSize: dynamicTypeSize)
    }

    private var scrollsPortrait: Bool {
        !isLandscape && dynamicTypeSize.ashvaultUsesAccessibilityLayout
    }

    var body: some View {
        Group {
            if sideBySide {
                HStack(spacing: 20) {
                    summarySection
                    collectSection
                }
                .padding(.horizontal, 24)
            } else if scrollsPortrait {
                ScrollView {
                    VStack(spacing: 20) {
                        summarySection
                        collectSection
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    summarySection
                    collectSection
                    Spacer()
                }
                .padding()
            }
        }
        .presentationDetents(isLandscape ? [.fraction(0.6)] : [.medium, .large])
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            ScaledEmoji("💤", style: isLandscape ? .title : .largeTitle)
            Text("While you were away")
                .font(isLandscape ? .title2.bold() : .title.bold())
                .foregroundStyle(Theme.gold)
            Text(modeText)
                .font(.gameSubtitle(compactHeight: isLandscape))
                .multilineTextAlignment(.center)
                .foregroundStyleBodySecondary()
                .fixedSize(horizontal: false, vertical: true)
            if report.hitCap {
                Text("Offline cap reached (\(formatDuration(report.creditedDuration)) credited) — \(Narrative.Term.offlineAshTreeHint)")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var collectSection: some View {
        VStack(spacing: 12) {
            Panel {
                VStack(spacing: 8) {
                    HStack {
                        Text("🪙").font(.title2).accessibilityDecorative()
                        Text("+\(Formatting.short(report.gold)) gold")
                            .font(isLandscape ? .headline.bold() : .title3.bold())
                            .foregroundStyle(Theme.gold)
                    }
                    detailRow("~\(report.estimatedKills) kills", systemImage: "skull")
                    if report.mercenaryGold > 0 {
                        detailRow("Mercenaries: +\(Formatting.short(report.mercenaryGold))g",
                                  systemImage: "person.3.fill")
                    }
                    detailRow(durationDetailText, systemImage: "clock")
                }
            }

            Button { dismiss() } label: {
                Text("Collect")
                    .font(isLandscape ? .headline.bold() : .title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isLandscape ? 10 : 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Dismisses the offline earnings report")
        }
        .frame(maxWidth: .infinity)
    }

    private func detailRow(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyleBodySecondary()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeText: String {
        let credited = formatDuration(report.creditedDuration)
        if report.wasAutoBattle {
            return "Auto-battle kept diving for \(credited)."
        }
        return "Your crawl idled at reduced rate for \(credited)."
    }

    private var durationDetailText: String {
        let credited = formatDuration(report.creditedDuration)
        guard report.hitCap else { return "Away \(credited)" }
        let away = formatDuration(report.duration)
        return "\(credited) credited · \(away) away"
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval / 60)
        if mins < 60 { return "\(max(1, mins)) min" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
