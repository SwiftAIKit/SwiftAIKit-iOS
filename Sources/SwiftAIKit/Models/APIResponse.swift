import Foundation

/// A wrapper that includes API response data along with billing information
public struct APIResponse<T: Sendable>: Sendable {
    /// The actual response data
    public let data: T

    /// Billing information from response headers (if available)
    public let billing: BillingInfo?

    public init(data: T, billing: BillingInfo? = nil) {
        self.data = data
        self.billing = billing
    }
}

/// Type alias for chat completion with billing info
public typealias ChatCompletionResponse = APIResponse<ChatCompletion>
