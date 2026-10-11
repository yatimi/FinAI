//
//  BudgetRecord.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation
import SwiftData

@Model
final class BudgetRecord {
    @Attribute(.unique) var id: UUID
    var category: String
    var limit: String
    var currencyCode: String

    init(_ budget: CategoryBudget) {
        id = budget.id
        category = budget.category.rawValue
        limit = NSDecimalNumber(decimal: budget.limit.amount).stringValue
        currencyCode = budget.limit.currency.code
    }

    func apply(_ budget: CategoryBudget) {
        category = budget.category.rawValue
        limit = NSDecimalNumber(decimal: budget.limit.amount).stringValue
        currencyCode = budget.limit.currency.code
    }

    func domainValue() throws -> CategoryBudget {
        guard let category = Category(rawValue: category),
              let amount = Decimal(string: limit, locale: Locale(identifier: "en_US_POSIX")) else { throw ValidationError.invalidAmount }
        let budget = try CategoryBudget(id: id, category: category, limit: Money(amount: amount, currency: Currency(code: currencyCode)))
        try budget.validate()
        return budget
    }
}
