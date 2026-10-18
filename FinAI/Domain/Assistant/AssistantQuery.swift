//
//  AssistantQuery.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation

struct AssistantQuery: Equatable, Sendable {
    enum Kind: Sendable { case spending, comparison, merchant }
    enum Period: Sendable { case thisMonth, lastMonth }

    var kind: Kind
    var period: Period = .thisMonth
    var merchant: String?
}
