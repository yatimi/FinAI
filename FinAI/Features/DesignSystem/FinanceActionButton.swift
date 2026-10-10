//
//  FinanceActionButton.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceActionButton: View {
    let title: LocalizedStringResource
    var loadingTitle: LocalizedStringResource? = nil
    var isLoading = false
    var emphasis: FinanceButtonStyle.Emphasis = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FinanceStyle.Spacing.compact) {
                if isLoading {
                    ProgressView()
                        .tint(emphasis == .primary
                              ? FinanceStyle.ColorRole.onAccent : FinanceStyle.ColorRole.accent)
                        .accessibilityHidden(true)
                }
                Text(isLoading ? loadingTitle ?? title : title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(FinanceButtonStyle(emphasis: emphasis))
        .disabled(isLoading)
    }
}
