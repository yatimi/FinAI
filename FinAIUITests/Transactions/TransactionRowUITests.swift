//
//  TransactionRowUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 19.10.26.
//

import XCTest

final class TransactionRowUITests: XCTestCase {
    @MainActor
    func testCompactRowsPreserveTypeDirectionCurrencyAndDetails() throws {
        try exerciseRows(largeText: false)
    }

    @MainActor
    func testRowsReflowWithLongMerchantAndAccessibilityText() throws {
        try exerciseRows(largeText: true)
    }

    @MainActor
    private func exerciseRows(largeText: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        let merchant = "Synthetic merchant with a deliberately long store name"
        app.launchEnvironment["FINAI_TEST_CSV"] = """
            date,description,amount,currency,type
            2026-09-01,Synthetic salary,3400.00,EUR,income
            2026-09-02,\(merchant),-9876543.21,USD,expense
            2026-09-03,Synthetic refund,25.00,USD,refund
            2026-09-04,Synthetic transfer,-100.00,EUR,transfer
            """
        app.launch()
        XCTAssertTrue(app.navigationBars["Import transactions"].waitForExistence(timeout: 15))
        let account = app.textFields[AccessibilityID.importAccountName]
        for _ in 0..<12 where !account.isHittable { app.swipeUp() }
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        account.typeText("Synthetic account\n")
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<12 where !preview.isHittable { app.swipeUp() }
        XCTAssertTrue(preview.isHittable)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        let list = app.collectionViews[AccessibilityID.transactionList]
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        for (name, kind, direction, currency) in [
            ("Synthetic transfer", "Transfer", "Money out", "EUR"),
            ("Synthetic refund", "Refund", "Money in", "USD"),
            (merchant, "Expense", "Money out", "USD"),
            ("Synthetic salary", "Income", "Money in", "EUR")
        ] {
            let row = list.buttons.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
            for _ in 0..<14 where !row.isHittable { list.swipeUp() }
            XCTAssertTrue(row.isHittable, name)
            XCTAssertTrue(row.label.contains(kind), row.label)
            XCTAssertTrue(row.label.contains(direction), row.label)
            XCTAssertTrue(row.label.contains(currency), row.label)
            if name == merchant {
                XCTAssertTrue(row.label.contains("9,876,543.21"), row.label)
                let amount = list.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "9,876,543.21")).firstMatch
                for _ in 0..<10 where !amount.isHittable { list.swipeUp() }
                XCTAssertTrue(amount.isHittable)
                let image = XCTAttachment(screenshot: app.screenshot())
                image.name = largeText ? "Transactions-accessibility-text" : "Transactions-compact"
                image.lifetime = .keepAlways
                add(image)
            }
        }
        let salary = list.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Synthetic salary")).firstMatch
        salary.tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Income"].exists)
    }
}
