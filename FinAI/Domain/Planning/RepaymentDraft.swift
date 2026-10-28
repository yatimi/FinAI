//
//  RepaymentDraft.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

struct RepaymentDraft: Equatable, Sendable {
    var amount = ""
    var date: Date

    func repayment(id: UUID, currency: Currency, locale: Locale) throws -> DebtRepayment {
        let separator: CSVMapping.DecimalSeparator = locale.decimalSeparator == "," ? .comma : .dot
        return try DebtRepayment(id: id, amount: Money(amount: ImportValueParser().amount(amount, separator: separator), currency: currency), date: date)
    }
}
