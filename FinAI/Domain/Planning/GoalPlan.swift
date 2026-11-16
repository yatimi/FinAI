//
//  GoalPlan.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation

struct GoalPlan: Equatable, Sendable {
    let remaining: Money
    let contributionMonths: Int
    let monthlyContribution: Money?
    let status: Status

    enum Status: Equatable, Sendable { case active, completed, overdue }
}
