import Foundation

public actor ArtifactJournal {
    private let directory: URL?
    private var records: [ToolExecutionRecord] = []

    public init(directory: URL? = nil) {
        self.directory = directory
    }

    public func append(_ record: ToolExecutionRecord) async {
        records.append(record)
        guard let directory else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let filename = String(format: "%04d-%@.json", records.count, sanitize(record.toolName))
            let url = directory.appendingPathComponent(filename)
            try JSONEncoder.pretty.encode(record).write(to: url, options: .atomic)
        } catch {
            // Journaling must not crash the edit loop. The caller still receives the tool result.
        }
    }

    public func allRecords() -> [ToolExecutionRecord] {
        records
    }

    private func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: ".", with: "-")
    }
}
