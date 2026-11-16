//
//  TransactionEditTests.swift
//  FinAITests
//
//  Created by Tommy on 07.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct TransactionEditTests {
    @Test func draftRoundTripsExactAmountsAndValidatesLocale() throws {
        let transaction = try TestFixtures.transaction(amount: try #require(Decimal(string: "123456789.123456789")))
        for locale in [Locale(identifier: "en_US"), Locale(identifier: "de_DE")] {
            var draft = TransactionEditDraft(transaction: transaction, locale: locale)
            #expect(try draft.transaction(replacing: transaction, locale: locale) == transaction)
            draft.amount = locale.decimalSeparator == "," ? "2.345,67" : "2,345.67"
            draft.merchant = " Corrected merchant "
            draft.currencyCode = " usd "
            let edited = try draft.transaction(replacing: transaction, locale: locale)
            #expect(edited.money == (try Money(amount: #require(Decimal(string: "2345.67")), currency: .usd)))
            #expect(edited.merchant == "Corrected merchant")
            #expect(edited.id == transaction.id && edited.rawDescription == transaction.rawDescription && edited.source == transaction.source)
        }
    }

    @Test(arguments: ["-1", "bad", "1.1234567890123456789", "1e100", "NaN"])
    func invalidAmountsNeverProduceATransaction(_ amount: String) throws {
        let transaction = try TestFixtures.transaction(amount: 10)
        var draft = TransactionEditDraft(transaction: transaction, locale: Locale(identifier: "en_US"))
        draft.amount = amount
        #expect(throws: TransactionEditError.invalidAmount) { try draft.transaction(replacing: transaction, locale: Locale(identifier: "en_US")) }
    }

    @Test func emptyMerchantCurrencyAndDirectionAreReviewableErrors() throws {
        let transaction = try TestFixtures.transaction(amount: 10)
        let locale = Locale(identifier: "en_US")
        var draft = TransactionEditDraft(transaction: transaction, locale: locale)
        draft.merchant = " \n "
        #expect(throws: TransactionEditError.missingMerchant) { try draft.transaction(replacing: transaction, locale: locale) }
        draft.merchant = "Merchant"
        draft.currencyCode = "INVALID"
        #expect(throws: TransactionEditError.invalidCurrency) { try draft.transaction(replacing: transaction, locale: locale) }
        draft.currencyCode = "EUR"
        draft.kind = .income
        #expect(throws: TransactionEditError.invalidDirection) { try draft.transaction(replacing: transaction, locale: locale) }
        draft.direction = .credit
        draft.incomeKind = .salary
        #expect(try draft.transaction(replacing: transaction, locale: locale).incomeKind == .salary)
        draft.kind = .refund
        #expect(try draft.transaction(replacing: transaction, locale: locale).incomeKind == nil)
    }

    @Test func correctionChecksAccountAndConflictAndPreservesFirstOriginal() throws {
        let account = ImportFixtures.account
        let transaction = try TestFixtures.transaction(amount: 10, accountID: account.id)
        let snapshot = FinanceSnapshot(accounts: [account], transactions: [transaction])
        let locale = Locale(identifier: "en_US")
        var draft = TransactionEditDraft(transaction: transaction, locale: locale)
        draft.amount = "20"
        let edited = try draft.transaction(replacing: transaction, locale: locale)
        let service = TransactionEditService()
        let saved = try service.replacing(transaction, with: edited, in: snapshot)
        #expect(saved.originalTransactions == [transaction])
        #expect(throws: TransactionEditError.storageChanged) { try service.replacing(transaction, with: edited, in: saved) }
        draft.amount = "30"
        let second = try service.replacing(edited, with: draft.transaction(replacing: edited, locale: locale), in: saved)
        #expect(second.originalTransactions == [transaction])
        draft.accountID = UUID()
        #expect(throws: TransactionEditError.invalidAccount) {
            try service.replacing(transaction, with: draft.transaction(replacing: transaction, locale: locale), in: snapshot)
        }
    }

    @Test func correctionRejectsTotalsThatLosePrecision() throws {
        let transaction = try TestFixtures.transaction(amount: 1, accountID: ImportFixtures.account.id)
        let other = try TestFixtures.transaction(amount: try #require(Decimal(string: "0.01")), accountID: ImportFixtures.account.id)
        var draft = TransactionEditDraft(transaction: transaction, locale: Locale(identifier: "en_US"))
        draft.amount = "99999999999999999999999999999999999999"
        let edited = try draft.transaction(replacing: transaction, locale: Locale(identifier: "en_US"))
        #expect(throws: TransactionEditError.unsupportedTotals) {
            try TransactionEditService().replacing(transaction, with: edited, in: FinanceSnapshot(accounts: [ImportFixtures.account], transactions: [transaction, other]))
        }
    }
}
