//
//  Category.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

enum Category: String, CaseIterable, Codable, Sendable {
    case groceries, restaurants, transport, shopping, housing, utilities
    case health, entertainment, subscriptions, travel, family, transfers, income, other
}
