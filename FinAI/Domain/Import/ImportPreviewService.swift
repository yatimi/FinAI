//
//  ImportPreviewService.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import Foundation

struct ImportPreviewService: Sendable {
    var classification = TransactionClassificationService()

    func candidate(
        rowNumber: Int, date: Date, description: String, money: Money,
        direction: Transaction.Direction, kind: Transaction.Kind, payeeDescription: String? = nil
    ) -> ImportCandidate {
        // Saved rules use the preserved original description; bank operation labels must not
        // prevent the built-in merchant catalog from recognizing the payee below that label.
        let hasOriginalRule = classification.rules.contains { $0.matches(description: description, kind: kind) }
        let suggestion = classification.suggest(description: hasOriginalRule ? description : payeeDescription ?? description, kind: kind)
        return ImportCandidate(
            id: UUID(), rowNumber: rowNumber, date: date, description: description, money: money,
            direction: direction, merchant: suggestion.merchant, kind: kind, category: suggestion.category
        )
    }

    func review(
        candidates: [ImportCandidate], issues: [ImportPreview.Issue] = [],
        account: Account, existing: [Transaction], timeZone: TimeZone
    ) throws -> ImportPreview {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return try ImportPreview(
            candidates: DuplicateDetectionService().review(candidates, accountID: account.id, existing: existing, calendar: calendar),
            issues: issues
        )
    }

    func preview(
        statement: StatementDocument, account: Account, existing: [Transaction], timeZone: TimeZone
    ) throws -> ImportPreview {
        let parser = ImportValueParser()
        var candidates: [ImportCandidate] = []
        for entry in statement.entries {
            try Task.checkCancellation()
            let value = entry.signedAmount
            candidates.append(candidate(
                rowNumber: entry.number,
                date: try parser.date(entry.bookingDate, format: .dotted, timeZone: timeZone),
                description: entry.description,
                money: try Money(amount: value < 0 ? -value : value, currency: statement.currency),
                direction: value < 0 ? .debit : .credit, kind: entry.kind,
                payeeDescription: entry.payeeDescription
            ))
        }
        return try review(candidates: candidates, account: account, existing: existing, timeZone: timeZone)
    }
}
