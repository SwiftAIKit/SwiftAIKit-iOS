import Foundation

/// API environment configuration
public enum AIEnvironment: Sendable {
    case production
    case test
    case custom(baseURL: URL)

    /// Base URL for the API environment
    public var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://api.swiftaikit.com")!
        case .test:
            return URL(string: "https://api-test.swiftaikit.com")!
        case .custom(let url):
            return url
        }
    }

    /// Check if environment is production
    public var isProduction: Bool {
        if case .production = self {
            return true
        }
        return false
    }

    /// Check if environment is test
    public var isTest: Bool {
        if case .test = self {
            return true
        }
        return false
    }

    /// Auto-detect environment based on build configuration
    public static var auto: AIEnvironment {
        #if targetEnvironment(simulator)
        // Simulator always uses test environment
        return .test
        #elseif DEBUG
        // Debug builds use test environment
        return .test
        #else
        // Release builds use production environment
        return .production
        #endif
    }
}
