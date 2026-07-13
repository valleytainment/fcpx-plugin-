import Foundation

public struct SafetyDecision: Equatable, Sendable {
    public let allowed: Bool
    public let reason: String

    public init(allowed: Bool, reason: String) {
        self.allowed = allowed
        self.reason = reason
    }
}

public struct AgentSafetyPolicy: Sendable {
    public let mode: AgentMode
    public let allowExternalSideEffects: Bool

    public init(mode: AgentMode, allowExternalSideEffects: Bool = false) {
        self.mode = mode
        self.allowExternalSideEffects = allowExternalSideEffects
    }

    public func authorize(toolName: String) -> SafetyDecision {
        guard let risk = FCPToolCatalog.risk(for: toolName) else {
            return SafetyDecision(allowed: false, reason: "Unknown tool is denied by default.")
        }

        switch mode {
        case .observe:
            return risk == .readOnly
                ? SafetyDecision(allowed: true, reason: "Read-only operation allowed in Observe mode.")
                : SafetyDecision(allowed: false, reason: "Observe mode cannot change Final Cut Pro.")

        case .suggest:
            return risk == .readOnly
                ? SafetyDecision(allowed: true, reason: "Read-only operation allowed while preparing a proposal.")
                : SafetyDecision(allowed: false, reason: "Suggest mode requires approval before execution.")

        case .executeSafe:
            switch risk {
            case .readOnly, .reversibleEdit:
                return SafetyDecision(allowed: true, reason: "Bounded reversible operation allowed.")
            case .externalSideEffect:
                return SafetyDecision(allowed: allowExternalSideEffects, reason: allowExternalSideEffects ? "Explicit external-side-effect approval present." : "Export/publish requires explicit approval.")
            case .destructive:
                return SafetyDecision(allowed: false, reason: "Destructive operations are never allowed in Execute Safe mode.")
            }

        case .autoEdit:
            switch risk {
            case .readOnly, .reversibleEdit:
                return SafetyDecision(allowed: true, reason: "Autonomous reversible operation allowed.")
            case .externalSideEffect:
                return SafetyDecision(allowed: allowExternalSideEffects, reason: allowExternalSideEffects ? "Explicit external-side-effect approval present." : "Autonomous export/publish remains locked.")
            case .destructive:
                return SafetyDecision(allowed: false, reason: "Original-media destructive operations remain locked.")
            }
        }
    }
}
