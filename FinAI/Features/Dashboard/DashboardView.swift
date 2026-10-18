//
//  DashboardView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct DashboardView: View {
    let overview: FinanceOverview?
    let isLoading: Bool
    let loadDemo: () -> Void

    var body: some View {
        Group {
            if let overview {
                if overview.snapshot.accounts.isEmpty {
                    ScrollView {
                        FinanceEmptyState(
                            title: .understandYourFinances,
                            message: .gettingStartedExplanation,
                            systemImage: AppSymbol.gettingStarted.rawValue,
                            actionTitle: .exploreDemo,
                            action: loadDemo,
                            isLoading: isLoading,
                            actionAccessibilityIdentifier: AccessibilityID.loadDemo
                        )
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: FinanceStyle.Spacing.spacious) {
                            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                                Text(overview.month, format: .dateTime.month(.wide).year())
                                    .font(FinanceStyle.Typography.heading)
                                    .accessibilityAddTraits(.isHeader)
                                Label(overview.snapshot.transactions.allSatisfy { $0.source == .demo }
                                      ? .demoDataOnDevice : .localDataOnDevice, systemImage: AppSymbol.localStorage.rawValue)
                                    .font(FinanceStyle.Typography.label)
                                    .foregroundStyle(FinanceStyle.ColorRole.secondaryText)
                            }
                            ForEach(overview.summaries) { summary in
                                currencySummary(summary)
                            }
                            if overview.summaries.isEmpty {
                                FinanceEmptyState(
                                    title: .noTransactionsThisMonth,
                                    message: .dashboardTotalsExplanation,
                                    systemImage: "calendar"
                                )
                            }
                            Text(.dashboardTotalsExplanation)
                                .font(FinanceStyle.Typography.explanation)
                                .foregroundStyle(FinanceStyle.ColorRole.secondaryText)
                        }
                        .padding(FinanceStyle.Spacing.standard)
                    }
                    .background(FinanceStyle.Surface.canvas)
                    .accessibilityIdentifier(AccessibilityID.dashboard)
                }
            } else if isLoading {
                FinanceLoadingState(title: .loadingLocalData)
            } else {
                ContentUnavailableView(.localDataUnavailable, systemImage: AppSymbol.unavailableStorage.rawValue)
            }
        }
        .foregroundStyle(FinanceStyle.ColorRole.text)
        .tint(FinanceStyle.ColorRole.accent)
        .overlay(alignment: .topTrailing) {
            if isLoading && overview != nil { ProgressView().padding().accessibilityLabel(.loadingLocalData) }
        }
    }

    private func currencySummary(_ summary: CurrencySummary) -> some View {
        VStack(alignment: .leading, spacing: FinanceStyle.Spacing.section) {
            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                Text(verbatim: summary.currency.code)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                    Text(.netSpending)
                        .font(FinanceStyle.Typography.label)
                        .foregroundStyle(FinanceStyle.ColorRole.secondaryText)
                    MoneyText(money: summary.netSpending)
                        .font(FinanceStyle.Typography.amount)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }

            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.standard) {
                MoneyMetricRow(title: .income, money: summary.income)
                MoneyMetricRow(title: .expenses, money: summary.expenses)
                MoneyMetricRow(title: .refunds, money: summary.refunds)
                Divider()
                MoneyMetricRow(title: .netFlow, money: summary.netFlow)
                    .font(.headline)
            }
            Divider()
        }
    }
}
