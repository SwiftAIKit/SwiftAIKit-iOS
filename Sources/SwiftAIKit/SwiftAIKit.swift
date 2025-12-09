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

// Re-export all public types
@_exported import Foundation

// Version
public let swiftAIKitVersion = "1.0.0"
