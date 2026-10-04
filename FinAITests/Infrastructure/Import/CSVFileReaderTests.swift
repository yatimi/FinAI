//
//  CSVFileReaderTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct CSVFileReaderTests {
    @Test(arguments: [String.Encoding.utf8, .utf16])
    func readsSupportedEncodings(encoding: String.Encoding) async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".csv")
        defer { try? FileManager.default.removeItem(at: url) }
        try #require(ImportFixtures.csv.data(using: encoding)).write(to: url)
        let result = try await CSVFileReader().read(url)
        #expect(result.rows.count == 3)
        #expect(result.name == url.lastPathComponent)
    }

    @Test func rejectsUnsupportedEncoding() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".csv")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0xFF]).write(to: url)
        await #expect(throws: ImportError.unsupportedEncoding) { try await CSVFileReader().read(url) }
    }
}
