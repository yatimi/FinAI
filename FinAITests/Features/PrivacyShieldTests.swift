//
//  PrivacyShieldTests.swift
//  FinAITests
//
//  Created by Tommy on 31.10.26.
//

import Foundation
import Testing
import UIKit
@testable import FinAI

@MainActor
@Suite(.serialized)
struct PrivacyShieldTests {
    @Test func coversPresentedWindowsWithoutTakingKeyStatusUntilSceneBecomesActive() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let keyWindow = scene.windows.first { $0.isKeyWindow }
        let controller = PrivacyShieldWindowController()
        controller.attach(to: scene)
        defer { controller.detach() }
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: scene)
        let window = try #require(controller.window)
        #expect(window.isHidden)
        #expect(window.isKeyWindow == false)
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: scene)
        #expect(window.isHidden == false)
        #expect(window.windowLevel > .alert)
        #expect(window.frame == scene.coordinateSpace.bounds)
        #expect(window.isOpaque)
        #expect(window.isUserInteractionEnabled == false)
        #expect(window.isKeyWindow == false)
        #expect(scene.windows.first { $0.isKeyWindow } === keyWindow)
        NotificationCenter.default.post(name: UIScene.didEnterBackgroundNotification, object: scene)
        NotificationCenter.default.post(name: UIScene.willEnterForegroundNotification, object: scene)
        #expect(window.isHidden == false)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: scene)
        #expect(window.isHidden)
    }

    @Test func unrelatedNotificationsAndDetachedScenesCannotRevealOrRetainAWindow() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let controller = PrivacyShieldWindowController()
        controller.attach(to: scene)
        defer { controller.detach() }
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: scene)
        let window = try #require(controller.window)
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: NSObject())
        #expect(window.isHidden)
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: scene)
        #expect(window.isHidden == false)
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: scene)
        #expect(controller.window == nil)
        #expect(window.isHidden)
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: scene)
        #expect(controller.window == nil)
    }
}
