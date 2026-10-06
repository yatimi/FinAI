//
//  ImportBatchStore.swift
//  FinAI
//
//  Created by Tommy on 03.10.26.
//

import Foundation
import SwiftData

/// Owns the complete import commit; callers provide a fresh context with autosave disabled.
struct ImportBatchStore {
    /// Accepts a validated batch and checks it against saved data before committing its receipt and transactions together.
    func save(_ batch: ImportBatch, in context: ModelContext) throws {
        try Task.checkCancellation()
        let existing = try FinanceSnapshotStore().load(in: context)
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
}
