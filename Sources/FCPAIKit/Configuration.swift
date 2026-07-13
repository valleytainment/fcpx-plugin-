import Foundation

public struct FCPAIConfiguration: Codable, Equatable, Sendable {
    public var ollamaBaseURL: URL
    public var model: String
    public var temperature: Double
    public var topP: Double
    public var maxAgentSteps: Int
    public var defaultMode: AgentMode
    public var appGroupIdentifier: String

    public init(
        ollamaBaseURL: URL = URL(string: "http://127.0.0.1:11434")!,
        model: String = "qwen3:4b-instruct-2507-q4_K_M",
        temperature: Double = 0.2,
        topP: Double = 0.8,
        maxAgentSteps: Int = 8,
        defaultMode: AgentMode = .suggest,
        appGroupIdentifier: String = "group.com.valleytainment.fcpai"
    ) {
        self.ollamaBaseURL = ollamaBaseURL
        self.model = model
        self.temperature = temperature
        self.topP = topP
        self.maxAgentSteps = maxAgentSteps
        self.defaultMode = defaultMode
        self.appGroupIdentifier = appGroupIdentifier
    }

    public static func load(from url: URL) throws -> FCPAIConfiguration {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FCPAIConfiguration.self, from: data)
    }
}
