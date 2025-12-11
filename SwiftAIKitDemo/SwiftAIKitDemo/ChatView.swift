//
//  ChatView.swift
//  SwiftAIKitDemo
//
//  Basic chat view demonstrating standard chat completion.
//
//  This is the simplest SwiftAIKit usage example:
//  1. Create an AIClient with your API key
//  2. Build message history as [ChatMessage]
//  3. Call chatCompletion() to get the response
//

import SwiftUI
import SwiftAIKit

/// Basic chat view demonstrating standard (non-streaming) chat completion.
///
/// Key concepts demonstrated:
/// - Creating and configuring `AIClient`
/// - Converting UI messages to `ChatMessage` format
/// - Calling `chatCompletion()` and handling the response
/// - Error handling with `AIError`
struct ChatView: View {

    // MARK: - State Properties

    /// API Key stored persistently using @AppStorage.
    /// In production, consider using Keychain for sensitive data.
    @AppStorage("apiKey") private var apiKey = ""

    /// Chat message history for display.
    @State private var messages: [DisplayMessage] = []

    /// Current user input text.
    @State private var inputText = ""

    /// Loading state while waiting for API response.
    @State private var isLoading = false

    /// Error message to display (if any).
    @State private var errorMessage: String?

    // MARK: - Computed Properties

    /// Creates an AIClient instance.
    ///
    /// Note: This creates a new instance on each access.
    /// In production, consider storing the client as a singleton
    /// or injecting it via environment.
    ///
    /// Example with custom configuration:
    /// ```swift
    /// let config = AIConfiguration(
    ///     apiKey: apiKey,
    ///     defaultModel: "google/gemini-2.5-flash"
    /// )
    /// return AIClient(configuration: config)
    /// ```
    private var client: AIClient? {
        guard !apiKey.isEmpty else { return nil }
        return AIClient(apiKey: apiKey)
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if apiKey.isEmpty {
                    // Show prompt when API Key is not configured
                    APIKeyPromptView()
                } else {
                    messageListView
                    errorView
                    inputAreaView
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    clearButton
                }
            }
        }
    }

    // MARK: - Subviews

    /// Scrollable list of chat messages.
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }

                    // Loading indicator while waiting for response
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
            // Auto-scroll to bottom when new message arrives
            .onChange(of: messages.count) {
                withAnimation {
                    proxy.scrollTo(messages.last?.id ?? UUID(), anchor: .bottom)
                }
            }
        }
    }

    /// Error message banner.
    @ViewBuilder
    private var errorView: some View {
        if let error = errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
        }
    }

    /// Text input field and send button.
    private var inputAreaView: some View {
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

    /// Button to clear chat history.
    private var clearButton: some View {
        Button("Clear") {
            messages.removeAll()
            errorMessage = nil
        }
        .disabled(messages.isEmpty)
    }

    // MARK: - Methods

    /// Sends a message and receives AI response.
    ///
    /// This demonstrates the core SwiftAIKit workflow:
    ///
    /// ```swift
    /// // 1. Build messages array
    /// let messages: [ChatMessage] = [
    ///     .system("You are a helpful assistant."),
    ///     .user("Hello!")
    /// ]
    ///
    /// // 2. Call chatCompletion
    /// let response = try await client.chatCompletion(messages: messages)
    ///
    /// // 3. Access the response content
    /// print(response.content ?? "No response")
    /// ```
    private func sendMessage() async {
        // Prepare user message
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let client else { return }

        let userMessage = DisplayMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil
        isLoading = true

        // Ensure loading state is reset when function exits
        defer { isLoading = false }

        do {
            // Convert DisplayMessage to ChatMessage for API
            //
            // SwiftAIKit provides convenient static constructors:
            // - ChatMessage.user(_:)      - User message
            // - ChatMessage.assistant(_:) - Assistant message
            // - ChatMessage.system(_:)    - System prompt
            let chatMessages = messages.map { msg in
                switch msg.role {
                case .user: return ChatMessage.user(msg.content)
                case .assistant: return ChatMessage.assistant(msg.content)
                case .system: return ChatMessage.system(msg.content)
                }
            }

            // Call the API - this waits for the complete response
            // For real-time streaming, use chatCompletionStream() instead
            let response = try await client.chatCompletion(messages: chatMessages)

            // Add assistant response to chat
            if let content = response.content {
                let assistantMessage = DisplayMessage(role: .assistant, content: content)
                messages.append(assistantMessage)
            }

        } catch let error as AIError {
            // Handle SwiftAIKit-specific errors
            //
            // Common error types:
            // - .invalidAPIKey      - API key is invalid or missing
            // - .rateLimitExceeded  - Too many requests, check retryAfter
            // - .quotaExceeded      - Monthly quota exceeded
            // - .invalidSignature   - Request signature failed (SDK issue)
            // - .timestampExpired   - Device clock is incorrect
            // - .invalidBundleId    - App not authorized for this API key
            // - .invalidTeamId      - Team ID not authorized
            errorMessage = error.errorDescription

        } catch {
            // Handle other errors (network, etc.)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
