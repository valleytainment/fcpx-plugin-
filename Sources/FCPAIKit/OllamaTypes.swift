import Foundation

public struct OllamaChatMessage: Codable, Equatable, Sendable {
    public let role: String
    public let content: String?
    public let toolCalls: [OllamaToolCall]?
    public let toolName: String?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCalls = "tool_calls"
        case toolName = "tool_name"
    }

    public init(role: String, content: String? = nil, toolCalls: [OllamaToolCall]? = nil, toolName: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolName = toolName
    }
}

public struct OllamaToolCall: Codable, Equatable, Sendable {
    public let type: String?
    public let function: OllamaToolCallFunction

    public init(type: String? = "function", function: OllamaToolCallFunction) {
        self.type = type
        self.function = function
    }
}

public struct OllamaToolCallFunction: Codable, Equatable, Sendable {
    public let index: Int?
    public let name: String
    public let arguments: JSONValue

    public init(index: Int? = nil, name: String, arguments: JSONValue) {
        self.index = index
        self.name = name
        self.arguments = arguments
    }
}

public struct OllamaToolDefinition: Codable, Equatable, Sendable {
    public let type: String
    public let function: OllamaFunctionDefinition

    public init(function: OllamaFunctionDefinition) {
        self.type = "function"
        self.function = function
    }
}

public struct OllamaFunctionDefinition: Codable, Equatable, Sendable {
    public let name: String
    public let description: String
    public let parameters: JSONValue

    public init(name: String, description: String, parameters: JSONValue) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

struct OllamaChatRequest: Encodable, Sendable {
    let model: String
    let messages: [OllamaChatMessage]
    let stream: Bool
    let tools: [OllamaToolDefinition]
    let options: OllamaOptions
    let keepAlive: String

    enum CodingKeys: String, CodingKey {
        case model, messages, stream, tools, options
        case keepAlive = "keep_alive"
    }
}

struct OllamaOptions: Encodable, Sendable {
    let temperature: Double
    let topP: Double
    let seed: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case seed
    }
}

struct OllamaChatResponse: Decodable, Sendable {
    let message: OllamaChatMessage
    let done: Bool?
    let doneReason: String?

    enum CodingKeys: String, CodingKey {
        case message, done
        case doneReason = "done_reason"
    }
}
