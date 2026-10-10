//
//  BudgetProgress.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation

struct BudgetProgress: Equatable, Sendable {
    let month: Date
    let spent: Money
    /// May exceed the limit when refunds exceed this month's expenses.
    let remaining: Money
    let exceeded: Money
}
