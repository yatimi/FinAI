//
//  FinanceLoadingState.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceLoadingState: View {
    let title: LocalizedStringResource

    var body: some View {
        ProgressView {
            Text(title)
                .foregroundStyle(FinanceStyle.ColorRole.secondaryText)
        }
        .tint(FinanceStyle.ColorRole.accent)
        .padding(FinanceStyle.Spacing.section)
        .frame(maxWidth: .infinity)
    }
}
