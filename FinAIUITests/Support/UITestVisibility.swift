//
//  UITestVisibility.swift
//  FinAIUITests
//
//  Created by Tommy on 31.10.26.
//

import XCTest

/// Hit-testable controls can still lie under a navigation bar at accessibility text sizes.
enum UITestVisibility {
    @MainActor
    static func reveal(_ element: XCUIElement, in app: XCUIApplication, below navigationBar: XCUIElement,
                       scrollingUp: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        let top = navigationBar.frame.maxY + 8
        let bottom = app.frame.maxY - 40
        for _ in 0..<18 {
            if element.exists {
                let frame = element.frame
                if element.isHittable, frame.minY >= top, frame.maxY <= bottom { return }
                if frame.minY < top { app.swipeDown() } else { app.swipeUp() }
            } else if scrollingUp { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.exists, file: file, line: line)
        XCTAssertTrue(element.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.minY, top, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxY, bottom, file: file, line: line)
    }
}
