import SwiftUI
import FCPAIKit

struct ExtensionRootView: View {
    @ObservedObject var viewModel: ExtensionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FCP AI Operator")
                        .font(.title2.bold())
                    Text(viewModel.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") {
                    viewModel.refreshTimeline()
                }
            }

            Picker("Mode", selection: $viewModel.mode) {
                Text("Observe").tag(AgentMode.observe)
                Text("Suggest").tag(AgentMode.suggest)
                Text("Execute Safe").tag(AgentMode.executeSafe)
            }
            .pickerStyle(.segmented)

            GroupBox("Active timeline") {
                ScrollView {
                    Text(viewModel.timelineSummary)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 90, maxHeight: 150)
            }

            TextEditor(text: $viewModel.prompt)
                .font(.body)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))

            HStack {
                Button("Run local Qwen") {
                    viewModel.runAgent()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(viewModel.isRunning)

                if viewModel.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            GroupBox("Result") {
                ScrollView {
                    Text(viewModel.response.isEmpty ? "The agent response will appear here." : viewModel.response)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 560)
        .task {
            viewModel.refreshTimeline()
        }
    }
}
