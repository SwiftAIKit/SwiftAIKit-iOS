//
//  Models.swift
//  SwiftAIKitDemo
//
//  Data model definitions for the demo app.
//

import Foundation

// MARK: - Message Model

/// A message model for UI display purposes.
///
/// This model differs from SwiftAIKit's `ChatMessage`:
/// - `ChatMessage` is the SDK's API model for network requests
/// - `DisplayMessage` is a UI model with `id` for SwiftUI's `ForEach`
///
/// Example usage:
/// ```swift
/// let message = DisplayMessage(role: .user, content: "Hello!")
/// ```
struct DisplayMessage: Identifiable, Equatable {
    /// Unique identifier for SwiftUI list rendering.
    let id = UUID()

    /// Message role (user/assistant/system).
    let role: MessageRole

    /// Message content text.
    let content: String
}

// MARK: - Message Role

/// Enumeration of message roles in a conversation.
enum MessageRole {
    /// Message sent by the user.
    case user

    /// Response from AI assistant.
    case assistant

    /// System prompt (for setting AI behavior).
    case system

    /// Human-readable display name for UI.
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        }
    }
}
