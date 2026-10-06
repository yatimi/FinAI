//
//  StatementDocument.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import Foundation

struct StatementDocument: Equatable, Sendable {
    struct Entry: Equatable, Sendable {
        let number: Int
        let bookingDate: String
        let signedAmount: Decimal
        let description: String
        let payeeDescription: String
        let kind: Transaction.Kind
    }

    let name: String
    let currency: Currency
    let entries: [Entry]
}
