//
//  DailySpending.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import Foundation

struct DailySpending: Identifiable, Equatable, Sendable {
    let date: Date
    let netSpending: Money
    var id: Date { date }
}
