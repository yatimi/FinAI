//
//  Money.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct Money: Equatable, Sendable, Codable {
    let amount: Decimal
    let currency: Currency

    init(amount: Decimal, currency: Currency) throws {
        guard !amount.isNaN else { throw ValidationError.invalidAmount }
        self.amount = amount
        self.currency = currency
    }

    static func zero(_ currency: Currency) -> Self {
        Self(validatedAmount: .zero, currency: currency)
    }

    func adding(_ other: Self) throws -> Self {
        guard currency == other.currency else { throw ValidationError.currencyMismatch }
        var lhs = amount
        var rhs = other.amount
        var result = Decimal.zero
        guard NSDecimalAdd(&result, &lhs, &rhs, .plain) == .noError else {
            throw ValidationError.arithmeticFailure
        }
        return try Self(amount: result, currency: currency)
    }

    func subtracting(_ other: Self) throws -> Self {
        try adding(Self(amount: -other.amount, currency: other.currency))
    }

    private init(validatedAmount: Decimal, currency: Currency) {
        amount = validatedAmount
        self.currency = currency
    }

    private enum CodingKeys: String, CodingKey { case amount, currency }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            amount: container.decode(Decimal.self, forKey: .amount),
            currency: container.decode(Currency.self, forKey: .currency)
        )
    }
}
