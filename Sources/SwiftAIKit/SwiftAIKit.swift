// SwiftAIKit - AI API Client for iOS
//
// A Swift SDK for integrating AI capabilities into your iOS, macOS, tvOS, and watchOS apps.
//
// Quick Start:
//
//     import SwiftAIKit
//
//     let client = AIClient(apiKey: "sk_live_...")
//
//     // Non-streaming
//     let response = try await client.chatCompletion(
//         messages: [.user("Hello!")]
//     )
//     print(response.content ?? "")
//
//     // Streaming
//     let stream = try await client.chatCompletionStream(
//         messages: [.user("Hello!")]
//     )
//     for try await chunk in stream {
//         print(chunk.content ?? "", terminator: "")
//     }
//
//     // With billing info
//     let response = try await client.chatCompletionWithBilling(
//         messages: [.user("Hello!")]
//     )
//     print("Cost: $\(response.billing?.creditsUsed ?? 0)")
//     print("Remaining: $\(response.billing?.creditsRemaining ?? 0)")
//

// Re-export all public types
@_exported import Foundation

// Version
public let swiftAIKitVersion = "1.0.0"
