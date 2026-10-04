//
//  DuplicateDetectionTests.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct DuplicateDetectionTests {
    private let calendar = TestFixtures.calendar
    private let accountID = UUID()

    @Test func exactMatchKeepsOriginalDataAndNamesEarlierRow() throws {
        let first = try candidate(row: 2)
        let second = try candidate(row: 3)
        let reviewed = try review([first, second])
        #expect(reviewed[0].duplicateMatches.isEmpty)
        let match = try #require(reviewed[1].duplicateMatches.first)
        #expect(match.reason == .exact)
        #expect(match.source == .importRow(2))
        #expect(reviewed[1].description == second.description)
        #expect(reviewed[1].money == second.money)
    }

    @Test func normalizesCaseAccentsPunctuationAndWhitespaceOnlyForComparison() throws {
        let first = try candidate(description: "Café   purchase 123")
        let second = try candidate(row: 3, description: "CAFE-purchase 123")
        let match = try #require(review([first, second])[1].duplicateMatches.first)
        #expect(match.reason == .similarDescription)
        #expect(match.description == first.description)
        #expect(second.description == "CAFE-purchase 123")
    }

    @Test func findsNearDatesAndEnforcesThreeCalendarDayBoundary() throws {
        let saved = try candidate().transaction(accountID: accountID)
        let inside = try candidate(day: 4)
        let outside = try candidate(day: 5)
        let match = try #require(review([inside], existing: [saved])[0].duplicateMatches.first)
        #expect(match.reason == .nearbyDate)
        #expect(match.source == .savedTransaction(saved.id))
        #expect(try review([outside], existing: [saved])[0].duplicateMatches.isEmpty)
    }

    @Test func requiresKnownMerchantAndStrongSharedTokensForChangedDescription() throws {
        let first = try candidate(description: "REWE MARKT BERLIN purchase reference")
        let second = try candidate(row: 3, description: "REWE MARKT BERLIN purchase reference terminal")
        #expect(try review([first, second])[1].duplicateMatches.first?.reason == .similarDescription)
        let different = try candidate(row: 3, description: "REWE MARKT HAMBURG delivery checkout")
        #expect(try review([first, different])[1].duplicateMatches.isEmpty)
        let unknown = try candidate(description: "Unknown shop Berlin purchase reference")
        let unknownChanged = try candidate(row: 3, description: "Unknown shop Berlin purchase reference terminal")
        #expect(try review([unknown, unknownChanged])[1].duplicateMatches.isEmpty)
    }

    @Test func neverMatchesDifferentNumbersOrAlphanumericReferences() throws {
        let original = try candidate(description: "REWE MARKT BERLIN terminal 123 order A42")
        for text in ["REWE MARKT BERLIN terminal 456 order A42", "REWE MARKT BERLIN terminal 123 order A43"] {
            let changed = try candidate(row: 3, description: text)
            #expect(try review([original, changed])[1].duplicateMatches.isEmpty)
        }
    }

    @Test func ignoresAccountCurrencyAmountDirectionAndExplicitKindMismatches() throws {
        let original = try candidate()
        let saved = try original.transaction(accountID: UUID())
        #expect(try review([original], existing: [saved])[0].duplicateMatches.isEmpty)
        for other in try [
            candidate(row: 3, currency: .usd), candidate(row: 3, amount: 11),
            candidate(row: 3, kind: .refund, direction: .credit),
            candidate(row: 3, description: "REWE-MARKT 123", kind: .transfer)
        ] {
            #expect(try review([original, other])[1].duplicateMatches.isEmpty)
        }
    }

    @Test func unknownKindCanMatchAnExplicitKindWithoutInferringSemantics() throws {
        let first = try candidate()
        let unknown = try candidate(row: 3, description: "rewe markt 123", kind: .unknown)
        let reviewed = try review([first, unknown])
        #expect(reviewed[1].isPossibleDuplicate)
        #expect(reviewed[1].kind == .unknown)
    }

    @Test func exactMatchesTakePriorityAndEvidenceIsBoundedAndStable() throws {
        let exact = try candidate().transaction(accountID: accountID)
        let other = try candidate(description: "rewe markt 123").transaction(accountID: accountID)
        let existing = [exact, other] + (try (0..<8).map { _ in try candidate(day: 2).transaction(accountID: accountID) })
        let rows = try review([candidate()], existing: existing)
        #expect(rows[0].duplicateMatches.count == 3)
        #expect(rows[0].duplicateMatches.first?.source == .savedTransaction(exact.id))
        #expect(try review([candidate()], existing: existing.reversed())[0].duplicateMatches == rows[0].duplicateMatches)
    }

    @Test func blankPunctuationDescriptionsDoNotFuzzyMatch() throws {
        let rows = try [candidate(description: "!!!"), candidate(row: 3, description: "???")]
        #expect(try review(rows)[1].duplicateMatches.isEmpty)
    }

    @Test func dateWindowUsesCalendarDaysAcrossDaylightSaving() throws {
        var berlin = calendar
        berlin.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let firstDate = try #require(berlin.date(from: DateComponents(year: 2026, month: 10, day: 24)))
        let nextDate = try #require(berlin.date(from: DateComponents(year: 2026, month: 10, day: 27)))
        var first = try candidate()
        first = ImportCandidate(id: first.id, rowNumber: 2, date: firstDate, description: first.description, money: first.money,
                                direction: first.direction, merchant: first.merchant, kind: first.kind, category: first.category)
        let second = ImportCandidate(id: UUID(), rowNumber: 3, date: nextDate, description: first.description, money: first.money,
                                     direction: first.direction, merchant: first.merchant, kind: first.kind, category: first.category)
        let result = try DuplicateDetectionService().review([first, second], accountID: accountID, existing: [], calendar: berlin)
        #expect(result[1].duplicateMatches.first?.reason == .nearbyDate)
    }

    @Test func cancellationStopsReview() async throws {
        let rows = try [candidate()]
        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return try DuplicateDetectionService().review(rows, accountID: accountID, existing: [], calendar: calendar)
        }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    private func review(_ rows: [ImportCandidate], existing: [Transaction] = []) throws -> [ImportCandidate] {
        try DuplicateDetectionService().review(rows, accountID: accountID, existing: existing, calendar: calendar)
    }

    private func candidate(
        row: Int = 2, day: Int = 1, description: String = "REWE MARKT 123",
        amount: Decimal = 10, currency: Currency = .eur, kind: Transaction.Kind = .expense,
        direction: Transaction.Direction = .debit
    ) throws -> ImportCandidate {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: day)))
        return ImportCandidate(id: UUID(), rowNumber: row, date: date, description: description,
                               money: try Money(amount: amount, currency: currency), direction: direction,
                               merchant: "REWE", kind: kind, category: .groceries)
    }
}
