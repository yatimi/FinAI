//
//  PrivacyShield.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import SwiftUI
import UIKit

/// Attaches one privacy window to the same scene as this SwiftUI hierarchy, including its sheets.
struct PrivacyShield: UIViewRepresentable {
    func makeCoordinator() -> PrivacyShieldWindowController { PrivacyShieldWindowController() }

    func makeUIView(context: Context) -> SceneObserverView {
        let view = SceneObserverView()
        view.didChangeScene = { [weak controller = context.coordinator] scene in controller?.attach(to: scene) }
        return view
    }

    func updateUIView(_ uiView: SceneObserverView, context: Context) {
        context.coordinator.attach(to: uiView.window?.windowScene)
    }

    static func dismantleUIView(_ uiView: SceneObserverView, coordinator: PrivacyShieldWindowController) {
        uiView.didChangeScene = nil
        coordinator.detach()
    }

    final class SceneObserverView: UIView {
        var didChangeScene: ((UIWindowScene?) -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            didChangeScene?(window?.windowScene)
        }
    }
}
