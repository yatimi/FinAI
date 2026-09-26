//
//  DomainLabels.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

extension Account.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .bank: "Bank"
        case .debit: "Debit"
        case .credit: "Credit"
        case .cash: "Cash"
        case .savings: "Savings"
        case .other: "Other"
        }
    }
}

extension Transaction.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        case .transfer: "Transfer"
        case .refund: "Refund"
        case .adjustment: "Adjustment"
        case .unknown: "Unknown"
        }
    }
}

extension Transaction.Direction {
    var title: LocalizedStringResource { self == .debit ? "Money out" : "Money in" }
}

extension Category {
    var title: LocalizedStringResource {
        switch self {
        case .groceries: "Groceries"
        case .restaurants: "Restaurants"
        case .transport: "Transport"
        case .shopping: "Shopping"
        case .housing: "Housing"
        case .utilities: "Utilities"
        case .health: "Health"
        case .entertainment: "Entertainment"
        case .subscriptions: "Subscriptions"
        case .travel: "Travel"
        case .family: "Family"
        case .transfers: "Transfers"
        case .income: "Income"
        case .other: "Other"
        }
    }
}
