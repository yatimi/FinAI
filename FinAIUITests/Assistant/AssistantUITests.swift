//
//  AssistantUITests.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import XCTest

final class AssistantUITests: XCTestCase {
    @MainActor
    func testPeriodFollowUpWorksWithoutModelAndClearResetsContext() throws {
        continueAfterFailure = false
        let app = launch()
        loadDemo(app)
        app.buttons[AccessibilityID.openAssistant].tap()
        app.buttons[AccessibilityID.assistantThisMonth].tap()
        let month = app.staticTexts[AccessibilityID.assistantAnswerMonth]
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        let currentMonth = month.label
        let followUp = app.buttons[AccessibilityID.assistantFollowUpPeriod]
        XCTAssertTrue(followUp.waitForExistence(timeout: 5))
        followUp.tap()
        XCTAssertTrue(app.buttons["And this month?"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(month.label, currentMonth)
        followUp.tap()
        XCTAssertTrue(app.buttons["And last month?"].waitForExistence(timeout: 5))
        XCTAssertEqual(month.label, currentMonth)
        app.navigationBars.buttons["Clear"].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.assistantThisMonth].waitForExistence(timeout: 5))
        XCTAssertFalse(followUp.exists)
    }

    @MainActor
    func testSuggestedQuestionWorksWithoutModelAndOpensTransactionDetails() throws {
        continueAfterFailure = false
        let app = launch()
        loadDemo(app)
        app.buttons[AccessibilityID.openAssistant].tap()
        XCTAssertTrue(app.navigationBars["Assistant"].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.assistantThisMonth].tap()
        let transactions = app.buttons["\(AccessibilityID.assistantCurrentTransactions)-EUR"]
        let list = app.collectionViews.firstMatch
        for _ in 0..<12 where !transactions.isHittable { list.swipeUp() }
        XCTAssertTrue(transactions.isHittable)
        XCTAssertTrue(app.staticTexts["Selected month net spending"].exists)
        transactions.tap()
        let rows = app.collectionViews[AccessibilityID.assistantTransactions]
        XCTAssertTrue(rows.waitForExistence(timeout: 5))
        let transaction = rows.buttons.firstMatch
        for _ in 0..<8 where !transaction.isHittable { rows.swipeUp() }
        XCTAssertTrue(transaction.isHittable)
        transaction.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.editTransaction].waitForExistence(timeout: 5))
    }

    @MainActor
    func testComparisonWithLargestTextInDarkMode() throws {
        continueAfterFailure = false
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = appearance }
        let app = launch(largeText: true)
        loadDemo(app)
        app.buttons[AccessibilityID.openAssistant].tap()
        let compare = app.buttons[AccessibilityID.assistantCompare]
        let list = app.collectionViews.firstMatch
        for _ in 0..<10 where !compare.isHittable { list.swipeUp() }
        XCTAssertTrue(compare.isHittable)
        compare.tap()
        let changes = app.staticTexts["Recorded changes by category"]
        for _ in 0..<18 where !changes.isHittable { list.swipeUp() }
        XCTAssertTrue(changes.isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Assistant-comparison-largest-text-dark"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.navigationBars.buttons["Clear"].tap()
        XCTAssertFalse(changes.exists)
    }

    @MainActor
    private func launch(largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    @MainActor
    private func loadDemo(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
    }
}
