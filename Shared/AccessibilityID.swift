//
//  AccessibilityID.swift
//  FinAI
//
//  Created by Tommy on 04.10.26.
//

/// Stable automation identifiers shared by the app and its UI tests.
enum AccessibilityID {
    static let editTransaction = "editTransaction"
    static let saveTransaction = "saveTransaction"
    static let editTransactionMerchant = "editTransactionMerchant"
    static let editTransactionAmount = "editTransactionAmount"
    static let editTransactionCurrency = "editTransactionCurrency"
    static let transactionEditError = "transactionEditError"
    static let compactImportReview = "compactImportReview"
    static func importDetails(row: Int) -> String { "importDetails-\(row)" }

    static let dataError = "dataError"
    static let openImport = "openImport"
    static let openRecurringPayments = "openRecurringPayments"
    static let spendingAnalytics = "spendingAnalytics"
    static let recurringPayments = "recurringPayments"
    static let importError = "importError"
    static let chooseCSV = "chooseCSV"
    static let previewImport = "previewImport"
    static let confirmSelectedImport = "confirmSelectedImport"
    static let loadDemo = "loadDemo"
    static let dashboard = "dashboard"
    static let importAccountName = "importAccountName"
    static let importCurrency = "importCurrency"
    static let rulePattern = "rulePattern"
    static let ruleMerchant = "ruleMerchant"
    static let saveMerchantRule = "saveMerchantRule"
    static let transactionList = "transactionList"
    static let transactionFilters = "transactionFilters"
    static let resetTransactionFilters = "resetTransactionFilters"

    static func duplicateDecision(row: Int) -> String { "duplicateDecision-\(row)" }
    static func saveRule(row: Int) -> String { "saveRule-\(row)" }
}
