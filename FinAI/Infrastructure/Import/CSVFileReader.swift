//
//  CSVFileReader.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CSVFileReader: Sendable {
    @concurrent
    func read(_ url: URL) async throws -> CSVDocument {
        try Task.checkCancellation()
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<CSVDocument, any Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { coordinatedURL in
            result = Result {
                let handle = try FileHandle(forReadingFrom: coordinatedURL)
                defer { try? handle.close() }
                var data = Data()
                while let chunk = try handle.read(upToCount: 64 * 1024), !chunk.isEmpty {
                    try Task.checkCancellation()
                    data.append(chunk)
                    guard data.count <= CSVParser.maximumBytes else { throw ImportError.fileTooLarge }
                }
                let encoding: String.Encoding = data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) ? .utf16 : .utf8
                guard let text = String(data: data, encoding: encoding) else { throw ImportError.unsupportedEncoding }
                return try CSVParser().parse(text, name: url.lastPathComponent)
            }
        }
        if let result { return try result.get() }
        throw ImportError.unreadableFile
    }
}
