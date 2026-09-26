//
//  ImportError.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

enum ImportError: Error, Equatable {
    case unreadableFile, fileTooLarge, unsupportedEncoding, malformedCSV
    case emptyFile, tooManyRows, tooManyColumns, fieldTooLong, invalidMapping
    case invalidAmount, invalidDate, invalidCurrency, invalidKind, missingDescription
    case inconsistentDirection, invalidAccount, emptySelection, storageChanged, unsupportedTotals
}
