//
//  SavingsGoal.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation

/// A planning target. Recorded savings do not move money or change account balances.
struct SavingsGoal: Equatable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let target: Money
    let saved: Money
    let deadline: Date

    enum GoalError: Error, Equatable { case invalidName, invalidAmount, invalidDate, changed }

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GoalError.invalidName
        }
        guard target.amount > 0, saved.amount >= 0 else { throw GoalError.invalidAmount }
        guard target.currency == saved.currency else { throw ValidationError.currencyMismatch }
        guard deadline.timeIntervalSinceReferenceDate.isFinite else { throw GoalError.invalidDate }
    }
}
