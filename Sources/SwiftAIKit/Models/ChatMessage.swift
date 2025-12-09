import Foundation

/// A message in a chat conversation
public struct ChatMessage: Codable, Sendable, Equatable {
    /// The role of the message author
    public let role: Role

    /// The content of the message
    public let content: String?

    /// The name of the author (optional, for function messages)
    public let name: String?

    /// Tool calls made by the assistant (optional)
    public let toolCalls: [ToolCall]?

    /// The ID of the tool call this message is responding to
    public let toolCallId: String?

    /// Message role
    public enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
        case tool
        case function
    }

    /// Tool call information
    public struct ToolCall: Codable, Sendable, Equatable {
        public let id: String
        public let type: String
        public let function: FunctionCall

        public struct FunctionCall: Codable, Sendable, Equatable {
            public let name: String
            public let arguments: String
        }
    }

    enum CodingKeys: String, CodingKey {
        case role, content, name
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }

    /// Create a system message
    public static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content, name: nil, toolCalls: nil, toolCallId: nil)
    }

    /// Create a user message
    public static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content, name: nil, toolCalls: nil, toolCallId: nil)
    }

    /// Create an assistant message
    public static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, name: nil, toolCalls: nil, toolCallId: nil)
    }

    /// Create a custom message
    public init(
        role: Role,
        content: String?,
        name: String? = nil,
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) {
        self.role = role
        self.content = content
        self.name = name
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
}
