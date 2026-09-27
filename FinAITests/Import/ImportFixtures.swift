//
//  ImportFixtures.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
@testable import FinAI

enum ImportFixtures {
    static let csv = "date,description,amount,currency,type\n2026-09-01,Test coffee,-12.50,EUR,expense\n2026-09-02,Test employer,1000,EUR,income\n2026-09-03,Invalid,bad,EUR,expense\n"
    static let account = Account(id: UUID(), name: "Test bank", kind: .bank, currency: .eur)
    static func document() throws -> CSVDocument { try CSVParser().parse(csv, name: "sample.csv") }
    static func preview() throws -> ImportPreview {
        let document = try document()
        return try CSVImportService().preview(document: document, mapping: .suggested(for: document), account: account, existing: [], timeZone: .gmt)
    }
    static func batch(replacingDemo: Bool = false) throws -> ImportBatch {
        let candidates = try preview().candidates
        return try ImportBatch(
            id: UUID(), sourceName: "sample.csv", importedAt: TestFixtures.date, account: account,
            transactions: candidates.map { try $0.transaction(accountID: account.id) }, rowNumbers: candidates.map(\.rowNumber),
            replacingDemo: replacingDemo
        )
    }
}
