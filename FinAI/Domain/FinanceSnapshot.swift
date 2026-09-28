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

    static let empty = Self(accounts: [], transactions: [])

    func validate() throws {
        let accountIDs = Set(accounts.map(\.id))
        guard accountIDs.count == accounts.count,
              Set(transactions.map(\.id)).count == transactions.count,
              transactions.allSatisfy({ accountIDs.contains($0.accountID) }) else {
            throw ValidationError.invalidSnapshot
        }
    }
}
