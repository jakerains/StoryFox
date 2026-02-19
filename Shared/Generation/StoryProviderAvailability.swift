import Foundation

enum StoryProviderAvailability: Sendable, Equatable {
    case available
    case unavailable(reason: String)
}
