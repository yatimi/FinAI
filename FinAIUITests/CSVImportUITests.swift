//
//  CSVImportUITests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import XCTest

final class CSVImportUITests: XCTestCase {
    @MainActor
    func testPreviewCancelAndConfirmImport() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_CSV"] = "date,description,amount,currency,type\n2026-09-01,Test coffee,-12.50,EUR,expense\n2026-09-02,Test employer,1000,EUR,income\n2026-09-03,Invalid,bad,EUR,expense\n"
        app.launch()
        let accountName = app.textFields["importAccountName"]
        XCTAssertTrue(accountName.waitForExistence(timeout: 15))
        accountName.tap()
        accountName.typeText("Test bank")
        app.keyboards.buttons["Done"].tap()
        let preview = app.buttons["previewImport"]
        for _ in 0..<8 {
            if preview.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(preview.isHittable)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Selected transactions: 2"].exists)
        XCTAssertTrue(app.staticTexts["Invalid rows to skip: 1"].exists)
        app.buttons["confirmSelectedImport"].tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Review import"].exists)
        app.buttons["confirmSelectedImport"].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Test coffee"].exists)
        XCTAssertTrue(app.staticTexts["Test employer"].exists)
        app.tabBars.buttons["Accounts"].tap()
        XCTAssertTrue(app.staticTexts["Test bank"].waitForExistence(timeout: 5))
    }
}
