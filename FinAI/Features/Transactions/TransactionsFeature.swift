//
//  TransactionsFeature.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TransactionsFeature {
    @ObservableState
    struct State: Equatable {
        var snapshot = FinanceSnapshot.empty
        var query = TransactionQuery()
        var isFilterPresented = false
        var referenceDate = Date.distantPast
        var calendar = Calendar(identifier: .gregorian)

        var results: [Transaction] {
            TransactionSearchService().search(snapshot.transactions, query: query, now: referenceDate, calendar: calendar)
        }

        var currencies: [Currency] {
            Set(snapshot.transactions.map(\.money.currency)).sorted { $0.code < $1.code }
        }

        var hasInvalidDateRange: Bool {
            query.period == .custom && calendar.startOfDay(for: query.startDate) > calendar.startOfDay(for: query.endDate)
        }

        mutating func update(snapshot: FinanceSnapshot, date: Date, calendar: Calendar) {
            self.snapshot = snapshot
            referenceDate = date
            self.calendar = calendar
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case filtersTapped
        case resetTapped
        case transactionTapped(UUID)
    }

    @Dependency(\.date.now) var now

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .filtersTapped:
                if state.query.startDate == .distantPast {
                    state.query.startDate = now
                    state.query.endDate = now
                }
                state.isFilterPresented = true
                return .none
            case .resetTapped:
                state.query = TransactionQuery(startDate: now, endDate: now)
                return .none
            case .binding, .transactionTapped:
                return .none
            }
        }
    }
}
