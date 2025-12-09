import Foundation

/// Internal HTTP client for making API requests
actor HTTPClient {
    private let configuration: AIConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(configuration: AIConfiguration) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2

        self.session = URLSession(configuration: sessionConfig)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    /// Make a POST request and decode the response
    func post<Request: Encodable, Response: Decodable>(
        path: String,
        body: Request
    ) async throws -> Response {
        let request = try buildRequest(path: path, method: "POST", body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        return try decodeResponse(data)
    }

    /// Make a GET request and decode the response
    func get<Response: Decodable>(path: String) async throws -> Response {
        let request = try buildRequest(path: path, method: "GET", body: nil as String?)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
        return try decodeResponse(data)
    }

    /// Make a streaming POST request
    func stream<Request: Encodable>(
        path: String,
        body: Request
    ) async throws -> AsyncThrowingStream<Data, Error> {
        var request = try buildRequest(path: path, method: "POST", body: body)
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
    ) throws -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        // Add Bundle ID header
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Bundle-Id")
        }

        // Add User-Agent
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        if let body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw AIError.encodingError(underlying: error)
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
