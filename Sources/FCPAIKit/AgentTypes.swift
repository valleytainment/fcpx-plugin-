import Foundation

public enum AgentMode: String, Codable, CaseIterable, Sendable {
    case observe
    case suggest
    case executeSafe = "execute_safe"
    case autoEdit = "auto_edit"
}

public enum ToolRisk: String, Codable, Sendable {
    case readOnly = "read_only"
    case reversibleEdit = "reversible_edit"
    case externalSideEffect = "external_side_effect"
    case destructive
}

public struct TimelineMarker: Codable, Equatable, Sendable {
    public let frame: Int
    public let name: String

    public init(frame: Int, name: String) {
        self.frame = frame
        self.name = name
    }
}

public struct TimelineState: Codable, Equatable, Sendable {
    public var projectName: String
    public var sourceProjectName: String?
    public var frameRate: Double
    public var durationFrames: Int
    public var playheadFrame: Int
    public var markers: [TimelineMarker]
    public var cuts: [Int]
    public var isDuplicate: Bool

    public init(
        projectName: String,
        sourceProjectName: String? = nil,
        frameRate: Double = 24,
        durationFrames: Int = 14_400,
        playheadFrame: Int = 0,
        markers: [TimelineMarker] = [],
        cuts: [Int] = [],
        isDuplicate: Bool = false
    ) {
        self.projectName = projectName
        self.sourceProjectName = sourceProjectName
        self.frameRate = frameRate
        self.durationFrames = durationFrames
        self.playheadFrame = playheadFrame
        self.markers = markers
        self.cuts = cuts
        self.isDuplicate = isDuplicate
    }
}

public struct ToolExecutionRecord: Codable, Equatable, Sendable {
    public let toolName: String
    public let arguments: JSONValue
    public let result: JSONValue
    public let authorized: Bool
    public let timestamp: Date

    public init(toolName: String, arguments: JSONValue, result: JSONValue, authorized: Bool, timestamp: Date = Date()) {
        self.toolName = toolName
        self.arguments = arguments
        self.result = result
        self.authorized = authorized
        self.timestamp = timestamp
    }
}

public struct AgentRunResult: Codable, Equatable, Sendable {
    public let finalMessage: String
    public let steps: Int
    public let toolExecutions: [ToolExecutionRecord]
    public let stoppedByLimit: Bool

    public init(finalMessage: String, steps: Int, toolExecutions: [ToolExecutionRecord], stoppedByLimit: Bool) {
        self.finalMessage = finalMessage
        self.steps = steps
        self.toolExecutions = toolExecutions
        self.stoppedByLimit = stoppedByLimit
    }
}
