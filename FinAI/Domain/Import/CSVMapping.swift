//
//  CSVMapping.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CSVMapping: Equatable, Sendable {
    enum DateFormat: String, CaseIterable, Sendable {
        case iso = "yyyy-MM-dd"
        case dotted = "dd.MM.yyyy"
        case dayFirst = "dd/MM/yyyy"
        case monthFirst = "MM/dd/yyyy"
    }
    enum DecimalSeparator: String, CaseIterable, Sendable { case dot = ".", comma = "," }
    enum DirectionRule: String, CaseIterable, Sendable { case signed, moneyOut, moneyIn }

    var dateColumn = -1
    var amountColumn = -1
    var descriptionColumn = -1
    var currencyColumn = -1
    var kindColumn = -1
    var currencyCode = "EUR"
    var dateFormat = DateFormat.iso
    var decimalSeparator = DecimalSeparator.dot
    var directionRule = DirectionRule.signed
    var defaultKind = Transaction.Kind.unknown

    static func suggested(for document: CSVDocument) -> Self {
        func column(_ names: Set<String>) -> Int {
            document.headers.firstIndex { names.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) } ?? -1
        }
        var mapping = Self()
        mapping.dateColumn = column(["date", "datum", "booking date", "дата"])
        mapping.amountColumn = column(["amount", "betrag", "сума"])
        mapping.descriptionColumn = column(["description", "merchant", "beschreibung", "verwendungszweck", "опис"])
        mapping.currencyColumn = column(["currency", "währung", "валюта"])
        mapping.kindColumn = column(["type", "kind", "transaction type"])
        return mapping
    }

    func validate(columnCount: Int) throws {
        let required = [dateColumn, amountColumn, descriptionColumn]
        let selected = required + [currencyColumn, kindColumn].filter { $0 >= 0 }
        guard required.allSatisfy({ $0 >= 0 && $0 < columnCount }),
              [currencyColumn, kindColumn].allSatisfy({ $0 == -1 || (0..<columnCount).contains($0) }),
              Set(selected).count == selected.count else { throw ImportError.invalidMapping }
        if currencyColumn == -1 { _ = try Currency(code: currencyCode) }
    }
}
