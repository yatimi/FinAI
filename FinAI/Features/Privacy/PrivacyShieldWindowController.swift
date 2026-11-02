//
//  PrivacyShieldWindowController.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import SwiftUI
import UIKit

/// A separate, non-key window covers app-owned presentations before the system snapshot.
@MainActor
final class PrivacyShieldWindowController: NSObject {
    private(set) var window: UIWindow?
    private weak var scene: UIWindowScene?

    func attach(to scene: UIWindowScene?) {
        guard self.scene !== scene else { return }
        detach()
        guard let scene else { return }
        self.scene = scene
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.isUserInteractionEnabled = false
        let root = UIHostingController(rootView: PrivacyShieldView())
        root.view.backgroundColor = .systemBackground
        window.rootViewController = root
        window.backgroundColor = .systemBackground
        window.isOpaque = true
        self.window = window
        let center = NotificationCenter.default
        for name in [UIScene.willDeactivateNotification, UIScene.didEnterBackgroundNotification,
                     UIScene.willEnterForegroundNotification] {
            center.addObserver(self, selector: #selector(cover), name: name, object: scene)
        }
        center.addObserver(self, selector: #selector(uncover), name: UIScene.didActivateNotification, object: scene)
        center.addObserver(self, selector: #selector(disconnected), name: UIScene.didDisconnectNotification, object: scene)
        if scene.activationState == .foregroundActive { uncover() } else { cover() }
    }

    func detach() {
        NotificationCenter.default.removeObserver(self)
        window?.isHidden = true
        window = nil
        scene = nil
    }

    @objc private func cover() {
        guard let scene else { return }
        window?.frame = scene.coordinateSpace.bounds
        // No animation: the system may take its snapshot immediately after this notification.
        window?.isHidden = false
        window?.layoutIfNeeded()
    }

    @objc private func uncover() { window?.isHidden = true }
    @objc private func disconnected() { detach() }

    deinit { NotificationCenter.default.removeObserver(self) }
}
