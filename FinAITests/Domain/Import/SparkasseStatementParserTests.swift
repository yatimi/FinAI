//
//  SparkasseStatementParserTests.swift
//  FinAITests
//
//  Created by Tommy on 06.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct SparkasseStatementParserTests {
    @Test func parsesBookingDatesExactAmountsAndIndependentKinds() throws {
        let result = try StatementFixtures.document()
        #expect(result.entries.count == 5)
        #expect(result.entries.map(\.number) == [2, 3, 4, 5, 6])
        #expect(result.entries.map(\.kind) == [.expense, .unknown, .unknown, .expense, .adjustment])
        #expect(result.entries[1].signedAmount == 1000)
        #expect(result.entries[0].signedAmount == Decimal(string: "-12.50"))
        #expect(result.entries[3].bookingDate == "30.09.2026")
        #expect(result.currency == .eur)
        #expect(result.entries[0].description == "dig. Karte Apple Pay\nREWE MARKT 123//Example/DE\n2026-08-31T12:00 Debitk.0")
    }

    @Test func joinsPageBreaksAndIgnoresFeeAppendices() throws {
        let first = StatementFixtures.page("""
        Kontostand am 31.08.2026, Auszug Nr. 0 100,00
        01.09.2026Basis-Lastschr.einlös
        Test merchant
        """, number: 1, total: 3)
        let second = StatementFixtures.page("""
        Continued description
        -5,00
        Kontostand am 30.09.2026 um 20:00 Uhr 95,00
        """, number: 2, total: 3)
        let appendix = """
        Example Sparkasse
        Kontoauszug 1/2026
        GiroOnline 0000000000, DE00 0000 0000 0000 0000 00
        Seite 3 von 3
        Entgeltabrechnung: Anlage 1
        Abrechnung 30.09.2026 5,00-
        """
        let result = try SparkasseStatementParser().parse(pages: [first, second, appendix], name: "Test.pdf")
        #expect(result.entries.count == 1)
        #expect(result.entries[0].payeeDescription == "Test merchant\nContinued description")
    }

    @Test(arguments: [
        ("985,00", "984,99", ImportError.statementBalanceMismatch),
        ("-12,50", "-12,5", .malformedStatement),
        ("01.09.2026dig.", "31.02.2026dig.", .invalidDate),
        ("Betrag EUR", "Betrag USD", .unsupportedStatement),
        ("Postanschrift:", "Footer:", .malformedStatement),
        ("Seite 1 von 1", "Seite 2 von 2", .unsupportedStatement)
    ])
    func rejectsAmbiguousOrIncompleteStatements(change: (String, String, ImportError)) {
        let page = StatementFixtures.page(StatementFixtures.body).replacingOccurrences(of: change.0, with: change.1)
        #expect(throws: change.2) { try SparkasseStatementParser().parse(pages: [page], name: "Test.pdf") }
    }

    @Test func missingTransactionCannotPassBalanceCheck() {
        let body = StatementFixtures.body.replacingOccurrences(of: "03.09.2026Echtzeit-Überweisung\nOwn savings account\n-100,00\n", with: "")
        #expect(throws: ImportError.statementBalanceMismatch) {
            try SparkasseStatementParser().parse(pages: [StatementFixtures.page(body)], name: "Test.pdf")
        }
    }

    @Test func rejectsMixedStatementsAndMultipleAmounts() {
        let body = StatementFixtures.body.replacingOccurrences(of: "-12,50", with: "-12,50\n-1,00")
        #expect(throws: ImportError.malformedStatement) {
            try SparkasseStatementParser().parse(pages: [StatementFixtures.page(body)], name: "Test.pdf")
        }
        let page1 = StatementFixtures.page(StatementFixtures.body, number: 1, total: 2)
        let page2 = StatementFixtures.page(StatementFixtures.body, number: 2, total: 2)
            .replacingOccurrences(of: "Kontoauszug 1/2026", with: "Kontoauszug 2/2026")
        #expect(throws: ImportError.unsupportedStatement) {
            try SparkasseStatementParser().parse(pages: [page1, page2], name: "Test.pdf")
        }
    }

    @Test func previewReusesClassificationRulesAndDuplicateReviewWithoutConvertingCurrency() throws {
        let statement = try StatementFixtures.document()
        let account = Account(id: UUID(), name: "Dollar account", kind: .bank, currency: .usd)
        let service = ImportPreviewService()
        let firstPreview = try service.preview(statement: statement, account: account, existing: [], timeZone: .gmt)
        let first = try #require(firstPreview.candidates.first)
        #expect(first.merchant == "REWE")
        #expect(first.category == .groceries)
        #expect(first.money.currency == .eur)
        #expect(first.money.amount == Decimal(string: "12.50"))
        let preview = try service.preview(
            statement: statement, account: account, existing: [first.transaction(accountID: account.id)], timeZone: .gmt
        )
        #expect(preview.candidates[0].isPossibleDuplicate)
        #expect(preview.candidates[1].kind == .unknown)
        #expect(preview.issues.isEmpty)
        let batch = try ImportBatch(
            id: UUID(), sourceName: statement.name, importedAt: TestFixtures.date, account: account,
            transactions: preview.candidates.map { try $0.transaction(accountID: account.id) },
            rowNumbers: preview.candidates.map(\.rowNumber), replacingDemo: false
        )
        try batch.validate()
        #expect(batch.transactions.last?.money.amount == 0)
    }

    @Test func savedOriginalDescriptionRuleTakesPriorityOverBuiltInMerchant() throws {
        let statement = try StatementFixtures.document()
        let entry = try #require(statement.entries.first)
        let rule = MerchantRule(id: UUID(), pattern: entry.description, matchMode: .exact, kind: .expense, merchant: "My market", category: .family)
        let service = ImportPreviewService(classification: TransactionClassificationService(rules: [rule]))
        let result = try service.preview(statement: statement, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        #expect(result.candidates[0].merchant == "My market")
        #expect(result.candidates[0].category == .family)
    }

    @Test func rejectsBookingDatesOutsideStatementAndRowsAfterClosingBalance() {
        let body = StatementFixtures.body.replacingOccurrences(of: "01.09.2026dig.", with: "01.08.2026dig.")
        #expect(throws: ImportError.malformedStatement) {
            try SparkasseStatementParser().parse(pages: [StatementFixtures.page(body)], name: "Test.pdf")
        }
        let extra = StatementFixtures.body + "\n30.09.2026Abrechnung\n0,00"
        #expect(throws: ImportError.malformedStatement) {
            try SparkasseStatementParser().parse(pages: [StatementFixtures.page(extra)], name: "Test.pdf")
        }
    }

    @Test func emptyMonthStillRequiresBalances() throws {
        let result = try SparkasseStatementParser().parse(pages: [StatementFixtures.page("""
        Kontostand am 31.08.2026, Auszug Nr. 0 100,00
        Kontostand am 30.09.2026 um 20:00 Uhr 100,00
        """)], name: "Empty.pdf")
        #expect(result.entries.isEmpty)
    }
}
