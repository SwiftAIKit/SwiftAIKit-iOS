//
//  SettingsView.swift
//  SwiftAIKitDemo
//
//  Settings view for API key configuration and app information.
//
//  This view demonstrates:
//  - How to configure and store the API key
//  - How to retrieve Bundle ID and Team ID for dashboard setup
//

import SwiftUI

/// Settings view for configuring the SwiftAIKit demo app.
///
/// Key information displayed:
/// - API Key input (required for SDK to work)
/// - Bundle ID (needed for dashboard security configuration)
/// - Team ID (optional, for enhanced security)
struct SettingsView: View {

    // MARK: - State Properties

    /// Persisted API Key using @AppStorage.
    ///
    /// Note: @AppStorage uses UserDefaults which is not encrypted.
    /// For production apps, consider using Keychain instead:
    /// ```swift
    /// // Example using KeychainAccess library
    /// let keychain = Keychain(service: "com.yourapp.api")
    /// keychain["apiKey"] = apiKey
    /// ```
    @AppStorage("apiKey") private var apiKey = ""

    /// Temporary API key for editing (not saved until user taps Save).
    @State private var tempApiKey = ""

    /// Toggle to show/hide the API key text.
    @State private var showingKey = false

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                appInfoSection
                linksSection
            }
            .navigationTitle("Settings")
            .onAppear {
                // Initialize temp key with current saved value
                tempApiKey = apiKey
            }
        }
    }

    // MARK: - Sections

    /// API Key configuration section.
    private var apiKeySection: some View {
        Section {
            HStack {
                // Toggle between visible text field and secure field
                if showingKey {
                    TextField("API Key", text: $tempApiKey)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("API Key", text: $tempApiKey)
                }

                // Show/hide toggle button
                Button {
                    showingKey.toggle()
                } label: {
                    Image(systemName: showingKey ? "eye.slash" : "eye")
                }
            }

            // Save button
            Button("Save API Key") {
                apiKey = tempApiKey
            }
            .disabled(tempApiKey.isEmpty)
        } header: {
            Text("API Configuration")
        } footer: {
            Text("Get your API key from swiftaikit.com/dashboard")
        }
    }

    /// App information section showing Bundle ID and Team ID.
    ///
    /// These values are needed when configuring your project
    /// in the SwiftAIKit dashboard for security verification.
    private var appInfoSection: some View {
        Section {
            // Bundle ID - Required for API key binding
            LabeledContent("Bundle ID") {
                Text(Bundle.main.bundleIdentifier ?? "Unknown")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Team ID - Optional for enhanced security
            //
            // The Team ID is extracted from the AppIdentifierPrefix
            // which is automatically set by Xcode during code signing.
            // Format: "TEAMID." (10 characters + dot)
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
            Text("Add these to your SwiftAIKit dashboard to enable security features.")
        }
    }

    /// Helpful links section.
    private var linksSection: some View {
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
}

// MARK: - Preview

#Preview {
    SettingsView()
}
