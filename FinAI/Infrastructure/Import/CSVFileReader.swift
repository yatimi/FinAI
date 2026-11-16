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
        let data = try ImportFileDataReader().read(url, maximumBytes: CSVParser.maximumBytes, sizeError: .fileTooLarge)
        let encoding: String.Encoding = data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) ? .utf16 : .utf8
        guard let text = String(data: data, encoding: encoding) else { throw ImportError.unsupportedEncoding }
        return try CSVParser().parse(text, name: url.lastPathComponent)
    }
}
