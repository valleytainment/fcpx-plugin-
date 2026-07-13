import Foundation

public actor MockFCPAdapter: FCPAdapter {
    private var state: TimelineState
    private var undoStack: [TimelineState] = []

    public init(initialState: TimelineState = TimelineState(projectName: "Demo Project")) {
        self.state = initialState
    }

    public func currentState() -> TimelineState {
        state
    }

    public func execute(toolName: String, arguments: JSONValue) async throws -> JSONValue {
        let object = arguments.objectValue ?? [:]

        switch toolName {
        case "fcp.get_timeline_state":
            return try JSONValue.fromEncodable(state)

        case "project.duplicate":
            let newName = try object.requiredString("new_name")
            checkpoint()
            let originalName = state.projectName
            state.sourceProjectName = state.sourceProjectName ?? originalName
            state.projectName = newName
            state.isDuplicate = true
            return .object([
                "ok": .bool(true),
                "project_name": .string(state.projectName),
                "source_project_name": .string(originalName),
                "is_duplicate": .bool(true)
            ])

        case "timeline.move_playhead":
            let frame = try validatedFrame(object.requiredInt("frame"), allowEnd: true)
            checkpoint()
            state.playheadFrame = frame
            return .object(["ok": .bool(true), "playhead_frame": .number(Double(frame))])

        case "timeline.add_marker":
            let frame = try validatedFrame(object.requiredInt("frame"), allowEnd: false)
            let name = try object.requiredString("name")
            checkpoint()
            state.markers.append(TimelineMarker(frame: frame, name: name))
            state.markers.sort { $0.frame < $1.frame }
            return .object([
                "ok": .bool(true),
                "marker_count": .number(Double(state.markers.count))
            ])

        case "timeline.blade":
            guard state.isDuplicate else {
                throw FCPAdapterError.preconditionFailed("Blade operations are blocked until project.duplicate succeeds.")
            }
            let frame = try validatedFrame(object.requiredInt("frame"), allowEnd: false)
            checkpoint()
            if !state.cuts.contains(frame) {
                state.cuts.append(frame)
                state.cuts.sort()
            }
            return .object([
                "ok": .bool(true),
                "cut_frame": .number(Double(frame)),
                "cut_count": .number(Double(state.cuts.count))
            ])

        case "project.undo":
            guard let previous = undoStack.popLast() else {
                throw FCPAdapterError.preconditionFailed("There is no mock operation to undo.")
            }
            state = previous
            return .object(["ok": .bool(true), "restored_project": .string(state.projectName)])

        case "project.export":
            let destination = try object.requiredString("destination")
            let preset = try object.requiredString("preset")
            return .object([
                "ok": .bool(true),
                "simulated": .bool(true),
                "destination": .string(destination),
                "preset": .string(preset)
            ])

        default:
            throw FCPAdapterError.unsupportedTool(toolName)
        }
    }

    private func checkpoint() {
        undoStack.append(state)
    }

    private func validatedFrame(_ frame: Int, allowEnd: Bool) throws -> Int {
        let upperBound = allowEnd ? state.durationFrames : max(0, state.durationFrames - 1)
        guard frame >= 0, frame <= upperBound else {
            throw FCPAdapterError.invalidArguments("Frame \(frame) is outside 0...\(upperBound).")
        }
        return frame
    }
}
