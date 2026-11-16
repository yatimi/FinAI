//
//  FinanceSnapshot.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct FinanceSnapshot: Equatable, Sendable {
    var accounts: [Account]
    var transactions: [Transaction]

    /// Values before the first saved correction; absent entries use the current transaction.
    var originals: [UUID: Transaction] = [:]

    var originalTransactions: [Transaction] { transactions.map { originals[$0.id] ?? $0 } }

    static let empty = Self(accounts: [], transactions: [])

    func validate() throws {
        let accountIDs = Set(accounts.map(\.id))
        guard accountIDs.count == accounts.count,
              Set(transactions.map(\.id)).count == transactions.count,
              transactions.allSatisfy({ accountIDs.contains($0.accountID) }),
              originals.allSatisfy({ id, original in
                  transactions.contains { $0.id == id && original.id == id && $0.source == original.source && $0.rawDescription == original.rawDescription }
                  && accountIDs.contains(original.accountID)
              }) else {
            throw ValidationError.invalidSnapshot
        }
    }
}
