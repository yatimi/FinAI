//
//  TransactionEditLabels.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import Foundation

extension TransactionEditError {
    var message: LocalizedStringResource {
        switch self {
        case .missingMerchant: .transactionEditMissingMerchant
        case .invalidAmount: .transactionEditInvalidAmount
        case .invalidCurrency: .transactionEditInvalidCurrency
        case .invalidDate: .transactionEditInvalidDate
        case .invalidDirection: .transactionEditInvalidDirection
        case .invalidAccount: .transactionEditInvalidAccount
        case .unsupportedTotals: .transactionEditUnsupportedTotals
        case .storageChanged: .transactionEditStorageChanged
        case .saving: .transactionEditSaveFailed
        }
    }
}

extension Transaction.IncomeKind {
    var title: LocalizedStringResource {
        switch self {
        case .salary: .salaryIncome
        case .freelance: .freelanceIncome
        case .bonus: .bonusIncome
        case .interest: .interestIncome
        case .reimbursement: .reimbursementIncome
        case .other: .other
        }
    }
}
