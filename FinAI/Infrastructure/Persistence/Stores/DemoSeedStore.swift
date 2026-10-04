//
//  DemoSeedStore.swift
//  FinAI
//
//  Created by Tommy on 03.10.26.
//

import Foundation
import SwiftData

/// Synchronous operations run within FinanceDatabase isolation.
struct DemoSeedStore {
    /// Seeds only an empty store. Repeat requests and relaunches cannot duplicate demo records.
    func addDemo(referenceDate: Date, calendar: Calendar, in context: ModelContext) throws -> FinanceSnapshot {
        try Task.checkCancellation()
        let existing = try FinanceSnapshotStore().load(in: context)
        guard existing.accounts.isEmpty && existing.transactions.isEmpty else { return existing }
        let demo = try DemoData().make(referenceDate: referenceDate, calendar: calendar)
        try demo.validate()
        do {
            for account in demo.accounts { context.insert(AccountRecord(account)) }
            for transaction in demo.transactions { context.insert(TransactionRecord(transaction)) }
            try Task.checkCancellation()
            try context.save()
            return try FinanceSnapshotStore().load(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }
}
