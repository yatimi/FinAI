//
//  FinanceErrorState.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceErrorState: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let retryTitle: LocalizedStringResource
    let retry: () -> Void

    var body: some View {
        FinanceEmptyState(
            title: title,
            message: message,
            systemImage: "exclamationmark.triangle",
            actionTitle: retryTitle,
            action: retry
        )
    }
}
