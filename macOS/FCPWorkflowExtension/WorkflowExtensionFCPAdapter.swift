import Cocoa
import CoreMedia
import FCPAIKit
import ProExtensionHost

/// Phase 0 adapter: only Apple's public workflow-extension timeline surface.
/// Deep edit commands are intentionally not exposed here.
final class WorkflowExtensionFCPAdapter: @unchecked Sendable, FCPAdapter {
    func execute(toolName: String, arguments: JSONValue) async throws -> JSONValue {
        switch toolName {
        case "fcp.get_timeline_state":
            return try await MainActor.run { try readTimelineState() }
        case "timeline.move_playhead":
            return try await MainActor.run { try movePlayhead(arguments: arguments) }
        default:
            throw FCPAdapterError.unsupportedTool(
                "\(toolName) is not available through Apple's public workflow-extension timeline API in Phase 0."
            )
        }
    }

    @MainActor
    private func readTimelineState() throws -> JSONValue {
        guard let host = ProExtensionHostSingleton() as? FCPXHost else {
            throw FCPAdapterError.executionFailed("Final Cut Pro host is unavailable.")
        }
        guard let sequence = host.timeline.activeSequence else {
            throw FCPAdapterError.preconditionFailed("Open a project timeline in Final Cut Pro first.")
        }

        let frameDurationSeconds = CMTimeGetSeconds(sequence.frameDuration)
        let durationSeconds = CMTimeGetSeconds(sequence.duration)
        let frameRate = frameDurationSeconds > 0 ? 1.0 / frameDurationSeconds : 0
        let durationFrames = frameRate > 0 ? Int((durationSeconds * frameRate).rounded()) : 0
        let playheadSeconds = CMTimeGetSeconds(host.timeline.playheadTime())
        let playheadFrame = frameRate > 0 ? max(0, Int((playheadSeconds * frameRate).rounded())) : 0

        let state = TimelineState(
            projectName: sequence.name,
            frameRate: frameRate,
            durationFrames: durationFrames,
            playheadFrame: playheadFrame,
            markers: [],
            cuts: [],
            isDuplicate: false
        )
        return try JSONValue.fromEncodable(state)
    }

    @MainActor
    private func movePlayhead(arguments: JSONValue) throws -> JSONValue {
        guard let host = ProExtensionHostSingleton() as? FCPXHost else {
            throw FCPAdapterError.executionFailed("Final Cut Pro host is unavailable.")
        }
        guard let sequence = host.timeline.activeSequence else {
            throw FCPAdapterError.preconditionFailed("Open a project timeline in Final Cut Pro first.")
        }
        guard let object = arguments.objectValue,
              let frame = object["frame"]?.intValue else {
            throw FCPAdapterError.invalidArguments("timeline.move_playhead requires integer 'frame'.")
        }

        let frameDuration = sequence.frameDuration
        let target = CMTime(
            value: Int64(frame) * frameDuration.value,
            timescale: frameDuration.timescale
        )
        guard CMTimeCompare(target, .zero) >= 0,
              CMTimeCompare(target, sequence.duration) <= 0 else {
            throw FCPAdapterError.invalidArguments("Target frame is outside the active sequence.")
        }

        host.timeline.movePlayhead(to: target)
        return .object([
            "ok": .bool(true),
            "playhead_frame": .number(Double(frame))
        ])
    }
}
