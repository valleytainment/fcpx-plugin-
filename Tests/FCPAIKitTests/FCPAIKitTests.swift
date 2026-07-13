import XCTest
@testable import FCPAIKit

final class FCPAIKitTests: XCTestCase {
    func testSuggestModeAllowsReadsButBlocksEdits() {
        let policy = AgentSafetyPolicy(mode: .suggest)
        XCTAssertTrue(policy.authorize(toolName: "fcp.get_timeline_state").allowed)
        XCTAssertFalse(policy.authorize(toolName: "timeline.blade").allowed)
    }

    func testExecuteSafeBlocksExportWithoutExplicitApproval() {
        let locked = AgentSafetyPolicy(mode: .executeSafe)
        XCTAssertFalse(locked.authorize(toolName: "project.export").allowed)

        let approved = AgentSafetyPolicy(mode: .executeSafe, allowExternalSideEffects: true)
        XCTAssertTrue(approved.authorize(toolName: "project.export").allowed)
    }

    func testMockAdapterRequiresDuplicateBeforeBlade() async throws {
        let adapter = MockFCPAdapter(initialState: TimelineState(projectName: "Original", durationFrames: 100))
        do {
            _ = try await adapter.execute(
                toolName: "timeline.blade",
                arguments: .object(["frame": .number(10)])
            )
            XCTFail("Expected blade precondition to fail.")
        } catch let error as FCPAdapterError {
            guard case .preconditionFailed = error else {
                return XCTFail("Wrong error: \(error)")
            }
        }
    }

    func testDuplicateBladeMarkerAndUndoFlow() async throws {
        let adapter = MockFCPAdapter(initialState: TimelineState(projectName: "Original", durationFrames: 100))

        _ = try await adapter.execute(
            toolName: "project.duplicate",
            arguments: .object(["new_name": .string("Original — AI Cut 001")])
        )
        _ = try await adapter.execute(
            toolName: "timeline.blade",
            arguments: .object(["frame": .number(10)])
        )
        _ = try await adapter.execute(
            toolName: "timeline.add_marker",
            arguments: .object(["frame": .number(10), "name": .string("Review")])
        )

        var state = await adapter.currentState()
        XCTAssertEqual(state.projectName, "Original — AI Cut 001")
        XCTAssertEqual(state.cuts, [10])
        XCTAssertEqual(state.markers, [TimelineMarker(frame: 10, name: "Review")])

        _ = try await adapter.execute(toolName: "project.undo", arguments: .object([:]))
        state = await adapter.currentState()
        XCTAssertTrue(state.markers.isEmpty)
        XCTAssertEqual(state.cuts, [10])
    }

    func testToolNamesAreUnique() {
        let names = FCPToolCatalog.definitions.map(\.function.name)
        XCTAssertEqual(Set(names).count, names.count)
    }
}
