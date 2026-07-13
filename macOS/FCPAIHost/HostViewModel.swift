import Foundation
import FCPAIKit

@MainActor
final class HostViewModel: ObservableObject {
    @Published var model = UserDefaults.standard.string(forKey: "model") ?? "qwen3:4b-instruct-2507-q4_K_M"
    @Published var baseURLText = UserDefaults.standard.string(forKey: "baseURL") ?? "http://127.0.0.1:11434"
    @Published var status = "Not checked"
    @Published var isChecking = false

    func saveAndCheck() {
        guard let baseURL = URL(string: baseURLText) else {
            status = "Invalid Ollama URL"
            return
        }

        UserDefaults.standard.set(model, forKey: "model")
        UserDefaults.standard.set(baseURLText, forKey: "baseURL")
        isChecking = true
        status = "Checking local runtime…"

        Task {
            let client = OllamaClient(baseURL: baseURL, model: model)
            let healthy = await client.healthCheck()
            isChecking = false
            status = healthy ? "Ollama is reachable" : "Ollama is not reachable"
        }
    }
}
