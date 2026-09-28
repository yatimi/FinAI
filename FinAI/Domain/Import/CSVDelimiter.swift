//
//  CSVDelimiter.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

enum CSVDelimiter: String, CaseIterable, Sendable {
    case comma = ","
    case semicolon = ";"
    case tab = "\t"
    var character: Character { Character(rawValue) }
}
