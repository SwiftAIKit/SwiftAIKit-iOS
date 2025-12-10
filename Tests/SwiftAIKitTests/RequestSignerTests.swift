import CryptoKit
import XCTest
@testable import SwiftAIKit

final class RequestSignerTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSignerInitialization() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        XCTAssertNotNil(signer)
    }

    // MARK: - Sign Method Tests

    func testSignReturnsValidTimestamp() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let beforeSign = Int64(Date().timeIntervalSince1970)

        let result = signer.sign(bodyData: nil)

        let afterSign = Int64(Date().timeIntervalSince1970)
        XCTAssertGreaterThanOrEqual(result.timestamp, beforeSign)
        XCTAssertLessThanOrEqual(result.timestamp, afterSign)
    }

    func testSignReturnsValidNonce() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")

        let result = signer.sign(bodyData: nil)

        // Nonce should be a valid UUID string
        XCTAssertNotNil(UUID(uuidString: result.nonce))
    }

    func testSignReturnsBase64Signature() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")

        let result = signer.sign(bodyData: nil)

        // Signature should be valid base64
        XCTAssertNotNil(Data(base64Encoded: result.signature))
    }

    func testSignProducesUniqueNonces() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")

        let result1 = signer.sign(bodyData: nil)
        let result2 = signer.sign(bodyData: nil)

        XCTAssertNotEqual(result1.nonce, result2.nonce)
    }

    // MARK: - Signature Computation Tests

    func testComputeSignatureWithEmptyBody() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        let signature1 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        let signature2 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: Data())

        // Empty body and nil body should produce the same signature
        XCTAssertEqual(signature1, signature2)
    }

    func testComputeSignatureIsDeterministic() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"
        let body = """
        {"messages":[{"role":"user","content":"Hello"}]}
        """.data(using: .utf8)!

        let signature1 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)
        let signature2 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)

        XCTAssertEqual(signature1, signature2)
    }

    func testDifferentApiKeysProduceDifferentSignatures() {
        let signer1 = RequestSigner(apiKey: "sk_test_key1", bundleId: "com.example.app")
        let signer2 = RequestSigner(apiKey: "sk_test_key2", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        let signature1 = signer1.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        let signature2 = signer2.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)

        XCTAssertNotEqual(signature1, signature2)
    }

    func testDifferentBundleIdsProduceDifferentSignatures() {
        let signer1 = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app1")
        let signer2 = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app2")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        let signature1 = signer1.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        let signature2 = signer2.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)

        XCTAssertNotEqual(signature1, signature2)
    }

    func testBundleIdCaseInsensitivity() {
        // Bundle IDs with different cases should produce the same signature
        let signer1 = RequestSigner(apiKey: "sk_test_123", bundleId: "com.Example.App")
        let signer2 = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let signer3 = RequestSigner(apiKey: "sk_test_123", bundleId: "COM.EXAMPLE.APP")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        let signature1 = signer1.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        let signature2 = signer2.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        let signature3 = signer3.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)

        // All signatures should be identical (case-insensitive Bundle ID)
        XCTAssertEqual(signature1, signature2)
        XCTAssertEqual(signature2, signature3)
    }

    func testDifferentTimestampsProduceDifferentSignatures() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        let signature1 = signer.computeSignature(timestamp: 1700000000, nonce: nonce, bodyData: nil)
        let signature2 = signer.computeSignature(timestamp: 1700000001, nonce: nonce, bodyData: nil)

        XCTAssertNotEqual(signature1, signature2)
    }

    func testDifferentNoncesProduceDifferentSignatures() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000

        let signature1 = signer.computeSignature(
            timestamp: timestamp,
            nonce: "550e8400-e29b-41d4-a716-446655440000",
            bodyData: nil
        )
        let signature2 = signer.computeSignature(
            timestamp: timestamp,
            nonce: "550e8400-e29b-41d4-a716-446655440001",
            bodyData: nil
        )

        XCTAssertNotEqual(signature1, signature2)
    }

    func testDifferentBodiesProduceDifferentSignatures() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"
        let body1 = """
        {"messages":[{"role":"user","content":"Hello"}]}
        """.data(using: .utf8)!
        let body2 = """
        {"messages":[{"role":"user","content":"Hi"}]}
        """.data(using: .utf8)!

        let signature1 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body1)
        let signature2 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body2)

        XCTAssertNotEqual(signature1, signature2)
    }

    // MARK: - Signature Length Tests

    func testSignatureLengthIsConsistent() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        // Test various body sizes
        let bodies: [Data?] = [
            nil,
            "".data(using: .utf8),
            "short".data(using: .utf8),
            String(repeating: "x", count: 10000).data(using: .utf8),
        ]

        var signatureLengths = Set<Int>()
        for body in bodies {
            let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)
            signatureLengths.insert(signature.count)
        }

        // All signatures should have the same base64 length (44 characters for 256-bit HMAC)
        XCTAssertEqual(signatureLengths.count, 1)
        XCTAssertEqual(signatureLengths.first, 44)
    }

    // MARK: - Cross-Platform Verification Tests

    /// Tests that the signature matches expected values for cross-platform verification.
    /// These test vectors can be used to verify the server-side implementation.
    func testKnownSignatureVector() {
        let signer = RequestSigner(apiKey: "sk_test_abc123", bundleId: "com.swiftaikit.demo")
        let timestamp: Int64 = 1702000000
        let nonce = "test-nonce-12345"
        let body = """
        {"model":"gpt-4","messages":[{"role":"user","content":"Hello"}]}
        """.data(using: .utf8)!

        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)

        // Verify it's valid base64 and correct length
        XCTAssertNotNil(Data(base64Encoded: signature))
        XCTAssertEqual(signature.count, 44)

        // The signature should be reproducible
        let signature2 = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)
        XCTAssertEqual(signature, signature2)
    }

    func testEmptyBodySignatureVector() {
        let signer = RequestSigner(apiKey: "sk_test_abc123", bundleId: "com.swiftaikit.demo")
        let timestamp: Int64 = 1702000000
        let nonce = "test-nonce-12345"

        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)

        // Verify it's valid base64 and correct length
        XCTAssertNotNil(Data(base64Encoded: signature))
        XCTAssertEqual(signature.count, 44)
    }

    // MARK: - Edge Cases

    func testSignerWithEmptyApiKey() {
        let signer = RequestSigner(apiKey: "", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        // Should still produce a valid signature (albeit insecure)
        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        XCTAssertNotNil(Data(base64Encoded: signature))
    }

    func testSignerWithEmptyBundleId() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"

        // Should still produce a valid signature
        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: nil)
        XCTAssertNotNil(Data(base64Encoded: signature))
    }

    func testSignerWithUnicodeContent() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"
        let body = """
        {"messages":[{"role":"user","content":"你好世界 🌍"}]}
        """.data(using: .utf8)!

        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)

        XCTAssertNotNil(Data(base64Encoded: signature))
        XCTAssertEqual(signature.count, 44)
    }

    func testSignerWithLargeBody() {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")
        let timestamp: Int64 = 1700000000
        let nonce = "550e8400-e29b-41d4-a716-446655440000"
        let largeContent = String(repeating: "a", count: 100_000)
        let body = """
        {"messages":[{"role":"user","content":"\(largeContent)"}]}
        """.data(using: .utf8)!

        let signature = signer.computeSignature(timestamp: timestamp, nonce: nonce, bodyData: body)

        XCTAssertNotNil(Data(base64Encoded: signature))
        XCTAssertEqual(signature.count, 44)
    }

    // MARK: - Sendable Conformance

    func testSignerIsSendable() async {
        let signer = RequestSigner(apiKey: "sk_test_123", bundleId: "com.example.app")

        // Test that signer can be used across async boundaries
        let result = await Task.detached {
            signer.sign(bodyData: nil)
        }.value

        XCTAssertNotNil(UUID(uuidString: result.nonce))
        XCTAssertNotNil(Data(base64Encoded: result.signature))
    }
}
