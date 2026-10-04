//
//  MoneyTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct MoneyTests {
    @Test func decimalArithmeticIsExact() throws {
        let tenth = try Money(amount: Decimal(1) / 10, currency: .eur)
        let fifth = try Money(amount: Decimal(2) / 10, currency: .eur)
        let sum = try tenth.adding(fifth)
        #expect(sum.amount == Decimal(3) / 10)
        #expect(try sum.subtracting(tenth) == fifth)
    }

    @Test func rejectsMixedCurrencies() throws {
        let euros = try Money(amount: 10, currency: .eur)
        let dollars = try Money(amount: 10, currency: .usd)
        #expect(throws: ValidationError.currencyMismatch) { try euros.adding(dollars) }
        #expect(throws: ValidationError.currencyMismatch) { try euros.subtracting(dollars) }
    }

    @Test func rejectsNaNAndArithmeticOverflow() throws {
        #expect(throws: ValidationError.invalidAmount) { try Money(amount: .nan, currency: .eur) }
        let maximum = try Money(amount: .greatestFiniteMagnitude, currency: .eur)
        #expect(throws: ValidationError.arithmeticFailure) { try maximum.adding(maximum) }
    }

    @Test(arguments: ["eur", "", "EURO", "123", "ZZZ"])
    func rejectsInvalidCurrency(code: String) {
        #expect(throws: ValidationError.invalidCurrency) { try Currency(code: code) }
    }

    @Test func codingPreservesAmountAndValidatesCurrency() throws {
        let amount = try #require(Decimal(string: "123456789.123456789", locale: Locale(identifier: "en_US_POSIX")))
        let money = try Money(amount: amount, currency: .uah)
        #expect(try JSONDecoder().decode(Money.self, from: JSONEncoder().encode(money)) == money)
        #expect(throws: ValidationError.invalidCurrency) {
            try JSONDecoder().decode(Currency.self, from: Data("\"invalid\"".utf8))
        }
    }
}
