//
//  ContentView.swift
//  SwiftAIKitDemo
//
//  Created by cyonsun on 9/12/25.
//

import SwiftUI
import SwiftAIKit

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            StreamingChatView()
                .tabItem {
                    Label("Streaming", systemImage: "waveform")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Chat View

struct ChatView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @State private var messages: [DisplayMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var client: AIClient? {
        guard !apiKey.isEmpty else { return nil }
        return AIClient(apiKey: apiKey)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if apiKey.isEmpty {
                    APIKeyPromptView()
                } else {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                }

                                if isLoading {
                                    HStack {
                                        ProgressView()
                                            .padding(.horizontal)
                                        Spacer()
                                    }
                                    .id("loading")
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            withAnimation {
                                proxy.scrollTo(messages.last?.id.uuidString ?? "loading", anchor: .bottom)
                            }
                        }
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Input area
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...5)
                            .disabled(isLoading)

                        Button {
                            Task { await sendMessage() }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        messages.removeAll()
                        errorMessage = nil
                    }
                    .disabled(messages.isEmpty)
                }
            }
        }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let client else { return }

        // Add user message
        let userMessage = DisplayMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil
        isLoading = true

        defer { isLoading = false }

        do {
            // Build conversation history
            let chatMessages = messages.map { msg in
                switch msg.role {
                case .user: return ChatMessage.user(msg.content)
                case .assistant: return ChatMessage.assistant(msg.content)
                case .system: return ChatMessage.system(msg.content)
                }
            }

            let response = try await client.chatCompletion(messages: chatMessages)

            if let content = response.content {
                let assistantMessage = DisplayMessage(role: .assistant, content: content)
                messages.append(assistantMessage)
            }
        } catch let error as AIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Streaming Chat View

struct StreamingChatView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @State private var messages: [DisplayMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var currentStreamingContent = ""
    @State private var errorMessage: String?
    @State private var streamTask: Task<Void, Never>?

    private var client: AIClient? {
        guard !apiKey.isEmpty else { return nil }
        return AIClient(apiKey: apiKey)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if apiKey.isEmpty {
                    APIKeyPromptView()
                } else {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                }

                                // Streaming message
                                if isStreaming && !currentStreamingContent.isEmpty {
                                    MessageBubble(message: DisplayMessage(
                                        role: .assistant,
                                        content: currentStreamingContent + "▊"
                                    ))
                                    .id("streaming")
                                }
                            }
                            .padding()
                        }
                        .onChange(of: currentStreamingContent) {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Input area
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...5)
                            .disabled(isStreaming)

                        if isStreaming {
                            Button {
                                stopStreaming()
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Button {
                                Task { await sendStreamingMessage() }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title)
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .navigationTitle("Streaming")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        messages.removeAll()
                        errorMessage = nil
                    }
                    .disabled(messages.isEmpty || isStreaming)
                }
            }
        }
    }

    private func sendStreamingMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let client else { return }

        // Add user message
        let userMessage = DisplayMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil
        isStreaming = true
        currentStreamingContent = ""

        streamTask = Task {
            do {
                // Build conversation history
                let chatMessages = messages.map { msg in
                    switch msg.role {
                    case .user: return ChatMessage.user(msg.content)
                    case .assistant: return ChatMessage.assistant(msg.content)
                    case .system: return ChatMessage.system(msg.content)
                    }
                }

                let stream = try await client.chatCompletionStream(messages: chatMessages)

                for try await chunk in stream {
                    if let content = chunk.content {
                        currentStreamingContent += content
                    }
                }

                // Add completed message
                if !currentStreamingContent.isEmpty {
                    let assistantMessage = DisplayMessage(role: .assistant, content: currentStreamingContent)
                    messages.append(assistantMessage)
                }
            } catch let error as AIError {
                errorMessage = error.errorDescription
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }

            isStreaming = false
            currentStreamingContent = ""
        }
    }

    private func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil

        // Save partial response
        if !currentStreamingContent.isEmpty {
            let assistantMessage = DisplayMessage(role: .assistant, content: currentStreamingContent)
            messages.append(assistantMessage)
        }

        isStreaming = false
        currentStreamingContent = ""
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @State private var tempApiKey = ""
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if showingKey {
                            TextField("API Key", text: $tempApiKey)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("API Key", text: $tempApiKey)
                        }

                        Button {
                            showingKey.toggle()
                        } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                        }
                    }

                    Button("Save API Key") {
                        apiKey = tempApiKey
                    }
                    .disabled(tempApiKey.isEmpty)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Get your API key from swiftaikit.com/dashboard")
                }

                Section {
                    LabeledContent("Bundle ID") {
                        Text(Bundle.main.bundleIdentifier ?? "Unknown")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Team ID") {
                        if let teamId = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String {
                            Text(teamId.trimmingCharacters(in: CharacterSet(charactersIn: ".")))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not available")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("App Information")
                } footer: {
                    Text("Configure these in your SwiftAIKit dashboard for security.")
                }

                Section {
                    Link(destination: URL(string: "https://swiftaikit.com")!) {
                        Label("SwiftAIKit Website", systemImage: "globe")
                    }

                    Link(destination: URL(string: "https://swiftaikit.com/dashboard")!) {
                        Label("Dashboard", systemImage: "rectangle.on.rectangle")
                    }

                    Link(destination: URL(string: "https://github.com/swiftaikit/SwiftAIKit-iOS")!) {
                        Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } header: {
                    Text("Links")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                tempApiKey = apiKey
            }
        }
    }
}

// MARK: - Supporting Views

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

struct MessageBubble: View {
    let message: DisplayMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Models

struct DisplayMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String

    enum MessageRole {
        case user
        case assistant
        case system

        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "Assistant"
            case .system: return "System"
            }
        }
    }
}

#Preview {
    ContentView()
}
