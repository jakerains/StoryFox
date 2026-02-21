import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case onDevice
    case cloud
    case about

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: "General"
        case .onDevice: "On-Device"
        case .cloud: "Cloud"
        case .about: "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "sparkles.rectangle.stack"
        case .onDevice: "desktopcomputer"
        case .cloud: "cloud"
        case .about: "info.circle"
        }
    }
}
