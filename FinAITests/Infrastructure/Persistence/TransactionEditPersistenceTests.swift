//
//  TransactionEditPersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 07.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

struct TransactionEditPersistenceTests {
    @Test func editsSurviveReopenPreserveOriginalsAndImportRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        let database = FinanceDatabase(storeURL: url)
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        let expected = try #require(batch.transactions.first)
        let replacement = try edited(expected)
        _ = try await database.editTransaction(expected: expected, replacement: replacement, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let reopened = FinanceDatabase(storeURL: url)
        let saved = try await reopened.load()
        #expect(saved.transactions.first { $0.id == expected.id } == replacement)
        #expect(saved.originals[expected.id] == expected)
        try await reopened.saveImport(batch)
        #expect(try await reopened.load() == saved)
        let preview = try ImportPreviewService().review(candidates: [ImportCandidate(
            id: UUID(), rowNumber: 2, date: expected.date, description: expected.rawDescription,
            money: expected.money, direction: expected.direction, merchant: expected.merchant, kind: expected.kind, category: expected.category
        )], account: batch.account, existing: saved.originalTransactions, timeZone: .gmt)
        #expect(preview.candidates.first?.duplicateMatches.first?.reason == .exact)
        await #expect(throws: TransactionEditError.storageChanged) {
            try await reopened.editTransaction(expected: expected, replacement: replacement, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        #expect(try await reopened.load() == saved)
    }

    @Test func cancelledCorrectionDoesNotMutateData() async throws {
        let database = FinanceDatabase(inMemory: true)
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        let before = try await database.load()
        let expected = try #require(before.transactions.first)
        let replacement = try edited(expected)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                withUnsafeCurrentTask { $0?.cancel() }
                await #expect(throws: CancellationError.self) {
                    try await database.editTransaction(expected: expected, replacement: replacement, date: TestFixtures.date, calendar: TestFixtures.calendar)
                }
            }
        }
        #expect(try await database.load() == before)
    }

    @Test func failedSaveRollsBackCorrectionAndOriginalSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        let database = FinanceDatabase(storeURL: url)
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        let before = try await database.load()
        let expected = try #require(before.transactions.first)
        let replacement = try edited(expected)
        let schema = try FinanceStoreConfiguration(storeURL: url).makeContainer().schema
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, allowsSave: false, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        #expect(throws: (any Error).self) {
            try TransactionEditStore().save(expected: expected, replacement: replacement, date: TestFixtures.date, calendar: TestFixtures.calendar, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try FinanceSnapshotStore().load(in: ModelContext(container)) == before)
    }

    @Test func migrationFromActualVersionThreePreservesRecordsAndReceipts() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        let batch = try ImportFixtures.batch()
        try createVersionThree(at: url, batch: batch)
        let database = FinanceDatabase(storeURL: url)
        let before = try await database.load()
        #expect(before.originals.isEmpty)
        #expect(before.transactions.sorted { $0.id.uuidString < $1.id.uuidString } == batch.transactions.sorted { $0.id.uuidString < $1.id.uuidString })
        let expected = try #require(before.transactions.first)
        _ = try await database.editTransaction(expected: expected, replacement: edited(expected), date: TestFixtures.date, calendar: TestFixtures.calendar)
        try await FinanceDatabase(storeURL: url).saveImport(batch)
        #expect(try await FinanceDatabase(storeURL: url).load().originals[expected.id] == expected)
    }

    @Test func concurrentCorrectionsCannotSilentlyOverwriteEachOther() async throws {
        let database = FinanceDatabase(inMemory: true)
        let batch = try ImportFixtures.batch()
        try await database.saveImport(batch)
        let expected = try #require(batch.transactions.first)
        let replacement = try edited(expected)
        let successes = try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<2 {
                group.addTask {
                    do {
                        _ = try await database.editTransaction(expected: expected, replacement: replacement, date: TestFixtures.date, calendar: TestFixtures.calendar)
                        return true
                    } catch TransactionEditError.storageChanged { return false }
                }
            }
            var count = 0
            for try await success in group where success { count += 1 }
            return count
        }
        #expect(successes == 1)
        #expect(try await database.load().originals[expected.id] == expected)
    }

    @Test func originalSnapshotPreservesHighPrecisionMoney() async throws {
        let database = FinanceDatabase(inMemory: true)
        let amount = try #require(Decimal(string: "12345678901234567890.123456789012345678"))
        let original = try Transaction(id: UUID(), accountID: ImportFixtures.account.id, date: TestFixtures.date,
            merchant: "Original", rawDescription: "Original statement", money: Money(amount: amount, currency: .eur),
            direction: .debit, kind: .expense, category: .other, source: .imported)
        let batch = ImportBatch(id: UUID(), sourceName: "precision.csv", importedAt: TestFixtures.date, account: ImportFixtures.account,
            transactions: [original], rowNumbers: [2], replacingDemo: false)
        try await database.saveImport(batch)
        _ = try await database.editTransaction(expected: original, replacement: edited(original), date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(try await database.load().originals[original.id] == original)
    }

    private func createVersionThree(at url: URL, batch: ImportBatch) throws {
        let schema = Schema([AccountRecord.self, LegacyTransactionSchema.TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self], version: Schema.Version(3, 0, 0))
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        context.insert(AccountRecord(batch.account))
        for transaction in batch.transactions { context.insert(LegacyTransactionSchema.TransactionRecord(transaction)) }
        context.insert(ImportSessionRecord(batch))
        try context.save()
    }

    private func edited(_ transaction: Transaction) throws -> Transaction {
        var draft = TransactionEditDraft(transaction: transaction, locale: Locale(identifier: "en_US"))
        draft.merchant = "Edited merchant"
        draft.amount = "123.456789123456789"
        draft.date = transaction.date.addingTimeInterval(86400)
        draft.currencyCode = "USD"
        return try draft.transaction(replacing: transaction, locale: Locale(identifier: "en_US"))
    }
}
