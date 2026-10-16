//
//  AnalyticsFeature.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AnalyticsFeature {
    @ObservableState
    struct State: Equatable {
        var hasBeenOpened = false
        var snapshot = FinanceSnapshot.empty
        var selectedMonth: Date?
        var report: SpendingAnalytics?
        var hasFailure = false
        var calendar = Calendar(identifier: .gregorian)
        var referenceDate = Date.distantPast
        var drilldown: SpendingDrilldown?
        var isDrilldownPresented = false

        var drilldownTransactions: [Transaction] {
            drilldown?.transactions(in: snapshot, calendar: calendar) ?? []
        }

        mutating func update(snapshot: FinanceSnapshot, date: Date, calendar: Calendar) {
            hasBeenOpened = true
            self.snapshot = snapshot
            self.referenceDate = date
            self.calendar = calendar
            recalculate()
        }

        mutating func recalculate() {
            do {
                report = try SpendingAnalyticsService().analyze(snapshot.transactions, date: selectedMonth ?? referenceDate, calendar: calendar)
                hasFailure = false
            } catch {
                report = nil
                hasFailure = true
            }
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case moveMonth(Int)
        case retryTapped
        case currentMonthTapped
        case spendingTapped(Currency, SpendingBreakdown.Group?)
        case transactionTapped(UUID)
    }

    @Dependency(\.date.now) var now

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case let .moveMonth(offset):
                guard let month = state.report?.month,
                      let next = state.calendar.date(byAdding: .month, value: offset, to: month) else { return .none }
                state.selectedMonth = next
                state.recalculate()
                return .none
            case .currentMonthTapped:
                state.referenceDate = now
                state.selectedMonth = nil
                state.recalculate()
                return .none
            case let .spendingTapped(currency, group):
                guard let report = state.report, report.currencies.contains(where: { $0.currency == currency }) else { return .none }
                state.drilldown = SpendingDrilldown(month: report.month, currency: currency, group: group)
                state.isDrilldownPresented = true
                return .none
            case .retryTapped, .binding, .transactionTapped:
                return .none
            }
        }
    }
}
