//
//  ImportValueParser.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct ImportValueParser: Sendable {
    func amount(_ text: String, separator: CSVMapping.DecimalSeparator) throws -> Decimal {
        var input = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
        let decimal = separator.rawValue
        let grouping = separator == .dot ? "," : "."
        let escapedDecimal = NSRegularExpression.escapedPattern(for: decimal)
        let escapedGroup = NSRegularExpression.escapedPattern(for: grouping)
        let pattern = "^[+-]?(?:[0-9]+|[0-9]{1,3}(?:" + escapedGroup + "[0-9]{3})+|[0-9]{1,3}(?: [0-9]{3})+)(?:" + escapedDecimal + "[0-9]+)?$"
        guard input.range(of: pattern, options: .regularExpression) != nil else { throw ImportError.invalidAmount }
        input = input.replacingOccurrences(of: grouping, with: "").replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: decimal, with: ".")
        // Decimal has a bounded significand. Reject values that could be silently rounded by parsing.
        let digits = input.filter(\.isNumber).drop(while: { $0 == "0" })
        guard digits.count <= 38,
              let value = Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN else {
            throw ImportError.invalidAmount
        }
        let fractionalDigits = input.split(separator: ".", omittingEmptySubsequences: false).dropFirst().first?.count ?? 0
        guard fractionalDigits <= 18 else { throw ImportError.invalidAmount }
        return value
    }

    func date(_ text: String, format: CSVMapping.DateFormat, timeZone: TimeZone) throws -> Date {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format.rawValue
        formatter.isLenient = false
        guard let date = formatter.date(from: input), formatter.string(from: date) == input else {
            throw ImportError.invalidDate
        }
        return date
    }
}
