//
//  AssistantAnswer.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation

struct AssistantAnswer: Equatable, Sendable {
    let query: AssistantQuery
    let report: SpendingAnalytics
    let categoryChanges: [CategorySpendingChange]
}
