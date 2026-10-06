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
        case .bank: .bank
        case .debit: .debit
        case .credit: .credit
        case .cash: .cash
        case .savings: .savings
        case .other: .other
        }
    }
}

extension Transaction.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .expense: .expense
        case .income: .income
        case .transfer: .transfer
        case .refund: .refund
        case .adjustment: .adjustment
        case .unknown: .unknown
        }
    }
}

extension Transaction.Direction {
    var title: LocalizedStringResource { self == .debit ? .moneyOut : .moneyIn }
}

extension Category {
    var title: LocalizedStringResource {
        switch self {
        case .groceries: .groceries
        case .restaurants: .restaurants
        case .transport: .transport
        case .shopping: .shopping
        case .housing: .housing
        case .utilities: .utilities
        case .health: .health
        case .entertainment: .entertainment
        case .subscriptions: .subscriptions
        case .travel: .travel
        case .family: .family
        case .transfers: .transfers
        case .income: .income
        case .other: .other
        }
    }
}
