//
//  BudgetStore.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation
import SwiftData

struct BudgetStore {
    func load(in context: ModelContext) throws -> [CategoryBudget] {
        try Task.checkCancellation()
        return try context.fetch(FetchDescriptor<BudgetRecord>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.currencyCode)]))
            .map { try $0.domainValue() }
    }

    func save(_ budget: CategoryBudget, expected: CategoryBudget?, in context: ModelContext) throws -> [CategoryBudget] {
        try budget.validate()
        try Task.checkCancellation()
        let records = try context.fetch(FetchDescriptor<BudgetRecord>())
        let record = records.first { $0.id == budget.id }
        guard expected == nil || expected?.id == budget.id,
              try record?.domainValue() == expected else { throw CategoryBudget.BudgetError.changed }
        let others = try records.filter { $0.id != budget.id }.map { try $0.domainValue() }
        guard !others.contains(where: { $0.category == budget.category && $0.limit.currency == budget.limit.currency }) else {
            throw CategoryBudget.BudgetError.duplicate
        }
        do {
            if let record { record.apply(budget) } else { context.insert(BudgetRecord(budget)) }
            try Task.checkCancellation()
            try context.save()
        } catch { context.rollback(); throw error }
        return (others + [budget]).sorted {
            $0.category == $1.category ? $0.limit.currency.code < $1.limit.currency.code : $0.category.rawValue < $1.category.rawValue
        }
    }
}
