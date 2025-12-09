import Foundation

/// A streaming chat completion chunk
public struct ChatCompletionChunk: Codable, Sendable {
    /// Unique identifier for the completion
    public let id: String

    /// Object type (always "chat.completion.chunk")
    public let object: String

    /// Unix timestamp of when the chunk was created
    public let created: Int

    /// The model used for completion
    public let model: String

    /// The list of completion choices
    public let choices: [Choice]

    /// Token usage statistics (only in final chunk when requested)
    public let usage: Usage?

    /// A streaming choice
    public struct Choice: Codable, Sendable {
        /// The index of this choice
        public let index: Int

        /// The delta content
        public let delta: Delta

        /// The reason the completion stopped (only in final chunk)
        public let finishReason: FinishReason?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    /// Delta content in a streaming response
    public struct Delta: Codable, Sendable {
        /// The role (only in first chunk)
        public let role: ChatMessage.Role?

        /// The content fragment
        public let content: String?

        /// Tool calls (streamed incrementally)
        public let toolCalls: [ChatMessage.ToolCall]?

        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
        }
    }

    /// Reason for completion finishing
    public enum FinishReason: String, Codable, Sendable {
        case stop
        case length
        case toolCalls = "tool_calls"
        case contentFilter = "content_filter"
    }

    /// Token usage information
    public struct Usage: Codable, Sendable {
        /// Number of tokens in the prompt
        public let promptTokens: Int?

        /// Number of tokens in the completion
        public let completionTokens: Int?

        /// Total number of tokens used
        public let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

/// Extension to get content easily
public extension ChatCompletionChunk {
    /// The content of the first choice's delta
    var content: String? {
        choices.first?.delta.content
    }
}
