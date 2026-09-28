//
//  CSVImportServiceTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct CSVImportServiceTests {
    @Test func normalizationPreservesRawDescriptionAndExactDuplicateBehavior() throws {
        let raw = " rewe MARKT 123 "
        let document = try CSVParser().parse(
            "date,description,amount,currency,type\n2026-09-01,\(raw),-10,EUR,expense\n2026-09-01,REWE MARKT 456,-10,EUR,expense",
            name: "merchants.csv"
        )
        let service = CSVImportService()
        let mapping = CSVMapping.suggested(for: document)
        let result = try service.preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(result.candidates.map(\.merchant) == ["REWE", "REWE"])
        #expect(result.candidates.map(\.category) == [.groceries, .groceries])
        #expect(result.candidates.map(\.isPossibleDuplicate) == [false, false])
        let transactions = try result.candidates.map { try $0.transaction(accountID: ImportFixtures.account.id) }
        #expect(transactions[0].rawDescription == raw)
        #expect(transactions[0].merchant == "REWE")
        let repeated = try service.preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: transactions, timeZone: .gmt)
        #expect(repeated.candidates.allSatisfy { $0.isPossibleDuplicate })
    }

    @Test func blankMerchantCorrectionCannotBeSaved() throws {
        var candidate = try #require(ImportFixtures.preview().candidates.first)
        candidate.merchant = " \n "
        #expect(throws: ImportError.missingMerchant) {
            try candidate.transaction(accountID: ImportFixtures.account.id)
        }
    }

    @Test func producesCandidatesAndIssuesWithoutDroppingRowsSilently() throws {
        let result = try ImportFixtures.preview()
        #expect(result.candidates.count == 2)
        #expect(result.issues == [.init(rowNumber: 4, error: .invalidAmount)])
        #expect(result.candidates[0].kind == .expense)
        #expect(result.candidates[0].direction == .debit)
        #expect(result.candidates[0].money.amount == Decimal(125) / 10)
        let transaction = try result.candidates[0].transaction(accountID: ImportFixtures.account.id)
        #expect(transaction.rawDescription == "Test coffee")
        #expect(transaction.source == .imported)
    }

    @Test func signDoesNotClassifyUnknownTransactions() throws {
        let document = try CSVParser().parse("date,description,amount\n2026-09-01,Out,-10\n2026-09-02,In,20", name: "sample.csv")
        let result = try CSVImportService().preview(document: document, mapping: .suggested(for: document), account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(result.candidates.map(\.kind) == [.unknown, .unknown])
        #expect(result.candidates.map(\.direction) == [.debit, .credit])
    }

    @Test func validatesDateCurrencyWidthAndType() throws {
        let document = try CSVParser().parse("date,description,amount,currency,type\n2026-02-30,Coffee,-1,EUR,expense\n2026-09-01,Coffee,-1,XYZ,expense\n2026-09-01,Coffee,-1,EUR,invalid\n2026-09-01,Coffee,1,EUR,expense\n2026-09-01,Coffee", name: "sample.csv")
        let result = try CSVImportService().preview(document: document, mapping: .suggested(for: document), account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(result.candidates.isEmpty)
        #expect(result.issues.map(\.error) == [.invalidDate, .invalidCurrency, .invalidKind, .inconsistentDirection, .malformedCSV])
    }

    @Test func explicitDirectionAndFormatsSupportPositiveExpenses() throws {
        let document = try CSVParser().parse("Datum;Beschreibung;Betrag\n26.09.2026;Shopping;1.234,56", name: "sample.csv")
        var mapping = CSVMapping.suggested(for: document)
        mapping.dateFormat = .dotted
        mapping.decimalSeparator = .comma
        mapping.directionRule = .moneyOut
        mapping.defaultKind = .expense
        let result = try CSVImportService().preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(result.candidates.first?.money.amount == Decimal(123456) / 100)
        #expect(result.candidates.first?.direction == .debit)
    }

    @Test func findsExactMatchesWithinFileAndExistingAccount() throws {
        let document = try CSVParser().parse("date,description,amount\n2026-09-01,Coffee,-10\n2026-09-01,Coffee,-10", name: "sample.csv")
        let mapping = CSVMapping.suggested(for: document)
        let service = CSVImportService()
        let first = try service.preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(first.candidates.map(\.isPossibleDuplicate) == [false, true])
        let existing = try first.candidates.map { try $0.transaction(accountID: ImportFixtures.account.id) }
        let repeated = try service.preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: existing, timeZone: .gmt)
        #expect(repeated.candidates.allSatisfy { $0.isPossibleDuplicate })
    }

    @Test func refusesReusingOneColumnForDifferentFields() throws {
        let document = try ImportFixtures.document()
        var mapping = CSVMapping.suggested(for: document)
        mapping.amountColumn = mapping.dateColumn
        #expect(throws: ImportError.invalidMapping) {
            try CSVImportService().preview(document: document, mapping: mapping, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        }
    }
}
