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

    private func makeContext() throws -> ModelContext {
        if container == nil {
            let schema = Schema([AccountRecord.self, TransactionRecord.self], version: Schema.Version(1, 0, 0))
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
