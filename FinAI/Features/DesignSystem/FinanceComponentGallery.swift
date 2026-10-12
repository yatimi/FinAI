//
//  FinanceComponentGallery.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceComponentGallery: View {
    var body: some View {
        ScrollView {
            VStack(spacing: FinanceStyle.Spacing.section) {
                FinanceCard {
                    VStack(alignment: .leading, spacing: FinanceStyle.Spacing.standard) {
                        Text(verbatim: FinanceStrings.understandYourFinances).font(FinanceStyle.Typography.heading)
                        MoneyText(money: .zero(.eur)).font(FinanceStyle.Typography.amount)
                        FinanceActionButton(title: .exploreDemo, action: {})
                        FinanceActionButton(title: .exploreDemo, emphasis: .secondary, action: {})
                        FinanceActionButton(title: .loadingLocalData, isLoading: true, action: {})
                        FinanceActionButton(title: .exploreDemo, action: {}).disabled(true)
                    }
                }
                FinanceEmptyState(
                    title: .understandYourFinances,
                    message: .gettingStartedExplanation,
                    systemImage: AppSymbol.gettingStarted.rawValue,
                    actionTitle: .exploreDemo,
                    action: {}
                )
                FinanceLoadingState(title: .loadingLocalData)
                FinanceErrorState(
                    title: .localDataUnavailable,
                    message: .unableToLoadLocalDataYourSavedDataHasNotBeenReplaced,
                    retryTitle: .tryAgain,
                    retry: {}
                )
            }
            .padding(FinanceStyle.Spacing.standard)
        }
        .background(FinanceStyle.Surface.canvas)
    }
}

#Preview("Components · Light") {
    FinanceComponentGallery().preferredColorScheme(.light)
}

#Preview("Components · Dark · Large text") {
    FinanceComponentGallery()
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
