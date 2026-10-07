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
                    ContentUnavailableView {
                        Label(.understandYourFinances, systemImage: AppSymbol.gettingStarted.rawValue)
                    } description: {
                        Text(.gettingStartedExplanation)
                    } actions: {
                        Button(.exploreDemo, action: loadDemo)
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoading)
                            .accessibilityIdentifier(AccessibilityID.loadDemo)
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: FinanceStyle.Spacing.section) {
                            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                                Label(overview.snapshot.transactions.allSatisfy { $0.source == .demo }
                                      ? .demoDataOnDevice : .localDataOnDevice, systemImage: AppSymbol.localStorage.rawValue)
                                    .font(FinanceStyle.Typography.label)
                                    .foregroundStyle(.secondary)
                                Text(overview.month, format: .dateTime.month(.wide).year())
                                    .font(FinanceStyle.Typography.heading)
                            }
                            ForEach(overview.summaries) { summary in
                                VStack(alignment: .leading, spacing: FinanceStyle.Spacing.standard) {
                                    Text(verbatim: summary.currency.code)
                                        .font(.headline)
                                        .accessibilityAddTraits(.isHeader)
                                    MoneyMetricCard(title: .netSpending, money: summary.netSpending)
                                    FinanceCard {
                                        VStack(spacing: FinanceStyle.Spacing.standard) {
                                            MoneyMetricRow(title: .income, money: summary.income)
                                            MoneyMetricRow(title: .expenses, money: summary.expenses)
                                            MoneyMetricRow(title: .refunds, money: summary.refunds)
                                            Divider()
                                            MoneyMetricRow(title: .netFlow, money: summary.netFlow)
                                        }
                                    }
                                }
                            }
                            if overview.summaries.isEmpty {
                                Text(.noTransactionsThisMonth)
                            }
                            Text(.dashboardTotalsExplanation)
                                .font(FinanceStyle.Typography.explanation)
                                .foregroundStyle(.secondary)
                        }
                        .padding(FinanceStyle.Spacing.standard)
                    }
                    .background(FinanceStyle.Surface.canvas)
                    .accessibilityIdentifier(AccessibilityID.dashboard)
                }
            } else if isLoading {
                ProgressView(.loadingLocalData)
            } else {
                ContentUnavailableView(.localDataUnavailable, systemImage: AppSymbol.unavailableStorage.rawValue)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isLoading && overview != nil { ProgressView().padding().accessibilityLabel(.loadingLocalData) }
        }
    }
}
