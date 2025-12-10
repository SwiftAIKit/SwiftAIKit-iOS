//
//  StreamingChatView.swift
//  SwiftAIKitDemo
//
//  Streaming chat view demonstrating real-time response streaming.
//
//  Key differences from ChatView:
//  - Uses chatCompletionStream() instead of chatCompletion()
//  - Receives response chunks in real-time via AsyncThrowingStream
//  - Supports cancellation of ongoing streams
//

import SwiftUI
import SwiftAIKit

/// Streaming chat view demonstrating real-time response streaming.
///
/// Key concepts demonstrated:
/// - Using `chatCompletionStream()` for real-time responses
/// - Processing `AsyncThrowingStream<ChatCompletionChunk, Error>`
/// - Cancelling ongoing streams with Task cancellation
/// - Preserving partial responses when cancelled
struct StreamingChatView: View {

    // MARK: - State Properties

    /// API Key stored persistently.
    @AppStorage("apiKey") private var apiKey = ""

    /// Chat message history.
    @State private var messages: [DisplayMessage] = []

    /// Current user input.
    @State private var inputText = ""

    /// Whether currently streaming a response.
    @State private var isStreaming = false

    /// Accumulated content from stream chunks.
    @State private var currentStreamingContent = ""

    /// Error message (if any).
    @State private var errorMessage: String?

    /// Reference to the streaming task for cancellation.
    @State private var streamTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Creates an AIClient instance.
    private var client: AIClient? {
        guard !apiKey.isEmpty else { return nil }
        return AIClient(apiKey: apiKey)
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if apiKey.isEmpty {
                    APIKeyPromptView()
                } else {
                    messageListView
                    errorView
                    inputAreaView
                }
            }
            .navigationTitle("Streaming")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    clearButton
                }
            }
        }
    }

    // MARK: - Subviews

    /// Message list with streaming indicator.
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }

                    // Show streaming message with cursor animation
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
            // Auto-scroll as streaming content updates
            .onChange(of: currentStreamingContent) {
                withAnimation {
                    proxy.scrollTo("streaming", anchor: .bottom)
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

    /// Input area with send/stop button.
    private var inputAreaView: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isStreaming)

            // Toggle between send and stop button based on streaming state
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

    /// Clear chat history button.
    private var clearButton: some View {
        Button("Clear") {
            messages.removeAll()
            errorMessage = nil
        }
        .disabled(messages.isEmpty || isStreaming)
    }

    // MARK: - Methods

    /// Sends a message and streams the AI response in real-time.
    ///
    /// This demonstrates streaming with SwiftAIKit:
    ///
    /// ```swift
    /// // 1. Get the stream
    /// let stream = try await client.chatCompletionStream(messages: messages)
    ///
    /// // 2. Process chunks as they arrive
    /// for try await chunk in stream {
    ///     if let content = chunk.content {
    ///         print(content, terminator: "") // No newline
    ///     }
    /// }
    /// ```
    ///
    /// The stream is an `AsyncThrowingStream<ChatCompletionChunk, Error>`
    /// that yields chunks as they arrive from the server.
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

        // Store task reference for cancellation support
        streamTask = Task {
            do {
                // Convert to ChatMessage format
                let chatMessages = messages.map { msg in
                    switch msg.role {
                    case .user: return ChatMessage.user(msg.content)
                    case .assistant: return ChatMessage.assistant(msg.content)
                    case .system: return ChatMessage.system(msg.content)
                    }
                }

                // Get the stream - this initiates the request
                let stream = try await client.chatCompletionStream(messages: chatMessages)

                // Process each chunk as it arrives
                // Each chunk contains a small piece of the response
                for try await chunk in stream {
                    if let content = chunk.content {
                        // Append chunk content to accumulated response
                        currentStreamingContent += content
                    }
                }

                // Stream completed - save the full response
                if !currentStreamingContent.isEmpty {
                    let assistantMessage = DisplayMessage(
                        role: .assistant,
                        content: currentStreamingContent
                    )
                    messages.append(assistantMessage)
                }

            } catch let error as AIError {
                errorMessage = error.errorDescription
            } catch {
                // Don't show error for intentional cancellation
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }

            // Reset streaming state
            isStreaming = false
            currentStreamingContent = ""
        }
    }

    /// Stops the current streaming response.
    ///
    /// This demonstrates cancellation:
    /// - Cancels the Task running the stream
    /// - Preserves any partial response received so far
    /// - Resets the streaming state
    private func stopStreaming() {
        // Cancel the streaming task
        streamTask?.cancel()
        streamTask = nil

        // Save partial response if any content was received
        if !currentStreamingContent.isEmpty {
            let assistantMessage = DisplayMessage(
                role: .assistant,
                content: currentStreamingContent
            )
            messages.append(assistantMessage)
        }

        // Reset state
        isStreaming = false
        currentStreamingContent = ""
    }
}

// MARK: - Preview

#Preview {
    StreamingChatView()
}
