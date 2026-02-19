import Foundation

enum ModelSelectionStore {
    private static let keyV3 = "storyjuicer.modelSelectionSettings.v3"
    private static let legacyKeyV2 = "storyjuicer.modelSelectionSettings.v2"
    private static let legacyKeyV1 = "storyjuicer.modelSelectionSettings.v1"

    static func load(defaults: UserDefaults = .standard) -> ModelSelectionSettings {
        // Try v3 first
        if let data = defaults.data(forKey: keyV3),
           let settings = try? JSONDecoder().decode(ModelSelectionSettings.self, from: data) {
            return normalized(settings)
        }

        // Migrate from v2
        if let data = defaults.data(forKey: legacyKeyV2),
           let settings = try? JSONDecoder().decode(ModelSelectionSettings.self, from: data) {
            let migrated = normalized(settings)
            save(migrated, defaults: defaults)
            defaults.removeObject(forKey: legacyKeyV2)
            return migrated
        }

        // Migrate from v1
        if let migrated = loadLegacyV1(defaults: defaults) {
            save(migrated, defaults: defaults)
            defaults.removeObject(forKey: legacyKeyV1)
            return migrated
        }

        return .default
    }

    static func save(
        _ settings: ModelSelectionSettings,
        defaults: UserDefaults = .standard
    ) {
        guard let data = try? JSONEncoder().encode(normalized(settings)) else { return }
        defaults.set(data, forKey: keyV3)
    }

    private static func normalized(_ settings: ModelSelectionSettings) -> ModelSelectionSettings {
        var updated = settings
        // Only block .diffusers for image provider — allow cloud providers through.
        if updated.imageProvider == .diffusers {
            updated.imageProvider = .imagePlayground
        }
        if updated.mlxModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.mlxModelID = ModelSelectionSettings.defaultMLXModelID
        }
        if updated.diffusersModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.diffusersModelID = ModelSelectionSettings.defaultDiffusersModelID
        }
        if updated.diffusersRuntimeAlias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.diffusersRuntimeAlias = DiffusersRuntimeManager.defaultAlias
        }
        return updated
    }

    private static func loadLegacyV1(defaults: UserDefaults) -> ModelSelectionSettings? {
        guard let data = defaults.data(forKey: legacyKeyV1),
              let legacy = try? JSONDecoder().decode(LegacyV1Settings.self, from: data) else {
            return nil
        }

        let imageProvider: StoryImageProvider
        switch legacy.imageProvider {
        case .imagePlayground:
            imageProvider = .imagePlayground
        case .mflux:
            imageProvider = .imagePlayground
        }

        let textProvider: StoryTextProvider
        switch legacy.textProvider {
        case .appleFoundation:
            textProvider = .appleFoundation
        case .mlxSwift:
            textProvider = .mlxSwift
        }

        return ModelSelectionSettings(
            textProvider: textProvider,
            imageProvider: imageProvider,
            mlxModelID: legacy.mlxModelID,
            diffusersModelID: ModelSelectionSettings.defaultDiffusersModelID,
            hfTokenKeychainRef: legacy.hfTokenKeychainRef,
            diffusersRuntimeAlias: DiffusersRuntimeManager.defaultAlias,
            enableFoundationFallback: legacy.enableFoundationFallback,
            enableImageFallback: true
        )
    }
}

private struct LegacyV1Settings: Codable {
    var textProvider: LegacyStoryTextProvider
    var imageProvider: LegacyStoryImageProvider
    var mlxModelID: String
    var hfTokenKeychainRef: String?
    var enableFoundationFallback: Bool
}

private enum LegacyStoryTextProvider: String, Codable {
    case appleFoundation
    case mlxSwift
}

private enum LegacyStoryImageProvider: String, Codable {
    case imagePlayground
    case mflux
}
