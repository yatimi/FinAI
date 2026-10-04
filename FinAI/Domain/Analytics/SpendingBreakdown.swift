//
//  SpendingBreakdown.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct SpendingBreakdown: Identifiable, Equatable, Sendable {
    enum Group: Hashable, Sendable {
        case category(Category)
        case merchant(String)
    }

    let group: Group
    let expenses: Money
    let refunds: Money
    let netSpending: Money
    var id: Group { group }
}
