//
//  CSVParser.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CSVParser: Sendable {
    static let maximumBytes = 2 * 1024 * 1024
    static let maximumRows = 5_000
    static let maximumColumns = 64
    static let maximumFieldLength = 8_192

    func parse(_ text: String, name: String, delimiter: CSVDelimiter? = nil) throws -> CSVDocument {
        guard text.utf8.count <= Self.maximumBytes else { throw ImportError.fileTooLarge }
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let input = normalized.hasPrefix("\u{FEFF}") ? String(normalized.dropFirst()) : normalized
        if let delimiter { return try parseDocument(input, name: name, delimiter: delimiter) }
        // Delimiters are counted only outside quoted fields in the header record.
        var counts: [CSVDelimiter: Int] = [:]
        var quoted = false
        for character in input {
            if character == "\"" { quoted.toggle() }
            if character == "\n", !quoted { break }
            if !quoted, let separator = CSVDelimiter(rawValue: String(character)) { counts[separator, default: 0] += 1 }
        }
        let chosen = CSVDelimiter.allCases.max { counts[$0, default: 0] < counts[$1, default: 0] } ?? .comma
        return try parseDocument(input, name: name, delimiter: chosen)
    }

    private func parseDocument(_ text: String, name: String, delimiter: CSVDelimiter) throws -> CSVDocument {
        var records: [CSVDocument.Row] = []
        var fields: [String] = []
        var field = ""
        var quoted = false
        var closedQuote = false
        var whitespaceAfterQuote = false
        var recordNumber = 1
        var recordHasContent = false

        func appendField() throws {
            guard fields.count < Self.maximumColumns else { throw ImportError.tooManyColumns }
            fields.append(field)
            field = ""
            closedQuote = false
            whitespaceAfterQuote = false
        }
        func appendRecord() throws {
            try appendField()
            if recordHasContent || fields.count > 1 || fields.contains(where: { !$0.isEmpty }) {
                guard records.count <= Self.maximumRows else { throw ImportError.tooManyRows }
                records.append(.init(number: recordNumber, fields: fields))
            }
            fields = []
            recordNumber += 1
            recordHasContent = false
        }

        for (offset, character) in text.enumerated() {
            if offset.isMultiple(of: 1024) { try Task.checkCancellation() }
            if quoted {
                if character == "\"" { quoted = false; closedQuote = true; whitespaceAfterQuote = false }
                else { field.append(character) }
            } else if closedQuote {
                if character == "\"" {
                    guard !whitespaceAfterQuote else { throw ImportError.malformedCSV }
                    field.append(character); quoted = true; closedQuote = false
                }
                else if character == delimiter.character { try appendField(); recordHasContent = true }
                else if character == "\n" { try appendRecord() }
                else if character == " " { whitespaceAfterQuote = true }
                else { throw ImportError.malformedCSV }
            } else if character == "\"" {
                guard field.isEmpty else { throw ImportError.malformedCSV }
                quoted = true
                recordHasContent = true
            } else if character == delimiter.character {
                try appendField()
                recordHasContent = true
            } else if character == "\n" {
                try appendRecord()
            } else {
                field.append(character)
                recordHasContent = true
            }
            guard field.utf8.count <= Self.maximumFieldLength else { throw ImportError.fieldTooLong }
        }
        guard !quoted else { throw ImportError.malformedCSV }
        if recordHasContent || !fields.isEmpty || !field.isEmpty { try appendRecord() }
        guard let header = records.first, records.count > 1 else { throw ImportError.emptyFile }
        return CSVDocument(name: name, headers: header.fields, rows: Array(records.dropFirst()), delimiter: delimiter)
    }
}
