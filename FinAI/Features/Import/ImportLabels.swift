//
//  ImportLabels.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

extension ImportError {
    var message: LocalizedStringResource {
        switch self {
        case .unreadableFile: "The file could not be read. Choose it again and check access in Files."
        case .fileTooLarge: "Choose a file smaller than 2 MB."
        case .unsupportedEncoding: "Use a UTF-8 or UTF-16 CSV file."
        case .malformedCSV: "The row has invalid CSV formatting or a different number of columns."
        case .emptyFile: "The file needs a header and at least one data row."
        case .tooManyRows: "A file can contain up to 5,000 data rows."
        case .tooManyColumns: "A file can contain up to 64 columns."
        case .fieldTooLong: "A CSV field is too long."
        case .invalidMapping: "Choose different columns for date, amount and description."
        case .invalidAmount: "The amount does not match the selected number format or exceeds supported precision."
        case .invalidDate: "The date does not match the selected format or is not a valid calendar date."
        case .invalidCurrency: "Use a supported three-letter currency code, such as EUR or USD."
        case .invalidKind: "The type must be expense, income, transfer, refund, adjustment or unknown."
        case .missingDescription: "The description is empty."
        case .inconsistentDirection: "The transaction type conflicts with the selected money direction."
        case .invalidAccount: "Choose an account or enter a new account name of up to 100 characters."
        case .emptySelection: "Select at least one valid transaction."
        case .unsupportedTotals: "These amounts cannot be combined with your saved data without losing precision. Check the amounts and number format."
        case .storageChanged: "The import could not be saved. Your previous data is preserved. Try again or reopen the import."
        }
    }
}

extension CSVMapping.DirectionRule {
    var title: LocalizedStringResource {
        switch self {
        case .signed: "Negative out, positive in"
        case .moneyOut: "All amounts are money out"
        case .moneyIn: "All amounts are money in"
        }
    }
}
