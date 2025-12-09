# SwiftAIKit

A Swift SDK for integrating AI capabilities into your iOS, macOS, tvOS, and watchOS apps.

## Features

- Chat completions with streaming support
- Multiple AI model support (GPT-4, Claude, Gemini via OpenRouter)
- Automatic Bundle ID validation
- Built-in rate limiting and quota management
- Full async/await support
- Type-safe API

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swiftaikit/SwiftAIKit-iOS.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'SwiftAIKit', '~> 1.0'
```

Then run `pod install`.

## Quick Start

### Initialize the Client

```swift
import SwiftAIKit

let client = AIClient(apiKey: "sk_live_your_api_key")
```

### Chat Completion

```swift
let response = try await client.chatCompletion(
    messages: [
        .system("You are a helpful assistant."),
        .user("What is the capital of France?")
    ]
)

print(response.content ?? "No response")
```

### Streaming Chat Completion

```swift
let stream = try await client.chatCompletionStream(
    messages: [.user("Tell me a story")]
)

for try await chunk in stream {
    if let content = chunk.content {
        print(content, terminator: "")
    }
}
```

### Using Different Models

```swift
// Use a specific model
let response = try await client.chatCompletion(
    messages: [.user("Hello!")],
    model: "anthropic/claude-3.5-sonnet"
)

// Set a default model in configuration
let config = AIConfiguration(
    apiKey: "sk_live_...",
    defaultModel: "openai/gpt-4o"
)
let client = AIClient(configuration: config)
```

### Advanced Options

```swift
let response = try await client.chatCompletion(
    messages: [.user("Write a haiku about Swift")],
    model: "openai/gpt-4o",
    temperature: 0.7,
    maxTokens: 100,
    topP: 0.9
)
```

## SwiftUI Integration

```swift
import SwiftUI
import SwiftAIKit

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isLoading = false

    let client = AIClient(apiKey: "sk_live_...")

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages.indices, id: \.self) { index in
                    MessageBubble(message: messages[index])
                }
            }

            HStack {
                TextField("Message", text: $input)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    Task { await sendMessage() }
                }
                .disabled(input.isEmpty || isLoading)
            }
            .padding()
        }
    }

    func sendMessage() async {
        let userMessage = ChatMessage.user(input)
        messages.append(userMessage)
        input = ""
        isLoading = true

        do {
            let response = try await client.chatCompletion(messages: messages)
            if let content = response.content {
                messages.append(.assistant(content))
            }
        } catch {
            print("Error: \(error)")
        }

        isLoading = false
    }
}
```

## Streaming with SwiftUI

```swift
struct StreamingChatView: View {
    @State private var response = ""
    @State private var isStreaming = false

    let client = AIClient(apiKey: "sk_live_...")

    var body: some View {
        VStack {
            ScrollView {
                Text(response)
                    .padding()
            }

            Button(isStreaming ? "Streaming..." : "Start") {
                Task { await streamResponse() }
            }
            .disabled(isStreaming)
        }
    }

    func streamResponse() async {
        response = ""
        isStreaming = true

        do {
            let stream = try await client.chatCompletionStream(
                messages: [.user("Tell me a story")]
            )

            for try await chunk in stream {
                if let content = chunk.content {
                    response += content
                }
            }
        } catch {
            response = "Error: \(error.localizedDescription)"
        }

        isStreaming = false
    }
}
```

## Error Handling

```swift
do {
    let response = try await client.chatCompletion(messages: messages)
} catch AIError.invalidAPIKey {
    print("Invalid API key")
} catch AIError.rateLimitExceeded(let retryAfter) {
    print("Rate limited. Retry after \(retryAfter ?? 0) seconds")
} catch AIError.quotaExceeded {
    print("Monthly quota exceeded")
} catch AIError.timeout {
    print("Request timed out")
} catch {
    print("Error: \(error)")
}
```

## Configuration Options

```swift
let config = AIConfiguration(
    apiKey: "sk_live_...",
    baseURL: URL(string: "https://api.swiftaikit.com")!,
    timeoutInterval: 60,
    defaultModel: "openai/gpt-4o-mini"
)

let client = AIClient(configuration: config)
```

### Local Development

```swift
let config = AIConfiguration.local(apiKey: "sk_test_...", port: 3001)
let client = AIClient(configuration: config)
```

## Available Models

| Provider | Model ID |
|----------|----------|
| OpenAI | `openai/gpt-4o` |
| OpenAI | `openai/gpt-4o-mini` |
| Anthropic | `anthropic/claude-3.5-sonnet` |
| Anthropic | `anthropic/claude-3-haiku` |
| Google | `google/gemini-pro-1.5` |
| Google | `google/gemini-flash-1.5` |

## License

MIT License. See [LICENSE](LICENSE) for details.
