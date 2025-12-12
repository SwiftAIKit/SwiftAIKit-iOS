import Foundation

/// Billing information from API response headers
public struct BillingInfo: Sendable {
    /// Credits used for this request (in cents)
    public let creditsUsedCents: Int

    /// Remaining credits (in cents)
    public let creditsRemainingCents: Int

    /// Whether this request exceeded the monthly quota
    public let isOverage: Bool

    /// Credits used formatted as dollars
    public var creditsUsed: Double {
        Double(creditsUsedCents) / 100.0
    }

    /// Credits remaining formatted as dollars
    public var creditsRemaining: Double {
        Double(creditsRemainingCents) / 100.0
    }

    /// Initialize from response headers
    /// - Parameter headers: HTTP response headers
    /// - Returns: BillingInfo if all required headers are present, nil otherwise
    public static func from(headers: [AnyHashable: Any]) -> BillingInfo? {
        guard let usedString = headers["X-Credits-Used"] as? String ?? headers["x-credits-used"] as? String,
              let remainingString = headers["X-Credits-Remaining"] as? String ?? headers["x-credits-remaining"] as? String,
              let overageString = headers["X-Credits-Overage"] as? String ?? headers["x-credits-overage"] as? String,
              let used = Int(usedString),
              let remaining = Int(remainingString)
        else {
            return nil
        }

        let isOverage = overageString == "1" || overageString.lowercased() == "true"

        return BillingInfo(
            creditsUsedCents: used,
            creditsRemainingCents: remaining,
            isOverage: isOverage
        )
    }
}
