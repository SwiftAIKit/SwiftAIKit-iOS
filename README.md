# SwiftAIKit

A Swift SDK for integrating AI capabilities into your iOS, macOS, tvOS, and watchOS apps.

## Features

- Chat completions with streaming support
- Multiple AI model support (GPT-4, Claude, Gemini via OpenRouter)
- **Automatic request signing** - HMAC-SHA256 signatures prevent API key misuse
- **Replay attack protection** - Timestamp and nonce validation
- **Bundle ID binding** - API keys only work with authorized apps
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
    defaultModel: "google/gemini-2.5-flash"
)
let client = AIClient(configuration: config)
```

### Advanced Options

```swift
let response = try await client.chatCompletion(
    messages: [.user("Write a haiku about Swift")],
    model: "google/gemini-2.5-flash",
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

## Security Best Practices

### ⚠️ Critical: Never Hardcode API Keys

**DO NOT:**
- ❌ Hardcode API keys directly in your source code
- ❌ Store keys in `UserDefaults` (unencrypted)
- ❌ Commit keys to version control (add to `.gitignore`)
- ❌ Share production keys in demo apps or repositories
- ❌ Include keys in app screenshots or logs

**DO:**
- ✅ Store keys securely in **iOS Keychain** (see implementation below)
- ✅ Use environment variables during development
- ✅ Separate test and production keys
- ✅ Rotate keys regularly from your dashboard
- ✅ Monitor API usage for suspicious activity

### Secure API Key Storage

**Production-Ready Reference**: `SwiftAIKitDemo/KeychainStorage.swift`

⚠️ **Note**: The demo app uses `UserDefaults` for simplicity. For production apps, use the provided `KeychainStorage.swift` reference implementation.

Here's how to store your API key securely using Keychain:

```swift
// 1. Copy KeychainStorage.swift to your project

// 2. Save API key to Keychain
try KeychainStorage.save(key: "apiKey", value: "sk_live_your_key_here")

// 3. Retrieve from Keychain when initializing the client
if let apiKey = try? KeychainStorage.get(key: "apiKey") {
    let client = AIClient(apiKey: apiKey)
} else {
    // Prompt user to enter API key in settings
}

// 4. Delete from Keychain when logging out
try KeychainStorage.delete(key: "apiKey")
```

**Why Keychain for Production?**
- 🔐 **Encrypted** at the OS level (vs. UserDefaults plaintext)
- 🚫 **Isolated** - Not accessible by other apps
- 💾 **Persistent** - Survives app reinstalls (optional)
- ☁️ **Private** - Not backed up to iCloud (with correct accessibility settings)
- 🔒 **Secure** - Cannot be extracted via device backups or jailbreak tools

**Copy-paste ready implementation**: See `SwiftAIKitDemo/SwiftAIKitDemo/KeychainStorage.swift`

### Environment-Based Configuration

For development, use build configurations:

```swift
// Debug configuration
#if DEBUG
let client = AIClient(apiKey: ProcessInfo.processInfo.environment["SWIFTAIKIT_API_KEY"] ?? "")
#else
// Production: load from Keychain
let apiKey = try KeychainStorage.get(key: "apiKey")
let client = AIClient(apiKey: apiKey ?? "")
#endif
```

Then set the environment variable in your Xcode scheme:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `SWIFTAIKIT_API_KEY` with your test key

## Security Features

SwiftAIKit includes built-in security features to protect your API keys from misuse.

### How It Works

All API requests are automatically signed using HMAC-SHA256. The signature includes:

- **Timestamp** - Requests are only valid within ±5 minutes
- **Nonce** - Each request has a unique identifier to prevent replay attacks
- **Body Hash** - Request body is included in the signature to prevent tampering
- **Bundle ID** - Your app's bundle identifier is bound to the signature

This means even if someone intercepts your API key, they cannot use it from a different app.

### Setup Requirements

1. **Configure Bundle ID** in your [SwiftAIKit Dashboard](https://swiftaikit.com/dashboard):
   - Go to your project settings
   - Add your app's Bundle ID (e.g., `com.yourcompany.yourapp`)
   - Wildcards are supported (e.g., `com.yourcompany.*`)

2. **Optional: Configure Team ID** for additional security:
   - Add your Apple Developer Team ID (10 characters, e.g., `ABCDE12345`)
   - Find it in [Apple Developer Portal](https://developer.apple.com/account) under Membership

### No Code Changes Required

The SDK automatically:
- Signs every request with your API key and Bundle ID
- Adds timestamp and nonce headers
- Sends your app's Team ID (if available)

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
} catch AIError.invalidSignature {
    print("Request signature verification failed")
} catch AIError.timestampExpired {
    print("Request timestamp outside valid window")
} catch AIError.nonceReused {
    print("Request nonce was already used")
} catch AIError.invalidBundleId {
    print("Bundle ID not authorized for this project")
} catch AIError.invalidTeamId {
    print("Team ID not authorized for this project")
} catch {
    print("Error: \(error)")
}
```

### Security Errors

| Error | Description | Solution |
|-------|-------------|----------|
| `invalidSignature` | Request signature verification failed | Ensure SDK is up to date |
| `timestampExpired` | Device clock is off by more than 5 minutes | Check device time settings |
| `nonceReused` | Duplicate request detected | Retry with a new request |
| `invalidBundleId` | Bundle ID not in project whitelist | Add Bundle ID in dashboard |
| `invalidTeamId` | Team ID not in project whitelist | Add Team ID in dashboard |

## Configuration Options

```swift
let config = AIConfiguration(
    apiKey: "sk_live_...",
    baseURL: URL(string: "https://api.swiftaikit.com")!,
    timeoutInterval: 60,
    defaultModel: "google/gemini-2.5-flash"
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
