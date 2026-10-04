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
        case .unreadableFile: .unreadableImportFileMessage
        case .fileTooLarge: .chooseAFileSmallerThan2Mb
        case .unsupportedEncoding: .useAUtf8OrUtf16CsvFile
        case .malformedCSV: .malformedCSVMessage
        case .emptyFile: .theFileNeedsAHeaderAndAtLeastOneDataRow
        case .tooManyRows: .aFileCanContainUpTo5000DataRows
        case .tooManyColumns: .aFileCanContainUpTo64Columns
        case .fieldTooLong: .aCsvFieldIsTooLong
        case .invalidMapping: .chooseDifferentColumnsForDateAmountAndDescription
        case .invalidAmount: .invalidImportAmountMessage
        case .invalidDate: .invalidImportDateMessage
        case .invalidCurrency: .useASupportedThreeLetterCurrencyCodeSuchAsEurOrUsd
        case .invalidKind: .invalidImportKindMessage
        case .missingDescription: .theDescriptionIsEmpty
        case .missingMerchant: .enterAMerchantOrPayeeForEachSelectedTransaction
        case .inconsistentDirection: .theTransactionTypeConflictsWithTheSelectedMoneyDirection
        case .invalidAccount: .invalidImportAccountMessage
        case .emptySelection: .selectAtLeastOneValidTransaction
        case .unsupportedTotals: .unsupportedImportTotalsMessage
        case .storageChanged: .importStorageChangedMessage
        }
    }
}

extension CSVMapping.DirectionRule {
    var title: LocalizedStringResource {
        switch self {
        case .signed: .negativeOutPositiveIn
        case .moneyOut: .allAmountsAreMoneyOut
        case .moneyIn: .allAmountsAreMoneyIn
        }
    }
}


extension ImportDuplicateMatch.Reason {
    var title: LocalizedStringResource {
        switch self {
        case .exact: .sameDateAmountAndOriginalDescription
        case .similarDescription: .sameDayAndAmountWithASimilarDescription
        case .nearbyDate: .sameAmountAndASimilarDescriptionWithinThreeDays
        }
    }
}
