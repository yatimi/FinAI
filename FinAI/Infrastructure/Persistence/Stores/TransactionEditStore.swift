//
//  TransactionEditStore.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import Foundation
import SwiftData

/// Checks optimistic concurrency and commits a correction and its immutable original atomically.
struct TransactionEditStore {
    func save(expected: Transaction, replacement: Transaction, date: Date, calendar: Calendar, in context: ModelContext) throws -> FinanceOverview {
        try Task.checkCancellation()
        let snapshot = try FinanceSnapshotStore().load(in: context)
        let updated = try TransactionEditService().replacing(expected, with: replacement, in: snapshot)
        // Validate analytics before committing, so a post-commit calculation error cannot look like a failed save.
        let overview = try FinanceOverview.make(snapshot: updated, date: date, calendar: calendar)
        let id = expected.id
        guard let record = try context.fetch(FetchDescriptor<TransactionRecord>(predicate: #Predicate { $0.id == id })).first else {
            throw TransactionEditError.storageChanged
        }
        guard replacement != expected else { return overview }
        do {
            if record.originalData == nil { record.originalData = try JSONEncoder().encode(expected) }
            record.apply(replacement)
            try Task.checkCancellation()
            try context.save()
            return overview
        } catch {
            context.rollback()
            throw error
        }
    }
}
