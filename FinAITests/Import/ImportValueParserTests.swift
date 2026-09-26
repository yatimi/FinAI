//
//  ImportValueParserTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct ImportValueParserTests {
    @Test func parsesLocaleFormatsWithoutFloatingPoint() throws {
        let parser = ImportValueParser()
        #expect(try parser.amount("-1,234.56", separator: .dot) == -Decimal(123456) / 100)
        #expect(try parser.amount("1.234,56", separator: .comma) == Decimal(123456) / 100)
        #expect(try parser.amount("1\u{202F}234,56", separator: .comma) == Decimal(123456) / 100)
        #expect(try parser.amount("+0.01", separator: .dot) == Decimal(1) / 100)
    }

    @Test(arguments: ["12abc", "", "NaN", "€12.00", "1,23.45", "1.2.3", "1e3", "--12", "0.0000000000000000001", String(repeating: "9", count: 39)])
    func rejectsAmbiguousOrLossyNumbers(value: String) {
        #expect(throws: ImportError.invalidAmount) { try ImportValueParser().amount(value, separator: .dot) }
    }

    @Test func dateFormatsAreExplicitAndStrict() throws {
        let parser = ImportValueParser()
        let iso = try parser.date("2024-02-29", format: .iso, timeZone: .gmt)
        #expect(try parser.date("29.02.2024", format: .dotted, timeZone: .gmt) == iso)
        #expect(throws: ImportError.invalidDate) { try parser.date("2026-02-29", format: .iso, timeZone: .gmt) }
        #expect(throws: ImportError.invalidDate) { try parser.date("2026-2-01", format: .iso, timeZone: .gmt) }
        #expect(throws: ImportError.invalidDate) { try parser.date("2026-09-01 garbage", format: .iso, timeZone: .gmt) }
        let dayFirst = try parser.date("01/02/2026", format: .dayFirst, timeZone: .gmt)
        let monthFirst = try parser.date("01/02/2026", format: .monthFirst, timeZone: .gmt)
        #expect(dayFirst != monthFirst)
    }
}
