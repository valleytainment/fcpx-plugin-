import Foundation
import FCPAIKit

@main
struct FCPAIHostCLI {
    static func main() async {
        do {
            let options = try CLIOptions.parse(CommandLine.arguments)
            let model = ProcessInfo.processInfo.environment["FCP_AI_MODEL"] ?? options.model
            let baseURL = URL(string: ProcessInfo.processInfo.environment["OLLAMA_BASE_URL"] ?? "http://127.0.0.1:11434")!
            let client = OllamaClient(baseURL: baseURL, model: model)

            guard await client.healthCheck() else {
                throw CLIError.message("Ollama is not reachable at \(baseURL.absoluteString). Start Ollama and pull the configured model.")
            }

            let adapter = MockFCPAdapter(
                initialState: TimelineState(
                    projectName: "Demo Interview",
                    frameRate: 24,
                    durationFrames: 8_640,
                    playheadFrame: 0
                )
            )

            let runID = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let journalURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Runs", isDirectory: true)
                .appendingPathComponent(runID, isDirectory: true)
            let agent = FCPAgent(
                client: client,
                adapter: adapter,
                policy: AgentSafetyPolicy(mode: options.mode, allowExternalSideEffects: options.allowExternalSideEffects),
                maxSteps: options.maxSteps,
                journal: ArtifactJournal(directory: journalURL)
            )

            print("Model: \(model)")
            print("Mode: \(options.mode.rawValue)")
            print("Request: \(options.request)\n")

            let result = try await agent.run(userRequest: options.request)
            print("=== Agent response ===")
            print(result.finalMessage)
            print("\n=== Execution summary ===")
            print("Steps: \(result.steps)")
            print("Tool calls: \(result.toolExecutions.count)")
            print("Stopped by limit: \(result.stoppedByLimit)")

            if !result.toolExecutions.isEmpty {
                for (index, execution) in result.toolExecutions.enumerated() {
                    print("\n[\(index + 1)] \(execution.toolName) authorized=\(execution.authorized)")
                    print(execution.result.prettyPrinted())
                }
            }

            print("\nArtifacts: \(journalURL.path)")
        } catch {
            let errorText = "Error: \(error)\n" + CLIOptions.usage + "\n"
            FileHandle.standardError.write(Data(errorText.utf8))
            Foundation.exit(1)
        }
    }
}

private struct CLIOptions {
    let request: String
    let mode: AgentMode
    let model: String
    let maxSteps: Int
    let allowExternalSideEffects: Bool

    static let usage = """
    Usage:
      swift run fcp-ai-cli [options] "your editing request"

    Options:
      --mode observe|suggest|execute_safe|auto_edit
      --model MODEL_NAME
      --max-steps NUMBER
      --allow-external-side-effects

    Example:
      swift run fcp-ai-cli --mode execute_safe \\
        "Inspect the timeline, duplicate the project as Demo Interview — AI Cut 001, blade at frame 240, add a Review marker at frame 240, then verify the result."
    """

    static func parse(_ arguments: [String]) throws -> CLIOptions {
        var mode: AgentMode = .suggest
        var model = "qwen3:4b-instruct-2507-q4_K_M"
        var maxSteps = 8
        var allowExternalSideEffects = false
        var requestParts: [String] = []
        var index = 1

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--mode":
                index += 1
                guard index < arguments.count, let parsed = AgentMode(rawValue: arguments[index]) else {
                    throw CLIError.message("Invalid or missing --mode value.")
                }
                mode = parsed
            case "--model":
                index += 1
                guard index < arguments.count else { throw CLIError.message("Missing --model value.") }
                model = arguments[index]
            case "--max-steps":
                index += 1
                guard index < arguments.count, let parsed = Int(arguments[index]), parsed > 0 else {
                    throw CLIError.message("--max-steps must be a positive integer.")
                }
                maxSteps = parsed
            case "--allow-external-side-effects":
                allowExternalSideEffects = true
            case "--help", "-h":
                print(usage)
                Foundation.exit(0)
            default:
                requestParts.append(argument)
            }
            index += 1
        }

        guard !requestParts.isEmpty else {
            throw CLIError.message("An editing request is required.")
        }

        return CLIOptions(
            request: requestParts.joined(separator: " "),
            mode: mode,
            model: model,
            maxSteps: maxSteps,
            allowExternalSideEffects: allowExternalSideEffects
        )
    }
}

private enum CLIError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let value): return value
        }
    }
}
