//
//  Currency.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct Currency: Hashable, Sendable, Codable, Identifiable {
    let code: String
    var id: String { code }

    static let eur = Self(validatedCode: "EUR")
    static let usd = Self(validatedCode: "USD")
    static let uah = Self(validatedCode: "UAH")

    init(code: String) throws {
        guard Locale.commonISOCurrencyCodes.contains(code) else {
            throw ValidationError.invalidCurrency
        }
        self.code = code
    }

    private init(validatedCode: String) { code = validatedCode }

    init(from decoder: any Decoder) throws {
        try self.init(code: decoder.singleValueContainer().decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}
