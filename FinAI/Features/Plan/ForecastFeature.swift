//
//  ForecastFeature.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ForecastFeature {
    @ObservableState
    struct State: Equatable {
        var report: MonthForecast?
        var hasFailure = false

        mutating func update(transactions: [Transaction]?, date: Date, calendar: Calendar) {
            guard let transactions else { report = nil; hasFailure = false; return }
            do {
                report = try MonthForecastService().forecast(transactions, on: date, calendar: calendar)
                hasFailure = false
            } catch {
                report = nil
                hasFailure = true
            }
        }
    }

    enum Action: Equatable { case closeTapped }
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .closeTapped: return .run { _ in await dismiss() }
            }
        }
    }
}
