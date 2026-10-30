//
//  PersonalDebt.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

/// A manually recorded obligation, independent of bank transactions and account balances.
struct PersonalDebt: Equatable, Sendable, Identifiable {
    enum Direction: String, CaseIterable, Sendable { case iOwe, owedToMe }
    enum DebtError: Error, Equatable { case invalid, overpayment, changed }

    let id: UUID
    let person: String
    let direction: Direction
    let principal: Money
    let date: Date
    let dueDate: Date?
    var repayments: [DebtRepayment] = []
}
