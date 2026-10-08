//
//  FinanceSnapshotStore.swift
//  FinAI
//
//  Created by Tommy on 03.10.26.
//

import Foundation
import SwiftData

/// Reads validated domain values without exposing persistence records.
struct FinanceSnapshotStore {
    func load(in context: ModelContext) throws -> FinanceSnapshot {
        let accounts = try context.fetch(FetchDescriptor<AccountRecord>(sortBy: [SortDescriptor(\.name)]))
        let records = try context.fetch(FetchDescriptor<TransactionRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        var originals: [UUID: Transaction] = [:]
        for record in records {
            if let data = record.originalData { originals[record.id] = try JSONDecoder().decode(Transaction.self, from: data) }
        }
        let result = try FinanceSnapshot(
            accounts: accounts.map { try $0.domainValue() },
            transactions: records.map { try $0.domainValue() }.sorted {
                $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
            }, originals: originals
        )
        try result.validate()
        return result
    }
}
