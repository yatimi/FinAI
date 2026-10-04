//
//  Account.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct Account: Identifiable, Equatable, Codable, Sendable {
    enum Kind: String, Codable, Sendable, CaseIterable {
        case bank, debit, credit, cash, savings, other
    }

    let id: UUID
    let name: String
    let kind: Kind
    let currency: Currency
}
