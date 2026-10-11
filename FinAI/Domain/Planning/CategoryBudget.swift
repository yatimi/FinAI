//
//  CategoryBudget.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation

/// A repeating monthly limit across owned accounts, in one original currency.
struct CategoryBudget: Equatable, Sendable, Identifiable {
    let id: UUID
    let category: Category
    let limit: Money

    enum BudgetError: Error, Equatable { case invalidCategory, invalidAmount, changed, duplicate }

    func validate() throws {
        guard category != .income, category != .transfers else { throw BudgetError.invalidCategory }
        guard limit.amount > 0 else { throw BudgetError.invalidAmount }
    }
}
