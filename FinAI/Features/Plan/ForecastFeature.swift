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
    enum ScenarioFailure: Equatable { case invalidAmount, unavailable, remainingExpenses, remainingIncome, calculation }

    @ObservableState
    struct State: Equatable {
        var report: MonthForecast?
        var hasFailure = false
        var scenarioDraft = WhatIfDraft()
        var scenarioResult: WhatIfResult?
        var scenarioFailure: ScenarioFailure?
        var locale = Locale.current

        var scenarioCurrencies: [Currency] {
            report?.currencies.filter { $0.projection != nil }.map { $0.recorded.currency } ?? []
        }

        mutating func update(transactions: [Transaction]?, date: Date, calendar: Calendar) {
            let previousReport = report
            defer {
                if report != previousReport {
                    scenarioResult = nil
                    scenarioFailure = nil
                }
                if !scenarioCurrencies.contains(where: { $0.code == scenarioDraft.currencyCode }) {
                    scenarioDraft.currencyCode = scenarioCurrencies.first?.code ?? ""
                    scenarioDraft.amount = ""
                    scenarioResult = nil
                    scenarioFailure = nil
                }
            }
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

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case simulateTapped
        case resetScenarioTapped
        case closeTapped
    }
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.scenarioDraft) { _, _ in
                Reduce { state, _ in
                    state.scenarioResult = nil
                    state.scenarioFailure = nil
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .resetScenarioTapped:
                let currencyCode = state.scenarioDraft.currencyCode
                state.scenarioDraft = WhatIfDraft(currencyCode: currencyCode)
                state.scenarioResult = nil
                state.scenarioFailure = nil
                return .none
            case .simulateTapped:
                state.scenarioResult = nil
                state.scenarioFailure = nil
                guard let report = state.report,
                      state.scenarioCurrencies.contains(where: { $0.code == state.scenarioDraft.currencyCode }) else {
                    state.scenarioFailure = .unavailable
                    return .none
                }
                do {
                    let scenario = try state.scenarioDraft.scenario(locale: state.locale)
                    state.scenarioResult = try WhatIfPlanningService().simulate(scenario, forecast: report)
                } catch let error as WhatIfScenario.ScenarioError {
                    switch error {
                    case .invalidAmount: state.scenarioFailure = .invalidAmount
                    case .unavailableForecast: state.scenarioFailure = .unavailable
                    case .exceedsRemainingExpenses: state.scenarioFailure = .remainingExpenses
                    case .exceedsRemainingIncome: state.scenarioFailure = .remainingIncome
                    }
                } catch ValidationError.arithmeticFailure {
                    state.scenarioFailure = .calculation
                } catch {
                    state.scenarioFailure = .invalidAmount
                }
                return .none
            case .closeTapped: return .run { _ in await dismiss() }
            }
        }
    }
}
