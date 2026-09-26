//
//  ImportPersistenceTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

struct ImportPersistenceTests {
    @Test func importIsAtomicAndRetryDoesNotDuplicate() async throws {
        let database = FinanceDatabase(inMemory: true)
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        try await database.saveImport(batch)
        let saved = try await database.load()
        #expect(saved.accounts == [batch.account])
        #expect(Set(saved.transactions.map(\.id)) == Set(batch.transactions.map(\.id)))
        #expect(saved.transactions.count == 2)
    }

    @Test func demoReplacementRequiresConsentAndPreservesDataOnFailure() async throws {
        let database = FinanceDatabase(inMemory: true)
        let demo = try await database.addDemo(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        await #expect(throws: ImportError.storageChanged) { try await database.saveImport(ImportFixtures.batch()) }
        #expect(try await database.load() == demo)
        let batch = try ImportFixtures.batch(replacingDemo: true)
        try await database.saveImport(batch)
        let result = try await database.load()
        #expect(result.accounts == [batch.account])
        #expect(result.transactions.allSatisfy { $0.source == .imported })
        #expect(result.transactions.count == 2)
    }

    @Test func invalidBatchCannotPartiallyInsertAnAccount() async throws {
        let database = FinanceDatabase(inMemory: true)
        let batch = ImportBatch(id: UUID(), sourceName: "empty.csv", importedAt: TestFixtures.date,
                                account: ImportFixtures.account, transactions: [], rowNumbers: [], replacingDemo: false)
        await #expect(throws: ImportError.emptySelection) { try await database.saveImport(batch) }
        #expect(try await database.load() == .empty)
    }

    @Test func migratesFoundationStoreAndPersistsImportReceipt() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        try createFoundationStore(at: url)
        let database = FinanceDatabase(storeURL: url)
        #expect(try await database.load().accounts == [ImportFixtures.account])
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        let reopened = FinanceDatabase(storeURL: url)
        try await reopened.saveImport(batch)
        #expect(try await reopened.load().transactions.count == 2)
    }

    @Test func rejectsAmountsThatWouldMakeSavedTotalsLosePrecision() async throws {
        let database = FinanceDatabase(inMemory: true)
        let original = try ImportFixtures.batch()
        try await database.saveImport(original)
        let document = try CSVParser().parse(
            "date,description,amount,currency,type\n2026-09-02,Huge,99999999999999999999999999999999999999,EUR,income",
            name: "precision.csv"
        )
        let candidates = try CSVImportService().preview(
            document: document, mapping: .suggested(for: document), account: original.account,
            existing: [], timeZone: .gmt
        ).candidates
        let batch = try ImportBatch(
            id: UUID(), sourceName: document.name, importedAt: TestFixtures.date, account: original.account,
            transactions: candidates.map { try $0.transaction(accountID: original.account.id) },
            rowNumbers: candidates.map(\.rowNumber), replacingDemo: false
        )
        await #expect(throws: ImportError.unsupportedTotals) { try await database.saveImport(batch) }
        #expect(try await database.load().transactions.count == original.transactions.count)
    }

    private func createFoundationStore(at url: URL) throws {
        let schema = Schema([AccountRecord.self, TransactionRecord.self], version: Schema.Version(1, 0, 0))
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        context.insert(AccountRecord(ImportFixtures.account))
        try context.save()
    }
}
