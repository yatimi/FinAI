//
//  FinanceDatabaseTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct FinanceDatabaseTests {
    @Test func emptyStoreAndRepeatedSeed() async throws {
        let database = FinanceDatabase(inMemory: true)
        #expect(try await database.load() == .empty)
        let first = try await database.addDemo(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let second = try await database.addDemo(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(first == second)
        #expect(try await database.load() == first)
    }

    @Test func persistsAcrossDatabaseInstances() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Finance.store")
        let first = FinanceDatabase(storeURL: url)
        let saved = try await first.addDemo(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let reopened = FinanceDatabase(storeURL: url)
        #expect(try await reopened.load() == saved)
        #expect(try await reopened.addDemo(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar) == saved)
    }

    @Test func recordMappingPreservesOriginalDecimalAndProvenance() throws {
        let amount = try #require(Decimal(string: "123456789.123456789", locale: Locale(identifier: "en_US_POSIX")))
        let original = try TestFixtures.transaction(amount: amount, currency: .usd)
        let record = TransactionRecord(original)
        #expect(try record.domainValue() == original)
        record.kind = "corrupted-kind"
        #expect(throws: ValidationError.invalidSnapshot) { try record.domainValue() }
    }
}
