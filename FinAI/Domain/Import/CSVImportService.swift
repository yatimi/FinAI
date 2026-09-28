//
//  CSVImportService.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CSVImportService: Sendable {
    var classification = TransactionClassificationService()

    func preview(
        document: CSVDocument, mapping: CSVMapping, account: Account,
        existing: [Transaction], timeZone: TimeZone
    ) throws -> ImportPreview {
        try mapping.validate(columnCount: document.headers.count)
        var candidates: [ImportCandidate] = []
        var issues: [ImportPreview.Issue] = []
        var seen = Set(existing.filter { $0.accountID == account.id }.map(Fingerprint.init))
        let parser = ImportValueParser()
        for row in document.rows {
            try Task.checkCancellation()
            do {
                guard row.fields.count == document.headers.count else { throw ImportError.malformedCSV }
                let description = row.fields[mapping.descriptionColumn]
                guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ImportError.missingDescription }
                let value = try parser.amount(row.fields[mapping.amountColumn], separator: mapping.decimalSeparator)
                let date = try parser.date(row.fields[mapping.dateColumn], format: mapping.dateFormat, timeZone: timeZone)
                let code = mapping.currencyColumn >= 0 ? row.fields[mapping.currencyColumn].trimmingCharacters(in: .whitespacesAndNewlines).uppercased() : mapping.currencyCode
                guard let currency = try? Currency(code: code) else { throw ImportError.invalidCurrency }
                let direction: Transaction.Direction
                switch mapping.directionRule {
                case .signed: direction = value < 0 ? .debit : .credit
                case .moneyOut: direction = .debit
                case .moneyIn: direction = .credit
                }
                let kind: Transaction.Kind
                if mapping.kindColumn >= 0 {
                    guard let parsed = Transaction.Kind(rawValue: row.fields[mapping.kindColumn].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else {
                        throw ImportError.invalidKind
                    }
                    kind = parsed
                } else { kind = mapping.defaultKind }
                guard (kind != .expense || direction == .debit),
                      ((kind != .income && kind != .refund) || direction == .credit) else {
                    throw ImportError.inconsistentDirection
                }
                let money = try Money(amount: value < 0 ? -value : value, currency: currency)
                let fingerprint = Fingerprint(date: date, description: description, amount: money.amount, currency: currency, direction: direction)
                let duplicate = !seen.insert(fingerprint).inserted
                let suggestion = classification.suggest(description: description, kind: kind)
                candidates.append(ImportCandidate(
                    id: UUID(), rowNumber: row.number, date: date, description: description, money: money,
                    direction: direction, merchant: suggestion.merchant, kind: kind, category: suggestion.category,
                    isPossibleDuplicate: duplicate
                ))
            } catch let error as ImportError {
                issues.append(.init(rowNumber: row.number, error: error))
            }
        }
        return ImportPreview(candidates: candidates, issues: issues)
    }

    private struct Fingerprint: Hashable {
        let date: Date
        let description: String
        let amount: Decimal
        let currency: Currency
        let direction: Transaction.Direction

        init(date: Date, description: String, amount: Decimal, currency: Currency, direction: Transaction.Direction) {
            self.date = date
            self.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
            self.amount = amount
            self.currency = currency
            self.direction = direction
        }

        init(_ transaction: Transaction) {
            self.init(date: transaction.date, description: transaction.rawDescription, amount: transaction.money.amount,
                      currency: transaction.money.currency, direction: transaction.direction)
        }
    }
}
