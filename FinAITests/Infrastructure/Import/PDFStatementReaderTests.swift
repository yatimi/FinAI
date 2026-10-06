//
//  PDFStatementReaderTests.swift
//  FinAITests
//
//  Created by Tommy on 06.10.26.
//

import Foundation
import PDFKit
import Testing
import UIKit
@testable import FinAI

struct PDFStatementReaderTests {
    @MainActor
    @Test func readsSyntheticPDFThroughTheFileBoundary() async throws {
        let data = pdf(pages: [StatementFixtures.page(StatementFixtures.body)])
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".PDF")
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        let result = try await PDFStatementReader().read(url)
        #expect(result.entries.count == 5)
        #expect(result.name == url.lastPathComponent)
    }

    @MainActor
    @Test func refusesLockedAndImageOnlyPDFs() throws {
        let data = pdf(pages: ["Selectable text"])
        let document = try #require(PDFDocument(data: data))
        let locked = try #require(document.dataRepresentation(options: [PDFDocumentWriteOption.userPasswordOption: "test-password", PDFDocumentWriteOption.ownerPasswordOption: "owner-password"]))
        #expect(throws: ImportError.lockedPDF) { try PDFStatementReader().extractPages(locked) }
        let blank = pdf(pages: [""])
        #expect(throws: ImportError.pdfNeedsText) { try PDFStatementReader().extractPages(blank) }
        let mixed = pdf(pages: ["Selectable text", ""])
        #expect(throws: ImportError.pdfNeedsText) { try PDFStatementReader().extractPages(mixed) }
    }

    @Test func rejectsCorruptAndOversizedData() {
        #expect(throws: ImportError.unreadableFile) { try PDFStatementReader().extractPages(Data("not a PDF".utf8)) }
        #expect(throws: ImportError.pdfTooLarge) {
            try PDFStatementReader().extractPages(Data(repeating: 0, count: PDFStatementReader.maximumBytes + 1))
        }
    }

    @MainActor
    @Test func refusesTooManyPages() {
        let data = pdf(pages: Array(repeating: "Text", count: PDFStatementReader.maximumPages + 1))
        #expect(throws: ImportError.pdfTooLarge) { try PDFStatementReader().extractPages(data) }
    }

    @Test func cancellationStopsBeforeReading() async throws {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await PDFStatementReader().read(URL(fileURLWithPath: "/missing.pdf"))
        }
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @MainActor
    private func pdf(pages: [String]) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)).pdfData { context in
            for text in pages {
                context.beginPage()
                (text as NSString).draw(in: CGRect(x: 30, y: 30, width: 535, height: 782), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            }
        }
    }
}
