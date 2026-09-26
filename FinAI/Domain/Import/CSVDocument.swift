//
//  CSVDocument.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CSVDocument: Equatable, Sendable {
    struct Row: Equatable, Sendable {
        let number: Int
        let fields: [String]
    }
    let name: String
    let headers: [String]
    let rows: [Row]
    let delimiter: CSVDelimiter
}
