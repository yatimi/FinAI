//
//  ImportFileDataReader.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import Foundation

struct ImportFileDataReader: Sendable {
    func read(_ url: URL, maximumBytes: Int, sizeError: ImportError) throws -> Data {
        try Task.checkCancellation()
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<Data, any Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { coordinatedURL in
            result = Result {
                let handle = try FileHandle(forReadingFrom: coordinatedURL)
                defer { try? handle.close() }
                var data = Data()
                while let chunk = try handle.read(upToCount: 64 * 1024), !chunk.isEmpty {
                    try Task.checkCancellation()
                    data.append(chunk)
                    guard data.count <= maximumBytes else { throw sizeError }
                }
                try Task.checkCancellation()
                return data
            }
        }
        if let result { return try result.get() }
        throw ImportError.unreadableFile
    }
}
