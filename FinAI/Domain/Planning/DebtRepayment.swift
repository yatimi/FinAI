//
//  DebtRepayment.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

struct DebtRepayment: Equatable, Sendable, Identifiable {
    let id: UUID
    let amount: Money
    let date: Date
}
