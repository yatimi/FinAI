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
                    List {
                        Section {
                            Label(overview.snapshot.transactions.allSatisfy { $0.source == .demo }
                                  ? .demoDataOnDevice : .localDataOnDevice, systemImage: AppSymbol.localStorage.rawValue)
                                .font(.subheadline)
                            Text(overview.month, format: .dateTime.month(.wide).year())
                                .font(.title2.bold())
                        }
                        ForEach(overview.summaries) { summary in
                            Section(summary.currency.code) {
                                MoneyMetricRow(title: .income, money: summary.income)
                                MoneyMetricRow(title: .expenses, money: summary.expenses)
                                MoneyMetricRow(title: .refunds, money: summary.refunds)
                                MoneyMetricRow(title: .netSpending, money: summary.netSpending)
                                MoneyMetricRow(title: .netFlow, money: summary.netFlow)
                            }
                        }
                        if overview.summaries.isEmpty {
                            Text(.noTransactionsThisMonth)
                        }
                        Section {
                            Text(.dashboardTotalsExplanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
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
