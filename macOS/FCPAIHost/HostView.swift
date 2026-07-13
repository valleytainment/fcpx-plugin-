import SwiftUI

struct HostView: View {
    @ObservedObject var viewModel: HostViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Valleytainment FCP AI")
                    .font(.largeTitle.bold())
                Text("Local Qwen control plane for Final Cut Pro")
                    .foregroundStyle(.secondary)
            }

            GroupBox("Local model runtime") {
                Form {
                    TextField("Ollama URL", text: $viewModel.baseURLText)
                    TextField("Model", text: $viewModel.model)
                }
            }

            HStack {
                Button("Save and test") {
                    viewModel.saveAndCheck()
                }
                .disabled(viewModel.isChecking)

                if viewModel.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(viewModel.status)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Install the workflow extension")
                    .font(.headline)
                Text("Build the host and Final Cut Pro Workflow Extension targets, copy the signed host app to /Applications, reopen Final Cut Pro, then open it from Window → Extensions.")
                Text("The Phase 0 extension can read the active timeline and move the playhead through Apple's public SDK. Deep editing commands remain locked until the CommandPost/Accessibility adapter is added.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
    }
}
