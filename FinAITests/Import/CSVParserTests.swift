//
//  CSVParserTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct CSVParserTests {
    @Test func supportsBOMQuotesEscapesAndEmbeddedNewlines() throws {
        let input = "\u{FEFF}date,description,amount,extra\r\n2026-09-01,\"Coffee, \"\"large\"\"\r\nwith milk\",-12.50,\r\n"
        let document = try CSVParser().parse(input, name: "sample.csv")
        #expect(document.delimiter == .comma)
        #expect(document.rows.count == 1)
        #expect(document.rows[0].fields == ["2026-09-01", "Coffee, \"large\"\nwith milk", "-12.50", ""])
        #expect(document.rows[0].number == 2)
    }

    @Test(arguments: CSVDelimiter.allCases)
    func detectsSeparatorOutsideQuotes(separator: CSVDelimiter) throws {
        let csv = ["date", "\"description, with; punctuation\"", "amount"].joined(separator: separator.rawValue)
            + "\n" + ["2026-09-01", "Coffee", "-10"].joined(separator: separator.rawValue)
        #expect(try CSVParser().parse(csv, name: "sample.csv").delimiter == separator)
    }

    @Test(arguments: ["a,b\n\"unterminated,b", "a,b\nx\"y,z", "a,b\n\"x\"invalid,y", "a,b\n\"x\"  \"y\",z"])
    func rejectsMalformedQuotes(csv: String) {
        #expect(throws: ImportError.malformedCSV) { try CSVParser().parse(csv, name: "sample.csv", delimiter: .comma) }
    }

    @Test func preservesRaggedRowsForValidationAndIgnoresBlankLines() throws {
        let result = try CSVParser().parse("a,b\n\n1,2\n3\n", name: "sample.csv")
        #expect(result.rows.map(\.number) == [3, 4])
        #expect(result.rows[1].fields == ["3"])
    }

    @Test func enforcesLimits() {
        #expect(throws: ImportError.emptyFile) { try CSVParser().parse("date,amount", name: "sample.csv") }
        #expect(throws: ImportError.tooManyRows) {
            try CSVParser().parse("a,b\n" + String(repeating: "1,2\n", count: CSVParser.maximumRows + 1), name: "sample.csv")
        }
        #expect(throws: ImportError.tooManyColumns) {
            try CSVParser().parse(String(repeating: "a,", count: 65) + "\nx,y", name: "sample.csv", delimiter: .comma)
        }
        #expect(throws: ImportError.fileTooLarge) {
            try CSVParser().parse(String(repeating: "x", count: CSVParser.maximumBytes + 1), name: "sample.csv")
        }
    }
}
