//
//  DuplicateDetectionService.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation

/// Review hints only: matching never mutates or merges transactions.
struct DuplicateDetectionService: Sendable {
    func review(
        _ candidates: [ImportCandidate], accountID: UUID,
        existing: [Transaction], calendar: Calendar
    ) throws -> [ImportCandidate] {
        var index: [Key: [Entry]] = [:]
        for transaction in existing where transaction.accountID == accountID {
            try Task.checkCancellation()
            let key = Key(money: transaction.money, direction: transaction.direction, day: calendar.startOfDay(for: transaction.date))
            index[key, default: []].append(Entry(
                source: .savedTransaction(transaction.id), date: transaction.date,
                description: transaction.rawDescription, kind: transaction.kind
            ))
        }
        var reviewed: [ImportCandidate] = []
        for var candidate in candidates {
            try Task.checkCancellation()
            let entry = Entry(source: .importRow(candidate.rowNumber), date: candidate.date, description: candidate.description, kind: candidate.kind)
            let day = calendar.startOfDay(for: candidate.date)
            var matches: [ImportDuplicateMatch] = []
            for offset in -3...3 {
                guard let nearby = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
                let key = Key(money: candidate.money, direction: candidate.direction, day: nearby)
                for other in index[key] ?? [] {
                    try Task.checkCancellation()
                    guard let reason = reason(entry, other, sameDay: offset == 0) else { continue }
                    matches.append(ImportDuplicateMatch(source: other.source, reason: reason, date: other.date, description: other.description))
                    matches.sort(by: precedes)
                    if matches.count > 3 { matches.removeLast() }
                }
            }
            candidate.duplicateMatches = matches
            reviewed.append(candidate)
            let key = Key(money: candidate.money, direction: candidate.direction, day: day)
            index[key, default: []].append(entry)
        }
        return reviewed
    }

    private func reason(_ lhs: Entry, _ rhs: Entry, sameDay: Bool) -> ImportDuplicateMatch.Reason? {
        if lhs.date == rhs.date && lhs.description.trimmingCharacters(in: .whitespacesAndNewlines)
            == rhs.description.trimmingCharacters(in: .whitespacesAndNewlines) { return .exact }
        guard lhs.kind == rhs.kind || lhs.kind == .unknown || rhs.kind == .unknown,
              !lhs.tokens.isEmpty, lhs.numbers == rhs.numbers else { return nil }
        if lhs.tokens == rhs.tokens { return sameDay ? .similarDescription : .nearbyDate }
        guard let merchant = lhs.knownMerchant, merchant == rhs.knownMerchant else { return nil }
        let left = Set(lhs.tokens), right = Set(rhs.tokens)
        let shared = left.intersection(right).count
        // Dice similarity >= 0.8, with at least three shared tokens. Use integer arithmetic.
        guard shared >= 3, 5 * shared >= 2 * (left.count + right.count) else { return nil }
        return sameDay ? .similarDescription : .nearbyDate
    }

    private func precedes(_ lhs: ImportDuplicateMatch, _ rhs: ImportDuplicateMatch) -> Bool {
        if lhs.reason != rhs.reason { return lhs.reason.rawValue < rhs.reason.rawValue }
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        switch (lhs.source, rhs.source) {
        case let (.savedTransaction(left), .savedTransaction(right)): return left.uuidString < right.uuidString
        case let (.importRow(left), .importRow(right)): return left < right
        case (.savedTransaction, .importRow): return true
        case (.importRow, .savedTransaction): return false
        }
    }

    private struct Key: Hashable {
        let amount: Decimal
        let currency: Currency
        let direction: Transaction.Direction
        let day: Date
        init(money: Money, direction: Transaction.Direction, day: Date) {
            amount = money.amount
            currency = money.currency
            self.direction = direction
            self.day = day
        }
    }

    private struct Entry {
        let source: ImportDuplicateMatch.Source
        let date: Date
        let description: String
        let kind: Transaction.Kind
        let tokens: [String]
        let numbers: [String]
        let knownMerchant: String?

        init(source: ImportDuplicateMatch.Source, date: Date, description: String, kind: Transaction.Kind) {
            self.source = source
            self.date = date
            self.description = description
            self.kind = kind
            tokens = description.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                .split { !$0.isLetter && !$0.isNumber }.map(String.init)
            numbers = tokens.filter { $0.contains(where: \.isNumber) }
            knownMerchant = MerchantKnowledge.standard.match(description)?.name
        }
    }
}
