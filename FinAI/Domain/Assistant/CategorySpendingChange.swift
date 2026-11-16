//
//  CategorySpendingChange.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

struct CategorySpendingChange: Equatable, Sendable, Identifiable {
    let category: Category
    let change: Money
    var id: String { "\(change.currency.code)-\(category.rawValue)" }
}
