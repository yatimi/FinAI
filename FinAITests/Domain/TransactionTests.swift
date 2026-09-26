//
//  TransactionTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct TransactionTests {
    @Test func rejectsNegativeMagnitude() {
        #expect(throws: ValidationError.invalidTransaction) { try TestFixtures.transaction(amount: -1) }
    }

    @Test func rejectsContradictoryDirection() throws {
        #expect(throws: ValidationError.invalidTransaction) {
            try Transaction(
                id: UUID(), accountID: UUID(), date: TestFixtures.date, merchant: "Merchant",
                rawDescription: "Original", money: Money(amount: 10, currency: .eur),
                direction: .credit, kind: .expense, category: .other, source: .demo
            )
        }
    }

    @Test func decodingValidatesTransaction() throws {
        let transaction = try TestFixtures.transaction(amount: 10)
        let encoded = try JSONEncoder().encode(transaction)
        #expect(try JSONDecoder().decode(Transaction.self, from: encoded) == transaction)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["direction"] = "credit"
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: ValidationError.invalidTransaction) { try JSONDecoder().decode(Transaction.self, from: invalid) }
    }

    @Test func snapshotRejectsMissingAccountAndDuplicateIDs() throws {
        let transaction = try TestFixtures.transaction(amount: 10)
        #expect(throws: ValidationError.invalidSnapshot) {
            try FinanceSnapshot(accounts: [], transactions: [transaction]).validate()
        }
        let account = Account(id: transaction.accountID, name: "Account", kind: .bank, currency: .eur)
        #expect(throws: ValidationError.invalidSnapshot) {
            try FinanceSnapshot(accounts: [account], transactions: [transaction, transaction]).validate()
        }
    }

    @Test func demoIsSyntheticValidAndDoesNotContainFutureTransactions() throws {
        let demo = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        try demo.validate()
        #expect(demo.accounts.count == 3)
        #expect(demo.transactions.count > 40)
        #expect(demo.transactions.allSatisfy { $0.source == .demo && $0.date <= TestFixtures.date })
        #expect(Set(demo.transactions.map(\.kind)).isSuperset(of: [.income, .expense, .transfer, .refund]))
        let transfers = demo.transactions.filter { $0.kind == .transfer }
        #expect(transfers.filter { $0.direction == .credit }.count == transfers.filter { $0.direction == .debit }.count)
    }
}
