//
//  DebtRepaymentRecord.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation
import SwiftData

@Model
final class DebtRepaymentRecord {
    @Attribute(.unique) var id: UUID
    var debtID: UUID
    var amount: String
    var currencyCode: String
    var date: Date

    init(_ repayment: DebtRepayment, debtID: UUID) {
        id = repayment.id; self.debtID = debtID
        amount = NSDecimalNumber(decimal: repayment.amount.amount).stringValue
        currencyCode = repayment.amount.currency.code; date = repayment.date
    }

    func domainValue() throws -> DebtRepayment {
        guard let amount = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")) else {
            throw PersonalDebt.DebtError.invalid
        }
        return try DebtRepayment(id: id, amount: Money(amount: amount, currency: Currency(code: currencyCode)), date: date)
    }
}
