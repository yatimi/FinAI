//
//  SpendingAnalytics.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct SpendingAnalytics: Equatable, Sendable {
    let month: Date
    let previousMonth: Date
    let currencies: [MonthlySpending]
}
