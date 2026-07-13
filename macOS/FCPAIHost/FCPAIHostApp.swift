import SwiftUI

@main
struct FCPAIHostApp: App {
    @StateObject private var viewModel = HostViewModel()

    var body: some Scene {
        WindowGroup("Valleytainment FCP AI") {
            HostView(viewModel: viewModel)
                .frame(minWidth: 620, minHeight: 460)
        }
        .windowResizability(.contentMinSize)
    }
}
