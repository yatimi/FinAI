//
//  WhatIfDraft.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

struct WhatIfDraft: Equatable, Sendable {
    var change = WhatIfScenario.Change.additionalExpense
    var amount = ""
    var currencyCode = ""

    func scenario(locale: Locale) throws -> WhatIfScenario {
        let currency = try Currency(code: currencyCode)
        let separator: CSVMapping.DecimalSeparator = locale.decimalSeparator == "," ? .comma : .dot
        let amount = try ImportValueParser().amount(amount, separator: separator)
        return try WhatIfScenario(change: change, money: Money(amount: amount, currency: currency))
    }
}
