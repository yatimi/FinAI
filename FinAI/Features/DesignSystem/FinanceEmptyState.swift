//
//  FinanceEmptyState.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceEmptyState: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let systemImage: String
    var actionTitle: LocalizedStringResource? = nil
    var action: (() -> Void)? = nil
    var isLoading = false
    var actionAccessibilityIdentifier: String? = nil

    var body: some View {
        VStack(spacing: FinanceStyle.Spacing.section) {
            VStack(spacing: FinanceStyle.Spacing.standard) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(FinanceStyle.ColorRole.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(FinanceStyle.Typography.heading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(FinanceStyle.ColorRole.secondaryText)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            if let actionTitle, let action {
                if let actionAccessibilityIdentifier {
                    FinanceActionButton(title: actionTitle, isLoading: isLoading, action: action)
                        .accessibilityIdentifier(actionAccessibilityIdentifier)
                } else {
                    FinanceActionButton(title: actionTitle, isLoading: isLoading, action: action)
                }
            }
        }
        .foregroundStyle(FinanceStyle.ColorRole.text)
        .padding(FinanceStyle.Spacing.section)
        .frame(maxWidth: .infinity)
    }
}
