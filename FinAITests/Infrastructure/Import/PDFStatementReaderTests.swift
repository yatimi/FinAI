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
    @Test func restoresSeparateAmountColumnsBeforeParsing() throws {
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)).pdfData { context in
            context.beginPage()
            let rows: [(String, CGFloat)] = [
                ("Example Sparkasse", 30),
                ("Kontoauszug 1/2026", 60),
                ("GiroOnline 0000000000, DE00 0000 0000 0000 0000 00", 90),
                ("Datum Erläuterung Betrag EUR", 120),
                ("Kontostand am 31.08.2026, Auszug Nr. 0", 150),
                ("01.09.2026Basis-Lastschr.einlös", 180),
                ("Test merchant", 200),
                ("02.09.2026Gutschrift Überw.", 230),
                ("Test employer", 250),
                ("Kontostand am 30.09.2026 um 20:00 Uhr", 280),
                ("Postanschrift: Example bank", 320)
            ]
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
            // Write the description column first and the amounts later, while keeping
            // the visual rows aligned. Text stream order must not determine pairing.
            for (text, y) in rows {
                (text as NSString).draw(at: CGPoint(x: 30, y: y), withAttributes: attributes)
            }
            for (text, y) in [("Seite 1 von 1", CGFloat(60)), ("100,00", 150), ("-5,00", 180), ("20,00", 230), ("115,00", 280)] {
                (text as NSString).draw(at: CGPoint(x: 470, y: y), withAttributes: attributes)
            }
        }
        let pages = try PDFStatementReader().extractPages(data)
        let result = try SparkasseStatementParser().parse(pages: pages, name: "Synthetic columns.pdf")
        #expect(result.entries.map(\.signedAmount) == [-5, 20])
        #expect(result.entries.map(\.payeeDescription) == ["Test merchant", "Test employer"])
        #expect(result.entries.map(\.kind) == [.expense, .unknown])
    }

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
