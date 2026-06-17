import SwiftUI

/// Camp Codex — lore unlocked by depth, bosses, and choices.
struct CodexView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isLandscapeLayout) private var isLandscape

    private var entries: [CodexEntry] {
        Codex.catalog.sorted {
            let aUnlocked = engine.discoveredCodex.contains($0.id)
            let bUnlocked = engine.discoveredCodex.contains($1.id)
            if aUnlocked != bUnlocked { return aUnlocked && !bUnlocked }
            return ($0.unlockRing ?? 99) < ($1.unlockRing ?? 99)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollFit {
                LazyVStack(spacing: 12) {
                    ForEach(entries) { entry in
                        codexCard(entry)
                    }
                }
                .padding()
            }
            .navigationTitle(Narrative.Codex.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func codexCard(_ entry: CodexEntry) -> some View {
        let unlocked = engine.discoveredCodex.contains(entry.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(unlocked ? Theme.gold : .secondary)
                Spacer()
                if unlocked {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(Theme.mana)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
            if unlocked {
                Text(entry.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(Narrative.Codex.lockedHint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(unlocked
                            ? "\(entry.title). \(entry.body)"
                            : "Locked codex entry. \(Narrative.Codex.lockedHint)")
    }
}
