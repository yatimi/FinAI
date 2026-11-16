//
//  DebtDraft.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

struct DebtDraft: Equatable, Sendable {
    var person = ""
    var amount = ""
    var currencyCode = "EUR"
    var direction = PersonalDebt.Direction.iOwe
    var date: Date
    var hasDueDate = false
    var dueDate: Date

    init(date: Date) { self.date = date; dueDate = date }

    func debt(id: UUID, locale: Locale) throws -> PersonalDebt {
        let currency = try Currency(code: currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        let separator: CSVMapping.DecimalSeparator = locale.decimalSeparator == "," ? .comma : .dot
        return try PersonalDebt(id: id, person: person.trimmingCharacters(in: .whitespacesAndNewlines),
                                direction: direction, principal: Money(amount: ImportValueParser().amount(amount, separator: separator), currency: currency),
                                date: date, dueDate: hasDueDate ? dueDate : nil)
    }
}
