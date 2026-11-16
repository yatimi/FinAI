//
//  DebtsUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 25.10.26.
//

import XCTest

final class DebtsUITests: XCTestCase {
    @MainActor
    func testCreatePartialRepaymentAndSettlement() throws {
        try exerciseDebt(largeText: false)
    }

    @MainActor
    func testDebtInDarkModeWithAccessibilityText() throws {
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = appearance }
        try exerciseDebt(largeText: true)
    }

    @MainActor
    private func exerciseDebt(largeText: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plan"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Plan"].tap()
        app.buttons["Personal debts"].tap()
        let add = app.buttons["Add debt"]
        reveal(add, in: app)
        add.tap()
        let person = app.textFields["Person"]
        reveal(person, in: app)
        person.tap(); person.typeText("Alex")
        app.buttons["Done"].tap()
        let amount = app.textFields["Original debt amount"]
        reveal(amount, in: app)
        amount.tap(); amount.typeText("100")
        app.buttons["Done"].tap()
        let save = app.buttons["Save debt"]
        reveal(save, in: app); save.tap()
        let alex = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Alex")).firstMatch
        XCTAssertTrue(alex.waitForExistence(timeout: 10))
        reveal(alex, in: app); alex.tap()
        try repay("30", app: app)
        XCTAssertTrue(alex.waitForExistence(timeout: 10))
        reveal(alex, in: app)
        // Disclosure expansion is view state; reopen only if its contents are collapsed.
        if !app.staticTexts["Repayment history"].exists { alex.tap() }
        let remaining = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Remaining debt", "70.00")).firstMatch
        reveal(remaining, in: app)
        XCTAssertTrue(remaining.exists)
        let history = app.staticTexts["Repayment history"]
        reveal(history, in: app)
        XCTAssertTrue(history.exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = largeText ? "Debt-dark-accessibility" : "Debt-partial-repayment"
        image.lifetime = .keepAlways
        self.add(image)
        app.buttons["Close"].tap()
        app.buttons["Personal debts"].tap()
        XCTAssertTrue(alex.waitForExistence(timeout: 10))
        reveal(alex, in: app); alex.tap()
        try repay("70", app: app)
        XCTAssertTrue(alex.waitForExistence(timeout: 10))
        reveal(alex, in: app)
        if !app.staticTexts["Settled"].exists { alex.tap() }
        let settled = app.staticTexts["Settled"]
        reveal(settled, in: app)
        XCTAssertTrue(settled.exists)
        XCTAssertFalse(app.buttons["Record repayment"].exists)
    }

    @MainActor
    private func repay(_ amount: String, app: XCUIApplication) throws {
        let record = app.buttons["Record repayment"]
        reveal(record, in: app); record.tap()
        let input = app.textFields["Repayment amount"]
        reveal(input, in: app); input.tap(); input.typeText(amount)
        app.buttons["Done"].tap()
        let save = app.buttons["Save repayment"]
        reveal(save, in: app); save.tap()
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(element.isHittable)
    }
}
