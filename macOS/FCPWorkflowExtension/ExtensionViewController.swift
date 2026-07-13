import Cocoa
import SwiftUI
import ProExtension
import ProExtensionHost

final class ExtensionViewController: NSViewController {
    private let viewModel = ExtensionViewModel()

    override func loadView() {
        let rootView = ExtensionRootView(viewModel: viewModel)
        self.view = NSHostingView(rootView: rootView)
        self.view.appearance = NSAppearance(named: .darkAqua)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (ProExtensionHostSingleton() as? FCPXHost)?.timeline.add(self)
    }

    deinit {
        (ProExtensionHostSingleton() as? FCPXHost)?.timeline.remove(self)
    }
}

extension ExtensionViewController: FCPXTimelineObserver {
    func activeSequenceChanged() {
        Task { @MainActor in viewModel.refreshTimeline() }
    }

    func playheadTimeChanged() {
        Task { @MainActor in viewModel.refreshTimeline() }
    }

    func sequenceTimeRangeChanged() {
        Task { @MainActor in viewModel.refreshTimeline() }
    }
}
