//
//  PrivacyShieldView.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import SwiftUI

struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: AppSymbol.privacy.rawValue).font(.largeTitle).accessibilityHidden(true)
                Text(.finAI).font(.title)
                Text(.privacyPreviewHidden).multilineTextAlignment(.center)
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
    }
}
