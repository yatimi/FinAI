//
//  DebtRecord.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation
import SwiftData

@Model
final class DebtRecord {
    @Attribute(.unique) var id: UUID
    var person: String
    var direction: String
    var principal: String
    var currencyCode: String
    var date: Date
    var dueDate: Date?

    init(_ debt: PersonalDebt) {
        id = debt.id; person = debt.person; direction = debt.direction.rawValue
        principal = NSDecimalNumber(decimal: debt.principal.amount).stringValue
        currencyCode = debt.principal.currency.code; date = debt.date; dueDate = debt.dueDate
    }

    func domainValue(repayments: [DebtRepayment]) throws -> PersonalDebt {
        guard let amount = Decimal(string: principal, locale: Locale(identifier: "en_US_POSIX")),
              let direction = PersonalDebt.Direction(rawValue: direction) else { throw PersonalDebt.DebtError.invalid }
        return try PersonalDebt(id: id, person: person, direction: direction,
                                principal: Money(amount: amount, currency: Currency(code: currencyCode)),
                                date: date, dueDate: dueDate, repayments: repayments)
    }
}
