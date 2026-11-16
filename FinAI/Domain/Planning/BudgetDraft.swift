//
//  BudgetDraft.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation

struct BudgetDraft: Equatable, Sendable {
    var category = Category.groceries
    var limit = ""
    var currencyCode = "EUR"

    init() {}

    init(budget: CategoryBudget, locale: Locale) {
        category = budget.category
        limit = NSDecimalNumber(decimal: budget.limit.amount).stringValue
            .replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
        currencyCode = budget.limit.currency.code
    }

    func budget(id: UUID, locale: Locale) throws -> CategoryBudget {
        let currency = try Currency(code: currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        let separator: CSVMapping.DecimalSeparator = locale.decimalSeparator == "," ? .comma : .dot
        let value = try CategoryBudget(id: id, category: category,
            limit: Money(amount: ImportValueParser().amount(limit, separator: separator), currency: currency))
        try value.validate()
        return value
    }
}
