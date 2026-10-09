//
//  GoalDraft.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation

struct GoalDraft: Equatable, Sendable {
    var name = ""
    var target = ""
    var saved = "0"
    var currencyCode = "EUR"
    var deadline: Date

    init(deadline: Date) { self.deadline = deadline }

    init(goal: SavingsGoal, locale: Locale) {
        name = goal.name
        target = Self.amountText(goal.target.amount, locale: locale)
        saved = Self.amountText(goal.saved.amount, locale: locale)
        currencyCode = goal.target.currency.code
        deadline = goal.deadline
    }

    func goal(id: UUID, locale: Locale) throws -> SavingsGoal {
        let currency = try Currency(code: currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        let separator: CSVMapping.DecimalSeparator = locale.decimalSeparator == "," ? .comma : .dot
        let parser = ImportValueParser()
        let goal = try SavingsGoal(
            id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            target: Money(amount: parser.amount(target, separator: separator), currency: currency),
            saved: Money(amount: parser.amount(saved, separator: separator), currency: currency), deadline: deadline)
        try goal.validate()
        return goal
    }

    private static func amountText(_ value: Decimal, locale: Locale) -> String {
        NSDecimalNumber(decimal: value).stringValue.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
    }
}
