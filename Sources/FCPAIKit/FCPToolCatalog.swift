import Foundation

public struct FCPToolSpec: Equatable, Sendable {
    public let definition: OllamaToolDefinition
    public let risk: ToolRisk

    public init(definition: OllamaToolDefinition, risk: ToolRisk) {
        self.definition = definition
        self.risk = risk
    }
}

public enum FCPToolCatalog {
    public static let specs: [FCPToolSpec] = [
        spec(
            name: "fcp.get_timeline_state",
            description: "Read the active Final Cut Pro project and timeline state before making decisions.",
            risk: .readOnly,
            properties: [:],
            required: []
        ),
        spec(
            name: "project.duplicate",
            description: "Duplicate the active project to create a reversible AI working copy. Use this before multi-step timeline edits.",
            risk: .reversibleEdit,
            properties: [
                "new_name": schema(type: "string", description: "Name for the duplicated project.")
            ],
            required: ["new_name"]
        ),
        spec(
            name: "timeline.move_playhead",
            description: "Move the Final Cut Pro playhead to an exact zero-based frame number.",
            risk: .reversibleEdit,
            properties: [
                "frame": schema(type: "integer", description: "Target frame within the active timeline.")
            ],
            required: ["frame"]
        ),
        spec(
            name: "timeline.add_marker",
            description: "Add a named marker at an exact zero-based frame number.",
            risk: .reversibleEdit,
            properties: [
                "frame": schema(type: "integer", description: "Marker frame within the active timeline."),
                "name": schema(type: "string", description: "Clear marker label.")
            ],
            required: ["frame", "name"]
        ),
        spec(
            name: "timeline.blade",
            description: "Blade the primary storyline at an exact frame. The active project must already be an AI duplicate.",
            risk: .reversibleEdit,
            properties: [
                "frame": schema(type: "integer", description: "Cut frame within the active timeline.")
            ],
            required: ["frame"]
        ),
        spec(
            name: "project.undo",
            description: "Undo the most recent reversible operation in the active Final Cut Pro project.",
            risk: .reversibleEdit,
            properties: [:],
            required: []
        ),
        spec(
            name: "project.export",
            description: "Export the active project to an explicitly provided destination. Requires external-side-effect approval.",
            risk: .externalSideEffect,
            properties: [
                "destination": schema(type: "string", description: "Absolute output file path."),
                "preset": schema(type: "string", description: "Named Final Cut Pro export preset.")
            ],
            required: ["destination", "preset"]
        )
    ]

    public static var definitions: [OllamaToolDefinition] {
        specs.map(\.definition)
    }

    public static func definitions(named names: Set<String>) -> [OllamaToolDefinition] {
        specs
            .filter { names.contains($0.definition.function.name) }
            .map(\.definition)
    }

    public static func risk(for toolName: String) -> ToolRisk? {
        specs.first(where: { $0.definition.function.name == toolName })?.risk
    }

    private static func spec(
        name: String,
        description: String,
        risk: ToolRisk,
        properties: [String: JSONValue],
        required: [String]
    ) -> FCPToolSpec {
        let parameters: JSONValue = .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object(properties),
            "required": .array(required.map(JSONValue.string))
        ])
        return FCPToolSpec(
            definition: OllamaToolDefinition(
                function: OllamaFunctionDefinition(
                    name: name,
                    description: description,
                    parameters: parameters
                )
            ),
            risk: risk
        )
    }

    private static func schema(type: String, description: String) -> JSONValue {
        .object([
            "type": .string(type),
            "description": .string(description)
        ])
    }
}
