import SwiftUI

struct AboutSettingsTab: View {
    var updateManager: SoftwareUpdateManager

    var body: some View {
        VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.xLarge) {
            softwareUpdateSection
        }
    }

    // MARK: - Software Update

    private var softwareUpdateSection: some View {
        SettingsPanelCard {
            SettingsSectionHeader(
                title: "Software Update",
                subtitle: "Keep StoryFox up to date with the latest features and fixes.",
                systemImage: "arrow.triangle.2.circlepath"
            )

            SettingsControlRow(
                title: "Version",
                description: "Currently installed version of StoryFox."
            ) {
                Text(appVersionString)
                    .font(StoryJuicerTypography.settingsBody)
                    .foregroundStyle(Color.sjText)
                    .settingsFieldChrome()
            }

            SettingsControlRow(
                title: "Automatic Updates",
                description: "Periodically check for new versions in the background."
            ) {
                Toggle("Check automatically", isOn: Binding(
                    get: { updateManager.automaticallyChecksForUpdates },
                    set: { updateManager.automaticallyChecksForUpdates = $0 }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(.sjCoral)
            }

            VStack(alignment: .leading, spacing: StoryJuicerGlassTokens.Spacing.small) {
                HStack(spacing: StoryJuicerGlassTokens.Spacing.small) {
                    Button("Check for Updates...") {
                        updateManager.checkForUpdates()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!updateManager.canCheckForUpdates)

                    if let lastCheck = updateManager.lastUpdateCheckDate {
                        Text("Last checked: \(lastCheck.formatted(date: .abbreviated, time: .shortened))")
                            .font(StoryJuicerTypography.settingsMeta)
                            .foregroundStyle(Color.sjSecondaryText)
                    }
                }
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
