//
//  ContentView.swift
//  SwiftAIKitDemo
//
//  Main entry point for the demo app.
//
//  This app demonstrates the key features of SwiftAIKit:
//  - Chat tab: Basic chat completion (chatCompletion)
//  - Streaming tab: Real-time streaming (chatCompletionStream)
//  - Settings tab: API key configuration
//
//  File Structure:
//  - Models.swift      - Data models (DisplayMessage, MessageRole)
//  - Components.swift  - Reusable UI components (MessageBubble, APIKeyPromptView)
//  - ChatView.swift    - Basic chat completion demo
//  - StreamingChatView.swift - Streaming chat demo
//  - SettingsView.swift      - API key and app info settings
//

import SwiftUI

/// Main app view with tab navigation.
struct ContentView: View {
    var body: some View {
        TabView {
            // Basic chat completion demo
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            // Streaming chat demo
            StreamingChatView()
                .tabItem {
                    Label("Streaming", systemImage: "waveform")
                }

            // Settings and configuration
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
