//
//  DebtProgress.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

struct DebtProgress: Equatable, Sendable {
    enum Status: Equatable { case active, overdue, settled }
    let repaid: Money
    let remaining: Money
    let status: Status
}
