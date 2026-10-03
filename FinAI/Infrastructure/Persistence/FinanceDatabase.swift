//
//  FinanceDatabase.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData

actor FinanceDatabase {
    private let inMemory: Bool
    private let storeURL: URL?
    private var container: ModelContainer?

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        self.inMemory = inMemory
        self.storeURL = storeURL
    }

    func load() throws -> FinanceSnapshot {
        try Task.checkCancellation()
        return try snapshot(in: makeContext())
    }

    /// Seeds only an empty store. Repeat requests and relaunches cannot duplicate demo records.
    func addDemo(referenceDate: Date, calendar: Calendar) throws -> FinanceSnapshot {
        try Task.checkCancellation()
        let context = try makeContext()
        let existing = try snapshot(in: context)
        guard existing.accounts.isEmpty && existing.transactions.isEmpty else { return existing }
        let demo = try DemoData().make(referenceDate: referenceDate, calendar: calendar)
        try demo.validate()
        do {
            for account in demo.accounts { context.insert(AccountRecord(account)) }
            for transaction in demo.transactions { context.insert(TransactionRecord(transaction)) }
            try Task.checkCancellation()
            try context.save()
            return try snapshot(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// The session receipt and transactions are committed together, making a retry safe.
    func saveImport(_ batch: ImportBatch) throws {
        try Task.checkCancellation()
        try batch.validate()
        let context = try makeContext()
        let existing = try snapshot(in: context)
        let batchID = batch.id
        let receipt = try context.fetch(FetchDescriptor<ImportSessionRecord>(predicate: #Predicate { $0.id == batchID })).first
        if let receipt {
            let existingByID = Dictionary(uniqueKeysWithValues: existing.transactions.map { ($0.id, $0) })
            guard receipt.transactionIDs == batch.transactions.map(\.id),
                  receipt.accountID == batch.account.id,
                  receipt.sourceName == batch.sourceName,
                  receipt.rowNumbers == batch.rowNumbers,
                  batch.transactions.allSatisfy({ existingByID[$0.id] == $0 }) else { throw ImportError.storageChanged }
            return
        }
        let demoTransactions = existing.transactions.filter { $0.source == .demo }
        guard demoTransactions.isEmpty || batch.replacingDemo else { throw ImportError.storageChanged }
        let demoAccountIDs = Set(demoTransactions.map(\.accountID))
        let realAccountIDs = Set(existing.transactions.filter { $0.source != .demo }.map(\.accountID))
        let removedAccountIDs = demoAccountIDs.subtracting(realAccountIDs)
        guard !removedAccountIDs.contains(batch.account.id) else { throw ImportError.invalidAccount }
        if let account = existing.accounts.first(where: { $0.id == batch.account.id }), account != batch.account {
            throw ImportError.storageChanged
        }
        let existingIDs = Set(existing.transactions.map(\.id))
        guard batch.transactions.allSatisfy({ !existingIDs.contains($0.id) }) else { throw ImportError.storageChanged }
        try batch.validate(existingTransactions: existing.transactions.filter { !batch.replacingDemo || $0.source != .demo })
        do {
            if batch.replacingDemo {
                for record in try context.fetch(FetchDescriptor<TransactionRecord>()) where record.source == Transaction.Source.demo.rawValue {
                    context.delete(record)
                }
                for record in try context.fetch(FetchDescriptor<AccountRecord>()) where removedAccountIDs.contains(record.id) {
                    context.delete(record)
                }
            }
            if !existing.accounts.contains(where: { $0.id == batch.account.id }) { context.insert(AccountRecord(batch.account)) }
            for transaction in batch.transactions {
                try Task.checkCancellation()
                context.insert(TransactionRecord(transaction))
            }
            context.insert(ImportSessionRecord(batch))
            try Task.checkCancellation()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func loadMerchantRules() throws -> [MerchantRule] {
        try Task.checkCancellation()
        return try makeContext().fetch(FetchDescriptor<MerchantRuleRecord>(sortBy: [SortDescriptor(\.pattern)]))
            .map { try $0.domainValue() }
    }

    func saveMerchantRule(_ rule: MerchantRule, replacingExisting: Bool) throws -> [MerchantRule] {
        try Task.checkCancellation()
        try rule.validate()
        let context = try makeContext()
        let records = try context.fetch(FetchDescriptor<MerchantRuleRecord>())
        let existing = records.first { $0.id == rule.id }
        guard !replacingExisting || existing != nil else { throw MerchantRule.RuleError.missing }
        guard replacingExisting || existing == nil else { throw MerchantRule.RuleError.conflict }
        let otherRules = try records.filter { $0.id != rule.id }.map { try $0.domainValue() }
        guard !otherRules.contains(where: { rule.conflicts(with: $0) }) else { throw MerchantRule.RuleError.conflict }
        let result = (otherRules + [rule]).sorted { $0.pattern < $1.pattern }
        do {
            if let existing {
                existing.pattern = rule.pattern
                existing.matchMode = rule.matchMode.rawValue
                existing.kind = rule.kind.rawValue
                existing.merchant = rule.merchant
                existing.category = rule.category.rawValue
            } else { context.insert(MerchantRuleRecord(rule)) }
            try Task.checkCancellation()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return result
    }

    func deleteMerchantRule(_ id: UUID) throws -> [MerchantRule] {
        try Task.checkCancellation()
        let context = try makeContext()
        let records = try context.fetch(FetchDescriptor<MerchantRuleRecord>())
        let result = try records.filter { $0.id != id }.map { try $0.domainValue() }.sorted { $0.pattern < $1.pattern }
        do {
            for record in records where record.id == id { context.delete(record) }
            try Task.checkCancellation()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return result
    }

    private func makeContext() throws -> ModelContext {
        if container == nil {
            let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self], version: Schema.Version(3, 0, 0))
            let configuration: ModelConfiguration
            if let storeURL {
                configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            } else {
                configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
            }
            container = try ModelContainer(for: schema, configurations: [configuration])
        }
        guard let container else { throw ValidationError.invalidSnapshot }
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func snapshot(in context: ModelContext) throws -> FinanceSnapshot {
        let accounts = try context.fetch(FetchDescriptor<AccountRecord>(sortBy: [SortDescriptor(\.name)]))
        let records = try context.fetch(FetchDescriptor<TransactionRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let result = try FinanceSnapshot(
            accounts: accounts.map { try $0.domainValue() },
            transactions: records.map { try $0.domainValue() }.sorted {
                $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
            }
        )
        try result.validate()
        return result
    }
}
