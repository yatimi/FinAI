//
//  TransactionQuery.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct TransactionQuery: Equatable, Sendable {
    enum Period: CaseIterable, Sendable { case all, thisMonth, lastMonth, custom }

    var text = ""
    var accountID: UUID?
    var category: Category?
    var kind: Transaction.Kind?
    var currency: Currency?
    var period = Period.all
    var startDate = Date.distantPast
    var endDate = Date.distantPast

    var isActive: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || accountID != nil || category != nil || kind != nil || currency != nil || period != .all
    }
}
