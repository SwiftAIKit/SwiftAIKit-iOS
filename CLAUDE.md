# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftAIKit-iOS is a Swift SDK for integrating AI capabilities into iOS, macOS, tvOS, and watchOS apps. It provides a simple async/await API for chat completions with streaming support.

## Commands

```bash
# Build package
swift build

# Run tests
swift test

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## Architecture

### Directory Structure
- `Sources/SwiftAIKit/` - Main SDK source code
  - `Client/` - AIClient and HTTPClient for API communication
  - `Configuration/` - AIConfiguration for SDK setup
  - `Models/` - Data models (ChatMessage, ChatCompletion, etc.)
  - `Errors/` - AIError enum for error handling
- `Tests/SwiftAIKitTests/` - Unit tests

### Key Design Decisions

**Actor-based Client**: `AIClient` is an actor for thread-safe concurrent access.

**Streaming**: Uses `AsyncThrowingStream` for SSE-based streaming responses.

**Bundle ID Validation**: Automatically sends `X-Bundle-Id` header for server-side validation.

**Error Handling**: Typed `AIError` enum with specific cases for rate limiting, quota exceeded, etc.

## API Endpoint

- Production: `https://api.swiftaikit.com`
- Local development: Use `AIConfiguration.local(apiKey:port:)`

## Publishing

### Swift Package Manager
Users add via Xcode or Package.swift:
```swift
.package(url: "https://github.com/YOUR_USERNAME/SwiftAIKit-iOS.git", from: "1.0.0")
```

### CocoaPods
```bash
# Validate
pod spec lint SwiftAIKit.podspec

# Publish
pod trunk push SwiftAIKit.podspec
```

## Code Style

- Swift 5.9+ with async/await
- Sendable conformance for thread safety
- Comprehensive error handling

