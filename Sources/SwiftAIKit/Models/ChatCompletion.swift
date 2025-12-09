import Foundation

/// A chat completion response
public struct ChatCompletion: Codable, Sendable {
    /// Unique identifier for the completion
    public let id: String

    /// Object type (always "chat.completion")
    public let object: String

    /// Unix timestamp of when the completion was created
    public let created: Int

    /// The model used for completion
    public let model: String

    /// The list of completion choices
    public let choices: [Choice]

    /// Token usage statistics
    public let usage: Usage?

    /// A completion choice
    public struct Choice: Codable, Sendable {
        /// The index of this choice
        public let index: Int

        /// The generated message
        public let message: ChatMessage

        /// The reason the completion stopped
        public let finishReason: FinishReason?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    /// Reason for completion finishing
    public enum FinishReason: String, Codable, Sendable {
        case stop
        case length
        case toolCalls = "tool_calls"
        case contentFilter = "content_filter"
        case functionCall = "function_call"
    }

    /// Token usage information
    public struct Usage: Codable, Sendable {
        /// Number of tokens in the prompt
        public let promptTokens: Int

        /// Number of tokens in the completion
        public let completionTokens: Int

        /// Total number of tokens used
        public let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

/// Extension to get the first message content easily
public extension ChatCompletion {
    /// The content of the first choice's message
    var content: String? {
        choices.first?.message.content
    }
}
