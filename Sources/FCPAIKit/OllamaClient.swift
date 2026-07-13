import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum OllamaClientError: Error, CustomStringConvertible, Sendable {
    case invalidResponse
    case httpStatus(Int, String)
    case decoding(String)

    public var description: String {
        switch self {
        case .invalidResponse:
            return "Ollama returned a non-HTTP response."
        case .httpStatus(let status, let body):
            return "Ollama HTTP \(status): \(body)"
        case .decoding(let details):
            return "Could not decode Ollama response: \(details)"
        }
    }
}

public struct OllamaClient: Sendable {
    public let baseURL: URL
    public let model: String
    public let temperature: Double
    public let topP: Double
    public let seed: Int

    public init(
        baseURL: URL = URL(string: "http://127.0.0.1:11434")!,
        model: String = "qwen3:4b-instruct-2507-q4_K_M",
        temperature: Double = 0.2,
        topP: Double = 0.8,
        seed: Int = 42
    ) {
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.topP = topP
        self.seed = seed
    }

    public func chat(messages: [OllamaChatMessage], tools: [OllamaToolDefinition]) async throws -> OllamaChatMessage {
        let endpoint = baseURL.appendingPathComponent("api/chat")
        let payload = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: false,
            tools: tools,
            options: OllamaOptions(temperature: temperature, topP: topP, seed: seed),
            keepAlive: "15m"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OllamaClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw OllamaClientError.httpStatus(http.statusCode, body)
        }

        do {
            return try JSONDecoder().decode(OllamaChatResponse.self, from: data).message
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw OllamaClientError.decoding("\(error)\nBody: \(body)")
        }
    }

    public func healthCheck() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 4
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<300).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
