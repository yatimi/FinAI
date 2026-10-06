//
//  SparkasseStatementParser.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import Foundation

/// Supports the German Sparkasse table headed “Datum Erläuterung Betrag EUR”.
/// Rejects incomplete or ambiguous extraction instead of importing a partial statement.
struct SparkasseStatementParser: Sendable {
    func parse(pages: [String], name: String) throws -> StatementDocument {
        guard !pages.isEmpty, pages.count <= 100 else { throw ImportError.unsupportedStatement }
        guard pages.reduce(0, { $0 + $1.utf8.count }) <= CSVParser.maximumBytes else { throw ImportError.pdfTooLarge }
        let currency = Currency.eur
        let values = ImportValueParser()
        let amountPattern = #"^[+-]?(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+),[0-9]{2}$"#
        var entries: [StatementDocument.Entry] = []
        var opening: Money?
        var closing: Money?
        var openingDate: Date?
        var closingDate: Date?
        var running = Money.zero(currency)
        var statementReference: String?
        var accountReference: String?
        var pendingDate: String?
        var pendingLines: [String] = []
        var pendingAmount: Decimal?
        var foundTable = false

        func finishEntry() throws {
            guard let date = pendingDate else { return }
            guard let amount = pendingAmount, let operation = pendingLines.first else { throw ImportError.malformedStatement }
            guard pendingLines.joined(separator: "\n").utf8.count <= CSVParser.maximumFieldLength else { throw ImportError.fieldTooLong }
            let detail = pendingLines.dropFirst().joined(separator: "\n")
            let kind: Transaction.Kind
            if amount < 0 && (operation.hasPrefix("Basis-Lastschr.") || operation.hasPrefix("dig. Karte") || operation.hasPrefix("Kartenzahlung") || operation.hasPrefix("Entgeltabrechnung")) {
                kind = .expense
            } else if operation.hasPrefix("Abrechnung") {
                kind = .adjustment
            } else {
                // A credit can be a refund or an owned-account transfer; direction alone is insufficient.
                kind = .unknown
            }
            entries.append(.init(
                number: entries.count + 2, bookingDate: date, signedAmount: amount,
                description: pendingLines.joined(separator: "\n"),
                payeeDescription: detail.isEmpty ? operation : detail, kind: kind
            ))
            guard entries.count <= CSVParser.maximumRows else { throw ImportError.tooManyRows }
            running = try running.adding(Money(amount: amount, currency: currency))
            pendingDate = nil
            pendingLines = []
            pendingAmount = nil
        }

        for (index, page) in pages.enumerated() {
            try Task.checkCancellation()
            let lines = page.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard lines.contains(where: { $0.contains("Sparkasse") }),
                  let reference = lines.first(where: { $0.range(of: #"^Kontoauszug [0-9]+/[0-9]{4}$"#, options: .regularExpression) != nil }),
                  lines.contains("Seite \(index + 1) von \(pages.count)"),
                  let account = lines.first(where: { $0.range(of: #"DE[0-9]{2}(?: ?[0-9]){18}"#, options: .regularExpression) != nil }) else {
                throw ImportError.unsupportedStatement
            }
            // Compare only the account/IBAN prefix; the first page omits the account holder.
            let accountPrefix = String(account.split(separator: ",").prefix(2).joined(separator: ","))
            if let statementReference, statementReference != reference { throw ImportError.unsupportedStatement }
            if let accountReference, accountReference != accountPrefix { throw ImportError.unsupportedStatement }
            statementReference = reference
            accountReference = accountPrefix
            guard let header = lines.firstIndex(of: "Datum Erläuterung Betrag EUR") else {
                guard closing != nil, pendingDate == nil,
                      lines.contains(where: { $0.contains("Anlage") }) else { throw ImportError.unsupportedStatement }
                continue
            }
            guard closing == nil else { throw ImportError.malformedStatement }
            foundTable = true
            var reachedFooter = false
            for line in lines.dropFirst(header + 1) {
                try Task.checkCancellation()
                if line.hasPrefix("Postanschrift:") {
                    reachedFooter = true
                    break
                }
                if line.hasPrefix("Kontostand am ") {
                    try finishEntry()
                    guard let range = line.range(of: #"[+-]?(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+),[0-9]{2}$"#, options: .regularExpression) else {
                        throw ImportError.malformedStatement
                    }
                    let balance = try Money(amount: values.amount(String(line[range]), separator: .comma), currency: currency)
                    guard let dateRange = line.range(of: #"[0-9]{2}\.[0-9]{2}\.[0-9]{4}"#, options: .regularExpression) else { throw ImportError.malformedStatement }
                    let balanceDate = try values.date(String(line[dateRange]), format: .dotted, timeZone: .gmt)
                    if opening == nil && entries.isEmpty {
                        opening = balance
                        openingDate = balanceDate
                    } else if closing == nil {
                        closing = balance
                        closingDate = balanceDate
                    } else { throw ImportError.malformedStatement }
                    continue
                }
                if closing != nil {
                    guard line.range(of: #"^[0-9]{2}\.[0-9]{2}\.[0-9]{4}"#, options: .regularExpression) == nil,
                          line.range(of: amountPattern, options: .regularExpression) == nil else { throw ImportError.malformedStatement }
                    continue
                }
                if let range = line.range(of: #"^[0-9]{2}\.[0-9]{2}\.[0-9]{4}"#, options: .regularExpression) {
                    try finishEntry()
                    guard opening != nil else { throw ImportError.malformedStatement }
                    let date = String(line[range])
                    _ = try values.date(date, format: .dotted, timeZone: .gmt)
                    let operation = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    guard !operation.isEmpty else { throw ImportError.malformedStatement }
                    pendingDate = date
                    pendingLines = [operation]
                } else if line.range(of: amountPattern, options: .regularExpression) != nil {
                    guard pendingDate != nil, pendingAmount == nil else { throw ImportError.malformedStatement }
                    pendingAmount = try values.amount(line, separator: .comma)
                } else {
                    guard pendingDate != nil, pendingAmount == nil else { throw ImportError.malformedStatement }
                    pendingLines.append(line)
                    guard pendingLines.joined(separator: "\n").utf8.count <= CSVParser.maximumFieldLength else { throw ImportError.fieldTooLong }
                }
            }
            guard reachedFooter else { throw ImportError.malformedStatement }
            // Retain an unfinished description across a page break, but finalize a completed row.
            if pendingAmount != nil { try finishEntry() }
        }
        guard foundTable, pendingDate == nil, let opening, let closing, let openingDate, let closingDate,
              openingDate <= closingDate else { throw ImportError.malformedStatement }
        for entry in entries {
            let date = try values.date(entry.bookingDate, format: .dotted, timeZone: .gmt)
            guard date > openingDate, date <= closingDate else { throw ImportError.malformedStatement }
        }
        guard try opening.adding(running) == closing else { throw ImportError.statementBalanceMismatch }
        return StatementDocument(name: name, currency: currency, entries: entries)
    }
}
