import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Internal HTTP client for making API requests
actor HTTPClient {
    private let configuration: AIConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let signer: RequestSigner

    // Attestation components (iOS 14.0+)
    @available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
    private var attestationManager: (any AttestationProtocol)?

    @available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
    private var attestationKeychain: AttestationKeychain?

    init(configuration: AIConfiguration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2

        self.session = URLSession(configuration: sessionConfig)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        // Initialize request signer with API key and bundle ID
        self.signer = RequestSigner(
            apiKey: configuration.apiKey,
            bundleId: Bundle.main.bundleIdentifier ?? ""
        )

        // Initialize attestation based on environment (iOS 14.0+)
        if #available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *) {
            #if targetEnvironment(simulator)
            // Use simulator attestation in simulator environment
            self.attestationManager = SimulatorAttestation()
            #else
            // Use real App Attest on physical devices
            self.attestationManager = AttestationManager()
            #endif
            self.attestationKeychain = AttestationKeychain()
        }
    }

    /// Make a POST request and decode the response
    func post<Request: Encodable, Response: Decodable>(
        path: String,
        body: Request
    ) async throws -> Response {
        do {
            let request = try await buildRequest(path: path, method: "POST", body: body)
            let (data, response) = try await performRequest(request)
            try validateResponse(response, data: data)
            return try decodeResponse(data)
        } catch AIError.deviceNotRegistered {
            // Auto-register device and retry once
            if #available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *) {
                try await registerDevice()

                // Retry original request
                let request = try await buildRequest(path: path, method: "POST", body: body)
                let (data, response) = try await performRequest(request)
                try validateResponse(response, data: data)
                return try decodeResponse(data)
            } else {
                throw AIError.attestationNotSupported
            }
        } catch AIError.invalidAttestation {
            // Clear local attestation data and throw error for user to retry
            if #available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *) {
                await attestationManager?.clearAttestation()
                attestationKeychain?.clear()
            }
            throw AIError.invalidAttestation
        }
    }

    /// Make a GET request and decode the response
    func get<Response: Decodable>(path: String) async throws -> Response {
        let request = try await buildRequest(path: path, method: "GET", body: nil as String?)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        return try decodeResponse(data)
    }

    /// Make a streaming POST request
    func stream<Request: Encodable>(
        path: String,
        body: Request
    ) async throws -> AsyncThrowingStream<Data, Error> {
        var request = try await buildRequest(path: path, method: "POST", body: body)
        request.timeoutInterval = configuration.timeoutInterval * 2

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.unknown(message: "Invalid response type")
        }

        // Handle non-200 status codes by collecting error body
        if httpResponse.statusCode != 200 {
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            try handleErrorResponse(
                statusCode: httpResponse.statusCode,
                data: errorData,
                headers: httpResponse.allHeaderFields
            )
        }

        // Return stream for successful response
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var buffer = Data()
                    for try await byte in bytes {
                        // Check for cancellation
                        try Task.checkCancellation()

                        buffer.append(byte)

                        // Check for newline (SSE delimiter)
                        if byte == UInt8(ascii: "\n") {
                            if !buffer.isEmpty {
                                continuation.yield(buffer)
                                buffer = Data()
                            }
                        }
                    }

                    // Yield remaining data
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AIError.streamInterrupted)
                }
            }

            // Handle stream cancellation
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private Methods

    private func buildRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body?
    ) async throws -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        // Add Bundle ID header
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Bundle-Id")
        }

        // Add Team ID header (Apple Developer Team ID)
        if let teamId = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String {
            // Remove trailing dot if present
            let cleanTeamId = teamId.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            request.setValue(cleanTeamId, forHTTPHeaderField: "X-Team-Id")
        }

        // Add User-Agent
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Encode body if present
        if let body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw AIError.encodingError(underlying: error)
            }
        }

        // Sign the request
        let (timestamp, nonce, signature) = signer.sign(bodyData: request.httpBody)
        request.setValue(String(timestamp), forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")

        // Add environment header for API logging
        request.setValue(configuration.environment.isProduction ? "production" : "test", forHTTPHeaderField: "X-Environment")

        // Add attestation headers if available (iOS 14.0+)
        if #available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *),
           let manager = attestationManager,
           let keychain = attestationKeychain,
           let keyId = await manager.getKeyId(),
           let bodyData = request.httpBody
        {
            do {
                // Get and increment counter
                let counter = keychain.incrementCounter()

                // Generate assertion
                let assertion = try await manager.generateAssertion(requestData: bodyData, counter: counter)

                // Add attestation headers
                request.setValue(keyId, forHTTPHeaderField: "X-Attest-Key-Id")
                request.setValue(assertion, forHTTPHeaderField: "X-Attest-Assertion")
                request.setValue(String(counter), forHTTPHeaderField: "X-Attest-Counter")
            } catch {
                // Attestation generation failed - request will proceed without attestation
                // API will trigger device registration flow if attestation is required
            }
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AIError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw AIError.networkError(underlying: error)
            default:
                throw AIError.networkError(underlying: error)
            }
        } catch {
            throw AIError.networkError(underlying: error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.unknown(message: "Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            try handleErrorResponse(
                statusCode: httpResponse.statusCode,
                data: data,
                headers: httpResponse.allHeaderFields
            )
        }
    }

    private func handleErrorResponse(
        statusCode: Int,
        data: Data,
        headers: [AnyHashable: Any] = [:]
    ) throws -> Never {
        // Parse Retry-After header if present
        let retryAfter: Int? = {
            if let value = headers["Retry-After"] as? String {
                return Int(value)
            } else if let value = headers["retry-after"] as? String {
                return Int(value)
            }
            return nil
        }()

        // Try to decode error response
        struct ErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let message: String
                let type: String?
                let code: String?
            }
        }

        let message: String
        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            message = errorResponse.error.message

            // Handle specific error codes
            switch errorResponse.error.code {
            case "rate_limit_exceeded":
                throw AIError.rateLimitExceeded(retryAfter: retryAfter)
            case "quota_exceeded":
                throw AIError.quotaExceeded
            case "invalid_api_key", "missing_api_key":
                throw AIError.invalidAPIKey
            case "invalid_signature", "missing_signature_headers":
                throw AIError.invalidSignature
            case "timestamp_expired", "invalid_timestamp":
                throw AIError.timestampExpired
            case "nonce_reused":
                throw AIError.nonceReused
            case "invalid_bundle_id":
                throw AIError.invalidBundleId
            case "invalid_team_id":
                throw AIError.invalidTeamId
            case "attestation_required":
                throw AIError.attestationRequired
            case "device_not_registered":
                throw AIError.deviceNotRegistered
            case "invalid_attestation":
                throw AIError.invalidAttestation
            case "attestation_revoked":
                throw AIError.attestationRevoked
            case "simulator_not_allowed":
                throw AIError.simulatorNotAllowed
            default:
                break
            }
        } else {
            message = String(data: data, encoding: .utf8) ?? "Unknown error"
        }

        switch statusCode {
        case 401:
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimitExceeded(retryAfter: retryAfter)
        case 400:
            throw AIError.invalidRequest(message: message)
        case 500...599:
            throw AIError.serverError(message: message)
        default:
            throw AIError.httpError(statusCode: statusCode, message: message)
        }
    }

    private func decodeResponse<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw AIError.decodingError(underlying: error)
        }
    }

    // MARK: - Attestation Registration

    @available(iOS 14.0, macOS 11.0, tvOS 15.0, watchOS 9.0, *)
    private func registerDevice() async throws {
        guard let manager = attestationManager else {
            throw AIError.attestationNotSupported
        }

        // Step 1: Request challenge from server
        struct ChallengeRequest: Encodable {
            let bundleId: String
        }

        struct ChallengeResponse: Decodable {
            let challenge: String
        }

        let challengeRequest = ChallengeRequest(
            bundleId: Bundle.main.bundleIdentifier ?? "unknown"
        )
        let challengeResponse: ChallengeResponse = try await post(
            path: "/v1/attestation/challenge",
            body: challengeRequest
        )

        // Step 2: Attest key with Apple servers
        let attestation = try await manager.attestKey(challenge: challengeResponse.challenge)

        // Step 3: Register device with API
        struct RegistrationRequest: Encodable {
            let keyId: String
            let attestationObject: String
            let bundleId: String
            let teamId: String?
            let deviceModel: String
            let osVersion: String
        }

        struct RegistrationResponse: Decodable {
            let success: Bool
            let deviceId: String
        }

        let keyId = try await manager.ensureKeyExists()
        let registrationRequest = RegistrationRequest(
            keyId: keyId,
            attestationObject: attestation,
            bundleId: Bundle.main.bundleIdentifier ?? "unknown",
            teamId: getTeamId(),
            deviceModel: getDeviceModel(),
            osVersion: getOSVersion()
        )

        let _: RegistrationResponse = try await post(
            path: "/v1/attestation/register",
            body: registrationRequest
        )
    }

    private func getTeamId() -> String? {
        if let teamId = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String {
            return teamId.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
        return nil
    }

    private func getDeviceModel() -> String {
        #if os(iOS)
        return "iOS-\(UIDevice.current.model)"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "unknown"
        #endif
    }

    private func getOSVersion() -> String {
        #if os(iOS) || os(tvOS) || os(watchOS)
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "unknown"
        #endif
    }

    private var userAgent: String {
        #if os(iOS)
        return "SwiftAIKit/\(swiftAIKitVersion) iOS"
        #elseif os(macOS)
        return "SwiftAIKit/\(swiftAIKitVersion) macOS"
        #elseif os(tvOS)
        return "SwiftAIKit/\(swiftAIKitVersion) tvOS"
        #elseif os(watchOS)
        return "SwiftAIKit/\(swiftAIKitVersion) watchOS"
        #else
        return "SwiftAIKit/\(swiftAIKitVersion)"
        #endif
    }
}
