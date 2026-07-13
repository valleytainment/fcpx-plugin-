import Foundation
import FCPAIKit

@MainActor
final class HostViewModel: ObservableObject {
    @Published var model = SharedRuntimeConfig.load().model
    @Published var baseURLText = SharedRuntimeConfig.load().ollamaBaseURL
    @Published var status = "Not checked"
    @Published var isChecking = false

    func saveAndCheck() {
        guard let baseURL = URL(string: baseURLText) else {
            status = "Invalid Ollama URL"
            return
        }

        UserDefaults.standard.set(model, forKey: "model")
        UserDefaults.standard.set(baseURLText, forKey: "baseURL")
        try? SharedRuntimeConfig(ollamaBaseURL: baseURLText, model: model).save()
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
