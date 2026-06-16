import SwiftUI

/// Audio settings sheet. Toggles persist via `@AppStorage` (same keys the
/// `SoundManager` reads). Defaults: both on.
struct SettingsView: View {
    private static let buyMeACoffeeURL = URL(string: "https://buymeacoffee.com/jacobrozelq")!
    private static let privacyPolicyURL = URL(string: "https://jacobrozell.github.io/AshVault/privacy-policy.html")!
    private static let accessibilityURL = URL(string: "https://jacobrozell.github.io/AshVault/accessibility.html")!

    @AppStorage("audio.sfxEnabled") private var sfxEnabled = true
    @AppStorage("audio.musicEnabled") private var musicEnabled = true
    @AppStorage("haptics.enabled") private var hapticsEnabled = true
    @AppStorage("autoDescend.enabled") private var autoDescendEnabled = false
    @AppStorage("autoDescend.minShards") private var autoDescendMinShards = Balance.autoDescendDefaultMinShards
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var confirmAbandon = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                if engine.canAbandonRun {
                    Section {
                        Button("Abandon Run", role: .destructive) {
                            confirmAbandon = true
                        }
                        .accessibilityHint(Narrative.Term.abandonRunAccessibilityHint)
                    } footer: {
                        Text(Narrative.Term.abandonRunFooter)
                    }
                }
                Section("Audio & feedback") {
                    Toggle("Sound effects", isOn: $sfxEnabled)
                        .accessibilityHint("Plays or mutes combat and UI sounds")
                    Toggle("Music", isOn: $musicEnabled)
                        .accessibilityHint("Plays or mutes background music")
                        .onChange(of: musicEnabled) { _ in
                            SoundManager.shared.musicSettingChanged()
                        }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .accessibilityHint("Plays or mutes vibration feedback on hits and actions")
                }
                Section {
                    Toggle(Narrative.Term.autoWithdraw, isOn: $autoDescendEnabled)
                        .disabled(!engine.automationUnlocked)
                    if autoDescendEnabled && engine.automationUnlocked {
                        Stepper(value: $autoDescendMinShards, in: 1...100) {
                            Text(Narrative.Term.autoWithdrawThreshold(autoDescendMinShards))
                        }
                    }
                } header: {
                    Text("Automation")
                } footer: {
                    if engine.automationUnlocked {
                        Text(Narrative.Term.autoWithdrawActiveFooter(pending: engine.pendingShards))
                    } else {
                        Text(Narrative.Term.automationHint)
                    }
                }
                Section("About") {
                    Button(Narrative.Onboarding.howToPlay) { showOnboarding = true }
                        .accessibilityHint("Opens the game walkthrough")
                    Link(destination: Self.buyMeACoffeeURL) {
                        Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                    }
                    .accessibilityHint("Opens Buy Me a Coffee in Safari")
                    Link(destination: Self.privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .accessibilityHint("Opens the privacy policy in Safari")
                    Link(destination: Self.accessibilityURL) {
                        Label("Accessibility", systemImage: "figure.wave.circle.fill")
                    }
                    .accessibilityHint("Opens accessibility information in Safari")
                    LabeledContent("Game", value: Narrative.appName)
                    Text("A SwiftUI remake of a one-night Java console game. "
                         + "Audio respects the silent switch and won't interrupt "
                         + "your own music.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityHint("Closes settings")
                }
            }
            .confirmationDialog("Abandon this run?",
                                isPresented: $confirmAbandon,
                                titleVisibility: .visible) {
                Button("Abandon Run", role: .destructive) {
                    engine.abandonRun()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(Narrative.Term.abandonRunMessage)
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(marksComplete: false) { showOnboarding = false }
            }
        }
    }
}
