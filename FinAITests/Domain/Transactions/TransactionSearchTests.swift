//
//  TransactionSearchTests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct TransactionSearchTests {
    private let service = TransactionSearchService()

    @Test func searchesMerchantAndOriginalDescriptionIgnoringCaseAndAccents() throws {
        let transaction = try Transaction(
            id: UUID(), accountID: UUID(), date: TestFixtures.date, merchant: "Café REWE",
            rawDescription: "POS purchase BERLIN 123", money: Money(amount: 10, currency: .eur),
            direction: .debit, kind: .expense, category: .groceries, source: .imported
        )
        for text in ["  cafe rewe\n", "berlin", "123", "   "] {
            #expect(search([transaction], query: TransactionQuery(text: text)) == [transaction])
        }
        #expect(search([transaction], query: TransactionQuery(text: "Amazon")).isEmpty)
        #expect(search([], query: TransactionQuery(text: "REWE")).isEmpty)
    }

    @Test func intersectsEveryFilterAndPreservesValuesAndOrder() throws {
        let account = UUID()
        let matching = try TestFixtures.transaction(amount: 20, currency: .usd, kind: .refund, accountID: account)
        let otherAccount = try TestFixtures.transaction(amount: 20, currency: .usd, kind: .refund)
        let otherCurrency = try TestFixtures.transaction(amount: 20, kind: .refund, accountID: account)
        let otherKind = try TestFixtures.transaction(amount: 20, currency: .usd, accountID: account)
        let transactions = [otherAccount, matching, otherCurrency, otherKind]
        let query = TransactionQuery(text: "original", accountID: account, category: .other, kind: .refund, currency: .usd)
        #expect(search(transactions, query: query) == [matching])
        var wrongCategory = query
        wrongCategory.category = .groceries
        #expect(search(transactions, query: wrongCategory).isEmpty)
        var wrongText = query
        wrongText.text = "missing"
        #expect(search(transactions, query: wrongText).isEmpty)
        #expect(search(transactions, query: TransactionQuery()) == transactions)
    }

    @Test(arguments: Transaction.Kind.allCases)
    func filtersByExplicitKind(_ kind: Transaction.Kind) throws {
        let transactions = try Transaction.Kind.allCases.map { try TestFixtures.transaction(amount: 10, kind: $0) }
        let results = search(transactions, query: TransactionQuery(kind: kind))
        #expect(results.count == 1)
        #expect(results.first?.kind == kind)
    }

    @Test(arguments: [3, 10])
    func customDatesIncludeWholeDSTDayAndExcludeNextMidnight(month: Int) throws {
        var calendar = TestFixtures.calendar
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let day = month == 3 ? 29 : 25
        let noon = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
        let query = TransactionQuery(period: .custom, startDate: noon, endDate: noon)
        let interval = try #require(service.dateInterval(query: query, now: noon, calendar: calendar))
        #expect(interval.duration == (month == 3 ? 23 : 25) * 3600)
        let dates = [interval.start.addingTimeInterval(-1), interval.start, interval.end.addingTimeInterval(-1), interval.end]
        let transactions = try dates.map { try TestFixtures.transaction(amount: 1, date: $0) }
        #expect(service.search(transactions, query: query, now: noon, calendar: calendar) == Array(transactions[1...2]))
    }

    @Test func previousMonthCrossesYearAndCurrentMonthUsesHalfOpenInterval() throws {
        let calendar = TestFixtures.calendar
        let january = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)))
        let previous = try #require(service.dateInterval(query: TransactionQuery(period: .lastMonth), now: january, calendar: calendar))
        #expect(calendar.component(.year, from: previous.start) == 2025)
        #expect(calendar.component(.month, from: previous.start) == 12)
        let currentQuery = TransactionQuery(period: .thisMonth)
        let current = try #require(service.dateInterval(query: currentQuery, now: january, calendar: calendar))
        #expect(previous.end == current.start)
        let transactions = try [previous.start, current.start, current.end].map { try TestFixtures.transaction(amount: 1, date: $0) }
        #expect(service.search(transactions, query: currentQuery, now: january, calendar: calendar) == [transactions[1]])
        #expect(service.search(transactions, query: TransactionQuery(period: .lastMonth), now: january, calendar: calendar) == [transactions[0]])
    }

    @Test func invertedRangeNeverBroadensSearch() throws {
        let transaction = try TestFixtures.transaction(amount: 1)
        let query = TransactionQuery(period: .custom, startDate: TestFixtures.date.addingTimeInterval(86400), endDate: TestFixtures.date)
        #expect(search([transaction], query: query).isEmpty)
    }

    private func search(_ transactions: [Transaction], query: TransactionQuery) -> [Transaction] {
        service.search(transactions, query: query, now: TestFixtures.date, calendar: TestFixtures.calendar)
    }
}
