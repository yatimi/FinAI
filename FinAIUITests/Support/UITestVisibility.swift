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
        for _ in 0..<18 {
            let top = navigationBar.frame.maxY + 8
            let bottom = app.frame.maxY - 40
            let midpoint = (top + bottom) / 2
            let maximumDistance = (bottom - top) / 3
            var distance = scrollingUp ? -maximumDistance : maximumDistance
            if element.exists {
                let frame = element.frame
                if element.isHittable, frame.minY >= top, frame.maxY <= bottom { return }
                if !frame.isEmpty {
                    distance = min(max(midpoint - frame.midY, -maximumDistance), maximumDistance)
                }
            }
            // Full swipes can repeatedly overshoot a control near the navigation bar.
            // A bounded drag moves it toward the visible center without a fling.
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: app.frame.width / 2, dy: midpoint - app.frame.minY))
            let end = start.withOffset(CGVector(dx: 0, dy: distance))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.exists, file: file, line: line)
        XCTAssertTrue(element.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.minY, navigationBar.frame.maxY + 8, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxY, app.frame.maxY - 40, file: file, line: line)
    }
}
