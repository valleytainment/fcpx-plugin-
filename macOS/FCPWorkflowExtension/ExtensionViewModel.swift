import Foundation
import FCPAIKit

@MainActor
final class ExtensionViewModel: ObservableObject {
    @Published var prompt = "Inspect the active timeline and summarize its current project, duration, frame rate, and playhead position."
    @Published var response = ""
    @Published var timelineSummary = "Open a project timeline, then refresh."
    @Published var mode: AgentMode = .suggest
    @Published var isRunning = false
    @Published var status = "Ready"

    private let adapter = WorkflowExtensionFCPAdapter()

    func refreshTimeline() {
        Task {
            do {
                let result = try await adapter.execute(toolName: "fcp.get_timeline_state", arguments: .object([:]))
                timelineSummary = result.prettyPrinted()
                status = "Timeline connected"
            } catch {
                timelineSummary = String(describing: error)
                status = "Timeline unavailable"
            }
        }
    }

    func runAgent() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let runtime = SharedRuntimeConfig.load()
        guard let baseURL = URL(string: runtime.ollamaBaseURL) else {
            response = "Invalid Ollama URL in shared runtime config."
            return
        }

        isRunning = true
        status = "Qwen is planning…"
        response = ""
        let model = runtime.model
        let client = OllamaClient(baseURL: baseURL, model: model)
        let publicTools = FCPToolCatalog.definitions(named: [
            "fcp.get_timeline_state",
            "timeline.move_playhead"
        ])
        let agent = FCPAgent(
            client: client,
            adapter: adapter,
            policy: AgentSafetyPolicy(mode: mode),
            maxSteps: 6,
            toolDefinitions: publicTools
        )

        Task {
            do {
                let result = try await agent.run(userRequest: prompt)
                response = result.finalMessage
                status = "Finished in \(result.steps) step(s)"
                refreshTimeline()
            } catch {
                response = String(describing: error)
                status = "Agent failed"
            }
            isRunning = false
        }
    }
}
