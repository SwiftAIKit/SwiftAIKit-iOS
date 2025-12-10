//
//  Components.swift
//  SwiftAIKitDemo
//
//  Reusable UI components for the demo app.
//

import SwiftUI

// MARK: - API Key Prompt View

/// Empty state view shown when no API key is configured.
///
/// Displays a helpful message directing users to the Settings tab.
struct APIKeyPromptView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No API Key", systemImage: "key")
        } description: {
            Text("Please add your API key in Settings to start chatting.")
        } actions: {
            Text("Go to Settings tab →")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Message Bubble

/// Chat bubble component for displaying messages.
///
/// Features:
/// - Different alignment for user vs assistant messages
/// - Color-coded backgrounds (accent for user, gray for assistant)
/// - Role label above the bubble
///
/// Usage:
/// ```swift
/// let message = DisplayMessage(role: .user, content: "Hello!")
/// MessageBubble(message: message)
/// ```
struct MessageBubble: View {
    /// The message to display.
    let message: DisplayMessage

    var body: some View {
        HStack {
            // User messages align to the right
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role label (e.g., "You", "Assistant")
                Text(message.role.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Message content bubble
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .foregroundStyle(bubbleForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Assistant messages align to the left
            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    /// Background color based on message role.
    private var bubbleBackground: Color {
        message.role == .user ? Color.accentColor : Color(.systemGray5)
    }

    /// Text color based on message role.
    private var bubbleForeground: Color {
        message.role == .user ? .white : .primary
    }
}

// MARK: - Previews

#Preview("API Key Prompt") {
    APIKeyPromptView()
}

#Preview("Message Bubbles") {
    VStack(spacing: 12) {
        MessageBubble(message: DisplayMessage(role: .user, content: "Hello!"))
        MessageBubble(message: DisplayMessage(role: .assistant, content: "Hi there! How can I help you today?"))
        MessageBubble(message: DisplayMessage(role: .user, content: "What's the weather like?"))
        MessageBubble(message: DisplayMessage(role: .assistant, content: "I don't have access to real-time weather data, but I'd be happy to help you with other questions!"))
    }
    .padding()
}
