Pod::Spec.new do |s|
  s.name             = 'SwiftAIKit'
  s.version          = '1.0.0'
  s.summary          = 'AI API Client for iOS, macOS, tvOS, and watchOS'
  s.description      = <<-DESC
    SwiftAIKit is a Swift SDK for integrating AI capabilities into your Apple platform apps.
    Features include:
    - Chat completions with streaming support
    - Multiple AI model support via OpenRouter
    - Automatic Bundle ID validation
    - Built-in rate limiting and quota management
    - Full async/await support
  DESC

  s.homepage         = 'https://github.com/swiftaikit/SwiftAIKit-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SwiftAIKit' => 'support@swiftaikit.com' }
  s.source           = { :git => 'https://github.com/swiftaikit/SwiftAIKit-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.tvos.deployment_target = '15.0'
  s.watchos.deployment_target = '8.0'

  s.swift_version = '5.9'
  s.source_files = 'Sources/SwiftAIKit/**/*'

  s.frameworks = 'Foundation'
end
