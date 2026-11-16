//
//  AssistantScopeUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 30.10.26.
//

import XCTest

final class AssistantScopeUITests: XCTestCase {
    @MainActor
    func testCategoryRentExclusionAndMonthFollowUpKeepMatchingTransactions() {
        continueAfterFailure = false
        let app = launch()
        app.buttons["Spending by category"].tap()
        app.buttons["Groceries"].tap()
        assertTotal("108.29", in: app)
        excludeRent(in: app)
        let month = app.staticTexts[AccessibilityID.assistantAnswerMonth]
        reveal(month, in: app, upward: false)
        let selected = month.label
        let followUp = app.buttons[AccessibilityID.assistantFollowUpPeriod]
        reveal(followUp, in: app, upward: false)
        followUp.tap()
        XCTAssertTrue(app.buttons["And this month?"].waitForExistence(timeout: 10))
        XCTAssertNotEqual(month.label, selected)
        XCTAssertTrue(app.staticTexts["Groceries"].exists)
        assertTotal("108.29", in: app)
        let transactions = app.buttons["\(AccessibilityID.assistantCurrentTransactions)-EUR"]
        reveal(transactions, in: app)
        transactions.tap()
        let list = app.collectionViews[AccessibilityID.assistantTransactions]
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        XCTAssertEqual(list.buttons.count, 2)
        XCTAssertEqual(list.buttons.matching(NSPredicate(format: "label CONTAINS %@", "REWE")).count, 2)
        XCTAssertEqual(list.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Demo rent")).count, 0)
    }

    @MainActor
    func testRentExclusionWithLargestTextInDarkMode() {
        continueAfterFailure = false
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = appearance }
        let app = launch(largeText: true)
        let question = app.buttons[AccessibilityID.assistantThisMonth]
        reveal(question, in: app); question.tap()
        excludeRent(in: app)
        assertTotal("661.48", in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Assistant-rent-exclusion-largest-text-dark"
        attachment.lifetime = .keepAlways
        add(attachment)
        let remove = app.buttons["Include the excluded merchant again"]
        reveal(remove, in: app, upward: false)
        remove.tap()
        assertTotal("1,711.48", in: app)
        XCTAssertFalse(app.staticTexts["Excluded merchant"].exists)
    }

    @MainActor
    private func excludeRent(in app: XCUIApplication) {
        let withoutRent = app.buttons["Without rent…"]
        reveal(withoutRent, in: app)
        withoutRent.tap()
        let rent = app.buttons["Demo rent"]
        reveal(rent, in: app)
        rent.tap()
        let excluded = app.staticTexts["Excluded merchant"]
        reveal(excluded, in: app)
        XCTAssertTrue(excluded.exists)
        XCTAssertTrue(app.staticTexts["Demo rent"].exists)
    }

    @MainActor
    private func assertTotal(_ amount: String, in app: XCUIApplication) {
        let total = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                                        "Selected month net spending", amount)).firstMatch
        reveal(total, in: app)
        XCTAssertTrue(total.exists)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, upward: Bool = true) {
        for _ in 0..<18 {
            if element.isHittable { break }
            if element.exists, !element.frame.isEmpty {
                if element.frame.midY < app.frame.midY { app.swipeDown() } else { app.swipeUp() }
            } else if upward { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func launch(largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.buttons[AccessibilityID.openAssistant].tap()
        return app
    }
}
