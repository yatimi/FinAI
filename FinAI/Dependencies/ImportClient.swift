//
//  ImportClient.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct ImportClient: Sendable {
    var readFile: @Sendable (URL) async throws -> CSVDocument
    var preview: @Sendable (CSVDocument, CSVMapping, Account, [Transaction], TimeZone) async throws -> ImportPreview
    var save: @Sendable (ImportBatch) async throws -> Void

    static func live(database: FinanceDatabase) -> Self {
        Self(
            readFile: { try await CSVFileReader().read($0) },
            preview: { document, mapping, account, existing, timeZone in
                let rules = try await database.loadMerchantRules()
                return try await makePreview(document: document, mapping: mapping, account: account, existing: existing, timeZone: timeZone, rules: rules)
            },
            save: { try await database.saveImport($0) }
        )
    }

    @concurrent
    private static func makePreview(
        document: CSVDocument, mapping: CSVMapping, account: Account, existing: [Transaction], timeZone: TimeZone, rules: [MerchantRule]
    ) async throws -> ImportPreview {
        try CSVImportService(classification: TransactionClassificationService(rules: rules)).preview(document: document, mapping: mapping, account: account, existing: existing, timeZone: timeZone)
    }
}

extension ImportClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var importClient: ImportClient {
        get { self[ImportClient.self] }
        set { self[ImportClient.self] = newValue }
    }
}
