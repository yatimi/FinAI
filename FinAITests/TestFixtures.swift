//
//  TestFixtures.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
@testable import FinAI

enum TestFixtures {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
    static let date = Date(timeIntervalSince1970: 1_790_380_800)
    static func transaction(
        amount: Decimal, currency: Currency = .eur, kind: Transaction.Kind = .expense,
        date: Date = date, accountID: UUID = UUID()
    ) throws -> Transaction {
        try Transaction(
            id: UUID(), accountID: accountID, date: date, merchant: "Test merchant",
            rawDescription: "Original description", money: Money(amount: amount, currency: currency),
            direction: kind == .income || kind == .refund ? .credit : .debit,
            kind: kind, category: .other, source: .demo
        )
    }
}
