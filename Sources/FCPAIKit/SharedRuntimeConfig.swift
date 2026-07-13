import Foundation

/// Shared runtime settings written by the installer and read by host + extension.
public struct SharedRuntimeConfig: Codable, Equatable, Sendable {
    public var ollamaBaseURL: String
    public var model: String

    public init(ollamaBaseURL: String = "http://127.0.0.1:11434", model: String = "qwen3:4b-instruct-2507-q4_K_M") {
        self.ollamaBaseURL = ollamaBaseURL
        self.model = model
    }

    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ValleytainmentFCPAI", isDirectory: true)
    }

    public static var defaultFileURL: URL {
        defaultDirectory.appendingPathComponent("runtime-config.json")
    }

    public static func load() -> SharedRuntimeConfig {
        let url = defaultFileURL
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(SharedRuntimeConfig.self, from: data) else {
            return SharedRuntimeConfig()
        }
        return config
    }

    public func save() throws {
        let directory = Self.defaultDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(self)
        try data.write(to: Self.defaultFileURL, options: .atomic)
    }
}
