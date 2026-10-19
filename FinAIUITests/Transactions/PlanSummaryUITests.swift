//
//  PlanSummaryUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 19.10.26.
//

import XCTest

final class PlanSummaryUITests: XCTestCase {
    @MainActor
    func testPlanShowsRecordedBudgetSpendingAndManualGoalProgress() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_CSV"] = "date,description,amount,currency,type\n2026-09-01,REWE MARKT,-25.00,EUR,expense\n2026-09-02,REWE MARKT,5.00,EUR,refund"
        app.launch()
        let account = app.textFields[AccessibilityID.importAccountName]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        account.typeText("Synthetic account\n")
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<10 where !preview.isHittable { app.swipeUp() }
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.collectionViews[AccessibilityID.transactionList].waitForExistence(timeout: 10))
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.buttons["Add to plan"].waitForExistence(timeout: 10))
        app.buttons["Add to plan"].tap()
        app.buttons["Add budget"].tap()
        let limit = app.textFields[AccessibilityID.budgetLimit]
        XCTAssertTrue(limit.waitForExistence(timeout: 10))
        limit.tap()
        limit.typeText("100")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveBudget].tap()
        XCTAssertTrue(app.buttons["Edit budget"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        let budget = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Groceries", "Remaining")).firstMatch
        XCTAssertTrue(budget.waitForExistence(timeout: 10))
        XCTAssertTrue(budget.label.contains("€20.00"), budget.label)
        XCTAssertTrue(budget.label.contains("€80.00"), budget.label)
        app.buttons["Add to plan"].tap()
        app.buttons["Add goal"].tap()
        let name = app.textFields[AccessibilityID.goalName]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Laptop")
        let target = app.textFields[AccessibilityID.goalTarget]
        target.tap()
        target.typeText("1000")
        let saved = app.textFields[AccessibilityID.goalSaved]
        saved.tap()
        let oldValue = try XCTUnwrap(saved.value as? String)
        saved.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count) + "250")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveGoal].tap()
        XCTAssertTrue(app.buttons["Edit goal"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        let goal = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Laptop", "Remaining")).firstMatch
        for _ in 0..<10 where !goal.isHittable { app.swipeUp() }
        XCTAssertTrue(goal.waitForExistence(timeout: 10))
        XCTAssertTrue(goal.label.contains("€250.00"), goal.label)
        XCTAssertTrue(goal.label.contains("€750.00"), goal.label)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Plan-recorded-progress"
        image.lifetime = .keepAlways
        add(image)
        goal.tap()
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(saved.value as? String, "250")
        app.buttons["Close"].tap()
        app.tabBars.buttons["Transactions"].tap()
        let transactions = app.collectionViews[AccessibilityID.transactionList]
        transactions.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Expense")).firstMatch.tap()
        app.buttons[AccessibilityID.editTransaction].tap()
        let amount = app.textFields[AccessibilityID.editTransactionAmount]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        amount.tap()
        let oldAmount = try XCTUnwrap(amount.value as? String)
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldAmount.count) + "45")
        app.buttons[AccessibilityID.saveTransaction].tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 10))
        app.navigationBars["Transaction details"].buttons["Done"].tap()
        app.tabBars.buttons["Plan"].tap()
        for _ in 0..<8 where !budget.isHittable { app.swipeDown() }
        XCTAssertTrue(budget.waitForExistence(timeout: 10))
        XCTAssertTrue(budget.label.contains("€40.00"), budget.label)
        XCTAssertTrue(budget.label.contains("€60.00"), budget.label)
    }
}
