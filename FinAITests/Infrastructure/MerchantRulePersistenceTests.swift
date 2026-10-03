//
//  MerchantRulePersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 02.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

struct MerchantRulePersistenceTests {
    @Test func migratesVersionTwoAndRulesSurviveReopeningWithoutChangingTransactions() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        let batch = try ImportFixtures.batch()
        try createVersionTwo(at: url, batch: batch)
        let database = FinanceDatabase(storeURL: url)
        let before = try await database.load()
        #expect(try await database.loadMerchantRules().isEmpty)
        var rule = MerchantRule(id: UUID(), pattern: "REWE", matchMode: .prefix, kind: .expense, merchant: "My REWE", category: .family)
        #expect(try await database.saveMerchantRule(rule, replacingExisting: false) == [rule])
        let reopened = FinanceDatabase(storeURL: url)
        #expect(try await reopened.loadMerchantRules() == [rule])
        let conflict = MerchantRule(id: UUID(), pattern: "rewe!", matchMode: .prefix, kind: .expense, merchant: "Other", category: .shopping)
        await #expect(throws: MerchantRule.RuleError.conflict) { try await reopened.saveMerchantRule(conflict, replacingExisting: false) }
        rule.category = .groceries
        #expect(try await reopened.saveMerchantRule(rule, replacingExisting: true) == [rule])
        try await reopened.saveImport(batch)
        #expect(try await reopened.load() == before)
        #expect(try await reopened.deleteMerchantRule(rule.id).isEmpty)
        #expect(try await FinanceDatabase(storeURL: url).loadMerchantRules().isEmpty)
        #expect(try await reopened.load() == before)
    }

    @Test func livePreviewLoadsRulesAndPreservesFinancialFields() async throws {
        let database = FinanceDatabase(inMemory: true)
        let rule = MerchantRule(id: UUID(), pattern: "REWE", matchMode: .prefix, kind: .expense, merchant: "My REWE", category: .family)
        _ = try await database.saveMerchantRule(rule, replacingExisting: false)
        let document = try CSVParser().parse("date,description,amount,currency,type\n2026-09-01,REWE MARKT 123,-12.50,EUR,expense", name: "rules.csv")
        let mapping = CSVMapping.suggested(for: document)
        let client = ImportClient.live(database: database)
        let preview = try await client.preview(document, mapping, ImportFixtures.account, [], .gmt)
        let candidate = try #require(preview.candidates.first)
        #expect(candidate.merchant == rule.merchant)
        #expect(candidate.category == .family)
        #expect(candidate.description == "REWE MARKT 123")
        #expect(candidate.kind == .expense)
        #expect(candidate.money.amount == Decimal(string: "12.50"))
        #expect(candidate.money.currency == .eur)
        #expect(try await database.load() == .empty)
    }

    @Test func failedValidationAndMissingEditDoNotInsertRules() async throws {
        let database = FinanceDatabase(inMemory: true)
        var rule = MerchantRule(id: UUID(), pattern: "Shop", matchMode: .exact, kind: .expense, merchant: "Shop", category: .shopping)
        await #expect(throws: MerchantRule.RuleError.missing) { try await database.saveMerchantRule(rule, replacingExisting: true) }
        rule.merchant = " "
        await #expect(throws: MerchantRule.RuleError.invalid) { try await database.saveMerchantRule(rule, replacingExisting: false) }
        #expect(try await database.loadMerchantRules().isEmpty)
    }

    private func createVersionTwo(at url: URL, batch: ImportBatch) throws {
        let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self], version: Schema.Version(2, 0, 0))
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        context.insert(AccountRecord(batch.account))
        for transaction in batch.transactions { context.insert(TransactionRecord(transaction)) }
        context.insert(ImportSessionRecord(batch))
        try context.save()
    }
}
