//
//  PDFImportUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 06.10.26.
//

import XCTest

final class PDFImportUITests: XCTestCase {
    @MainActor
    func testStatementPreviewCancelCorrectTypeAndConfirm() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_STATEMENT"] = """
        Example Sparkasse
        Kontoauszug 1/2026
        GiroOnline 0000000000, DE00 0000 0000 0000 0000 00
        Seite 1 von 1
        Datum Erläuterung Betrag EUR
        Kontostand am 31.08.2026, Auszug Nr. 0 100,00
        01.09.2026dig. Karte Apple Pay
        REWE MARKT 123
        -12,50
        02.09.2026Gutschrift Überw.
        Test employer
        1.000,00
        Kontostand am 30.09.2026 um 20:00 Uhr 1.087,50
        Postanschrift: Example bank
        """
        app.launch()
        let account = app.textFields[AccessibilityID.importAccountName]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Column mapping"].exists)
        XCTAssertTrue(app.staticTexts["Statement currency: EUR"].exists)
        account.tap()
        account.typeText("Statement bank")
        app.keyboards.buttons["Done"].tap()
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<8 where !preview.isHittable { app.swipeUp() }
        XCTAssertTrue(preview.isHittable)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Selected transactions: 2"].exists)
        let unknown = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Unknown")).firstMatch
        for _ in 0..<12 where !unknown.isHittable { app.swipeUp() }
        XCTAssertTrue(unknown.isHittable)
        unknown.tap()
        app.buttons["Income"].tap()
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        XCTAssertTrue(app.alerts.staticTexts["Selected: 2. Skipped: 0. Your source file will not be changed."].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Review import"].exists)
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["REWE"].exists)
        XCTAssertTrue(app.staticTexts["Test employer"].exists)
        app.tabBars.buttons["Accounts"].tap()
        XCTAssertTrue(app.staticTexts["Statement bank"].waitForExistence(timeout: 5))
    }
}
