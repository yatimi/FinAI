//
//  GoalRecord.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation
import SwiftData

@Model
final class GoalRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var target: String
    var saved: String
    var currencyCode: String
    var deadline: Date

    init(_ goal: SavingsGoal) {
        id = goal.id
        name = goal.name
        target = NSDecimalNumber(decimal: goal.target.amount).stringValue
        saved = NSDecimalNumber(decimal: goal.saved.amount).stringValue
        currencyCode = goal.target.currency.code
        deadline = goal.deadline
    }

    func apply(_ goal: SavingsGoal) {
        name = goal.name
        target = NSDecimalNumber(decimal: goal.target.amount).stringValue
        saved = NSDecimalNumber(decimal: goal.saved.amount).stringValue
        currencyCode = goal.target.currency.code
        deadline = goal.deadline
    }

    func domainValue() throws -> SavingsGoal {
        let locale = Locale(identifier: "en_US_POSIX")
        guard let target = Decimal(string: target, locale: locale),
              let saved = Decimal(string: saved, locale: locale) else { throw ValidationError.invalidAmount }
        let currency = try Currency(code: currencyCode)
        let goal = try SavingsGoal(id: id, name: name, target: Money(amount: target, currency: currency),
                                   saved: Money(amount: saved, currency: currency), deadline: deadline)
        try goal.validate()
        return goal
    }
}
