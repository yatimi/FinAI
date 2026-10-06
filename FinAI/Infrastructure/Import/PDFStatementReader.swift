//
//  PDFStatementReader.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import Foundation
import PDFKit

struct PDFStatementReader: Sendable {
    static let maximumBytes = 10 * 1024 * 1024
    static let maximumPages = 100
    static let maximumTextBytes = 2 * 1024 * 1024

    @concurrent
    func read(_ url: URL) async throws -> StatementDocument {
        let data = try ImportFileDataReader().read(url, maximumBytes: Self.maximumBytes, sizeError: .pdfTooLarge)
        let pages = try extractPages(data)
        return try SparkasseStatementParser().parse(pages: pages, name: url.lastPathComponent)
    }

    func extractPages(_ data: Data) throws -> [String] {
        try Task.checkCancellation()
        guard data.count <= Self.maximumBytes else { throw ImportError.pdfTooLarge }
        guard let document = PDFDocument(data: data) else { throw ImportError.unreadableFile }
        guard !document.isLocked else { throw ImportError.lockedPDF }
        guard document.pageCount > 0, document.pageCount <= Self.maximumPages else { throw ImportError.pdfTooLarge }
        var pages: [String] = []
        var totalBytes = 0
        for index in 0..<document.pageCount {
            try Task.checkCancellation()
            guard let text = document.page(at: index)?.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ImportError.pdfNeedsText
            }
            totalBytes += text.utf8.count
            guard totalBytes <= Self.maximumTextBytes else { throw ImportError.pdfTooLarge }
            pages.append(text)
        }
        try Task.checkCancellation()
        return pages
    }
}
