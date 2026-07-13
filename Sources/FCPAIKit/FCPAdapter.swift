import Foundation

public enum FCPAdapterError: Error, CustomStringConvertible, Sendable {
    case unsupportedTool(String)
    case invalidArguments(String)
    case preconditionFailed(String)
    case executionFailed(String)

    public var description: String {
        switch self {
        case .unsupportedTool(let tool): return "Unsupported tool: \(tool)"
        case .invalidArguments(let details): return "Invalid arguments: \(details)"
        case .preconditionFailed(let details): return "Precondition failed: \(details)"
        case .executionFailed(let details): return "Execution failed: \(details)"
        }
    }
}

public protocol FCPAdapter: Sendable {
    func execute(toolName: String, arguments: JSONValue) async throws -> JSONValue
}

extension Dictionary where Key == String, Value == JSONValue {
    func requiredString(_ key: String) throws -> String {
        guard let value = self[key]?.stringValue, !value.isEmpty else {
            throw FCPAdapterError.invalidArguments("Missing non-empty string '\(key)'.")
        }
        return value
    }

    func requiredInt(_ key: String) throws -> Int {
        guard let value = self[key]?.intValue else {
            throw FCPAdapterError.invalidArguments("Missing integer '\(key)'.")
        }
        return value
    }
}
