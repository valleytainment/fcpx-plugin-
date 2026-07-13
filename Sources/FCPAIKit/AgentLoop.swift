import Foundation

public struct FCPAgent: Sendable {
    public let client: OllamaClient
    public let adapter: any FCPAdapter
    public let policy: AgentSafetyPolicy
    public let maxSteps: Int
    public let journal: ArtifactJournal
    public let toolDefinitions: [OllamaToolDefinition]

    public init(
        client: OllamaClient,
        adapter: any FCPAdapter,
        policy: AgentSafetyPolicy,
        maxSteps: Int = 8,
        journal: ArtifactJournal = ArtifactJournal(),
        toolDefinitions: [OllamaToolDefinition] = FCPToolCatalog.definitions
    ) {
        self.client = client
        self.adapter = adapter
        self.policy = policy
        self.maxSteps = max(1, maxSteps)
        self.journal = journal
        self.toolDefinitions = toolDefinitions
    }

    public func run(userRequest: String) async throws -> AgentRunResult {
        var messages: [OllamaChatMessage] = [
            OllamaChatMessage(role: "system", content: Self.systemPrompt(mode: policy.mode)),
            OllamaChatMessage(role: "user", content: userRequest)
        ]
        var executions: [ToolExecutionRecord] = []

        for step in 1...maxSteps {
            let assistant = try await client.chat(messages: messages, tools: toolDefinitions)
            messages.append(assistant)

            guard let calls = assistant.toolCalls, !calls.isEmpty else {
                let text = assistant.content?.trimmingCharacters(in: .whitespacesAndNewlines)
                return AgentRunResult(
                    finalMessage: text?.isEmpty == false ? text! : "The model finished without a textual response.",
                    steps: step,
                    toolExecutions: executions,
                    stoppedByLimit: false
                )
            }

            for call in calls {
                let decision = policy.authorize(toolName: call.function.name)
                let result: JSONValue

                if decision.allowed {
                    do {
                        result = try await adapter.execute(toolName: call.function.name, arguments: call.function.arguments)
                    } catch {
                        result = .object([
                            "ok": .bool(false),
                            "error": .string(String(describing: error))
                        ])
                    }
                } else {
                    result = .object([
                        "ok": .bool(false),
                        "blocked": .bool(true),
                        "reason": .string(decision.reason),
                        "required_mode": .string(requiredMode(for: call.function.name))
                    ])
                }

                let record = ToolExecutionRecord(
                    toolName: call.function.name,
                    arguments: call.function.arguments,
                    result: result,
                    authorized: decision.allowed
                )
                executions.append(record)
                await journal.append(record)

                messages.append(
                    OllamaChatMessage(
                        role: "tool",
                        content: result.prettyPrinted(),
                        toolName: call.function.name
                    )
                )
            }
        }

        return AgentRunResult(
            finalMessage: "The agent stopped after reaching the configured \(maxSteps)-step safety limit.",
            steps: maxSteps,
            toolExecutions: executions,
            stoppedByLimit: true
        )
    }

    private func requiredMode(for toolName: String) -> String {
        switch FCPToolCatalog.risk(for: toolName) {
        case .readOnly: return AgentMode.observe.rawValue
        case .reversibleEdit: return AgentMode.executeSafe.rawValue
        case .externalSideEffect: return "execute_safe + explicit external approval"
        case .destructive: return "not available"
        case nil: return "not available"
        }
    }

    private static func systemPrompt(mode: AgentMode) -> String {
        """
        You are the Valleytainment Final Cut Pro AI operator running locally.
        Current execution mode: \(mode.rawValue).

        OPERATING CONTRACT
        1. Use supplied tools for all claims about Final Cut Pro state or actions.
        2. Call fcp.get_timeline_state before proposing or performing edits.
        3. Before any multi-step edit, create a clearly named duplicate with project.duplicate.
        4. Never claim an action succeeded unless the tool returned ok=true.
        5. After edits, call fcp.get_timeline_state and compare expected versus actual state.
        6. If a tool is blocked, explain the exact approval or mode required; do not retry endlessly.
        7. Never invent clips, media paths, timecodes, exports, or project names.
        8. Keep plans compact and executable. Prefer exact frame numbers when using timeline tools.
        9. Never export, publish, delete original media, or overwrite a source project without explicit host approval.
        10. Stop when verification fails.

        In Suggest mode, read state and return a proposed action plan; blocked edit calls are evidence that approval is needed.
        """
    }
}
