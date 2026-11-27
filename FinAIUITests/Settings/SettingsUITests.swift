//
//  SettingsUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 26.11.26.
//

import XCTest

final class SettingsUITests: XCTestCase {
    @MainActor
    func testUkrainianDemoAndSuggestedQuestionWithoutModel() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(uk)", "-AppleLocale", "uk_UA"]
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Завантажити демодані"].tap()
        let assistant = app.buttons[AccessibilityID.openAssistant]
        XCTAssertTrue(assistant.waitForExistence(timeout: 10))
        assistant.tap()
        XCTAssertTrue(app.navigationBars["Асистент"].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.assistantThisMonth].tap()
        XCTAssertTrue(app.staticTexts[AccessibilityID.assistantAnswerMonth].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.assistantFollowUpPeriod].tap()
        XCTAssertTrue(app.buttons["А за цей місяць?"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLanguageShortcutOpensSystemSettingsAndReturns() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        openSettings(in: app)
        app.buttons[AccessibilityID.settingsLanguage].tap()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
        app.activate()
        XCTAssertTrue(app.buttons[AccessibilityID.closeSettings].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppearancePersistsAcrossLaunchesAndReturnsToSystem() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_PREFERENCES"] = UUID().uuidString
        app.launch()
        openSettings(in: app)
        for choice in ["Dark", "Light", "System"] {
            let picker = app.buttons[AccessibilityID.settingsAppearance]
            picker.tap()
            app.buttons[choice].tap()
            XCTAssertTrue(picker.label.contains(choice) || (picker.value as? String) == choice)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Settings appearance: \(choice)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.buttons[AccessibilityID.closeSettings].tap()
            app.terminate()
            app.launch()
            openSettings(in: app)
            XCTAssertTrue(picker.label.contains(choice) || (picker.value as? String) == choice)
        }
        app.buttons[AccessibilityID.settingsPrivacy].tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Stored on your device"].exists)
    }

    @MainActor
    func testUkrainianSettingsAndPrivacyWithLargestText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(uk)", "-AppleLocale", "uk_UA",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        openSettings(in: app)
        let navigation = app.navigationBars["Налаштування"]
        XCTAssertTrue(navigation.waitForExistence(timeout: 5))
        let language = app.buttons[AccessibilityID.settingsLanguage]
        UITestVisibility.reveal(language, in: app, below: navigation)
        XCTAssertEqual(language.label, "Змінити мову")
        let privacy = app.buttons[AccessibilityID.settingsPrivacy]
        UITestVisibility.reveal(privacy, in: app, below: navigation)
        privacy.tap()
        let privacyNavigation = app.navigationBars["Приватність"]
        XCTAssertTrue(privacyNavigation.waitForExistence(timeout: 5))
        // Read each section in order: at the largest text size, the complete page spans many screens.
        for heading in ["Збереження на пристрої", "Асистент на пристрої", "Резервні копії пристрою",
                        "Коли програма неактивна", "Імпортовані файли"] {
            revealPrivacyHeading(app.staticTexts[heading], in: app, below: privacyNavigation)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Ukrainian privacy at largest text size"
        attachment.lifetime = .keepAlways
        add(attachment)
        privacyNavigation.buttons.firstMatch.tap()
        app.buttons[AccessibilityID.closeSettings].tap()
        XCTAssertTrue(app.tabBars.buttons["План"].waitForExistence(timeout: 5))
        app.tabBars.buttons["План"].tap()
        XCTAssertTrue(app.buttons["Додати до плану"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func revealPrivacyHeading(_ heading: XCUIElement, in app: XCUIApplication, below navigation: XCUIElement) {
        // Section headers may sit flush with the navigation bar; the control helper requires an extra inset.
        for _ in 0..<18 {
            if heading.exists, heading.isHittable,
               heading.frame.minY >= navigation.frame.maxY - 1,
               heading.frame.maxY <= app.frame.maxY - 40 { return }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTFail("Privacy section is not fully visible: \(heading.label)")
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let settings = app.buttons[AccessibilityID.openSettings]
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        settings.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.closeSettings].waitForExistence(timeout: 5))
    }
}
