//
//  ImportDuplicateMatch.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation

struct ImportDuplicateMatch: Equatable, Sendable, Identifiable {
    enum Source: Hashable, Sendable {
        case savedTransaction(UUID)
        case importRow(Int)
    }
    enum Reason: Int, Sendable { case exact, similarDescription, nearbyDate }

    let source: Source
    let reason: Reason
    let date: Date
    let description: String
    var id: Source { source }
}
