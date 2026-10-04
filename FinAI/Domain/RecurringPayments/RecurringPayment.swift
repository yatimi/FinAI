//
//  RecurringPayment.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation

/// Evidence of a repeating expense, not a confirmed contract or subscription.
struct RecurringPayment: Equatable, Sendable, Identifiable {
    struct ID: Hashable, Sendable {
        let accountID: UUID
        let merchant: String
        let currency: Currency
        let amount: Decimal
    }

    enum Cadence: CaseIterable, Sendable { case weekly, monthly, yearly }

    let id: ID
    let merchant: String
    let money: Money
    let cadence: Cadence
    let transactionIDs: [UUID]
    let firstDate: Date
    let lastDate: Date
    /// The next date after the last observed payment; never advanced past missing activity.
    let expectedDate: Date
    let isSubscriptionCandidate: Bool
    let isStale: Bool
}
