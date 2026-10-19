//
//  AssistantFeature.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AssistantFeature {
    private enum CancelID { case question }

    @ObservableState
    struct State: Equatable {
        var snapshot: FinanceSnapshot
        var referenceDate: Date
        var calendar: Calendar
        var question = ""
        var availability = AssistantAvailability.notReady
        var requestID: UUID?
        var answer: AssistantAnswer?
        var previousQuery: AssistantQuery?
        var isAnswerPresented = false
        var failure: AssistantError?
        var drilldown: SpendingDrilldown?
        var isDrilldownPresented = false
        @Presents var detail: TransactionDetailFeature.State?

        var isLoading: Bool { requestID != nil }
        var merchants: [String] { Set(snapshot.transactions.map(\.merchant).filter { !$0.isEmpty }).sorted() }
        var drilldownTransactions: [Transaction] { drilldown?.transactions(in: snapshot, calendar: calendar) ?? [] }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task, askTapped, cancelTapped, clearTapped, closeTapped
        case suggested(AssistantQuery)
        case followUp(AssistantQuery.Period)
        case response(UUID, Result<AssistantAnswer, AssistantError>)
        case contextUpdated(FinanceSnapshot, Date, Calendar)
        case showTransactions(Date, Currency)
        case transactionTapped(UUID)
        case detail(PresentationAction<TransactionDetailFeature.Action>)
        case delegate(Delegate)
        enum Delegate: Equatable { case didUpdate(FinanceOverview) }
    }

    @Dependency(\.assistantClient) var client
    @Dependency(\.date.now) var now
    @Dependency(\.locale) var locale
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                state.availability = client.availability(locale)
                if !state.calendar.isDate(now, equalTo: state.referenceDate, toGranularity: .month) {
                    return .send(.contextUpdated(state.snapshot, now, state.calendar))
                }
                return .none
            case .askTapped:
                let question = state.question.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !question.isEmpty, question.count <= 1_000 else {
                    state.failure = .unsupportedQuestion
                    return .none
                }
                do {
                    let previous = state.calendar.isDate(now, equalTo: state.referenceDate, toGranularity: .month)
                        ? state.previousQuery : nil
                    let query = try AssistantFollowUp().resolve(question, previous: previous)
                    return start(&state, query: query, question: question)
                } catch {
                    state.failure = .unsupportedQuestion
                    return .none
                }
            case let .followUp(period):
                guard !state.isLoading, let previous = state.previousQuery,
                      state.calendar.isDate(now, equalTo: state.referenceDate, toGranularity: .month) else {
                    return .none
                }
                state.question = ""
                return start(&state, query: AssistantFollowUp().applying(period, to: previous), question: "",
                             preservingPresentation: true)
            case let .suggested(query):
                state.question = ""
                return start(&state, query: query, question: "")
            case let .response(id, result):
                guard state.requestID == id else { return .none }
                state.requestID = nil
                switch result {
                case let .success(answer):
                    state.answer = answer
                    state.previousQuery = answer.query
                    state.isAnswerPresented = true
                case let .failure(error):
                    state.failure = error
                    state.isAnswerPresented = false
                    if error == .modelUnavailable { state.availability = client.availability(locale) }
                }
                return .none
            case .cancelTapped:
                state.requestID = nil
                state.isAnswerPresented = false
                return .cancel(id: CancelID.question)
            case .clearTapped:
                state.question = ""
                state.requestID = nil
                state.answer = nil
                state.previousQuery = nil
                state.isAnswerPresented = false
                state.failure = nil
                state.drilldown = nil
                state.isDrilldownPresented = false
                return .cancel(id: CancelID.question)
            case let .contextUpdated(snapshot, date, calendar):
                guard snapshot != state.snapshot || state.calendar != calendar
                    || !calendar.isDate(date, equalTo: state.referenceDate, toGranularity: .month) else { return .none }
                state.snapshot = snapshot
                state.referenceDate = date
                state.calendar = calendar
                state.requestID = nil
                state.answer = nil
                state.previousQuery = nil
                state.isAnswerPresented = false
                state.failure = nil
                state.drilldown = nil
                state.isDrilldownPresented = false
                return .cancel(id: CancelID.question)
            case let .showTransactions(month, currency):
                guard let answer = state.answer,
                      month == answer.report.month || (answer.query.kind == .comparison && month == answer.report.previousMonth),
                      answer.report.currencies.contains(where: { $0.currency == currency }) else { return .none }
                state.drilldown = SpendingDrilldown(month: month, currency: currency,
                                                  group: answer.query.merchant.map { .merchant($0) })
                state.isDrilldownPresented = true
                return .none
            case let .transactionTapped(id):
                guard let transaction = state.drilldownTransactions.first(where: { $0.id == id }),
                      let account = state.snapshot.accounts.first(where: { $0.id == transaction.accountID }) else { return .none }
                state.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name,
                                                            accounts: state.snapshot.accounts, original: state.snapshot.originals[id])
                return .none
            case let .detail(.presented(.delegate(.didUpdate(overview)))):
                return .send(.delegate(.didUpdate(overview)))
            case .closeTapped:
                return .run { _ in await dismiss() }
            case .binding, .detail, .delegate:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) { TransactionDetailFeature() }
    }

    private func start(_ state: inout State, query: AssistantQuery?, question: String,
                       preservingPresentation: Bool = false) -> Effect<Action> {
        let id = uuid()
        state.requestID = id
        state.answer = nil
        state.isAnswerPresented = preservingPresentation && state.isAnswerPresented
        state.failure = nil
        state.drilldown = nil
        state.isDrilldownPresented = false
        let snapshot = state.snapshot
        let date = now
        if !state.calendar.isDate(date, equalTo: state.referenceDate, toGranularity: .month) {
            state.previousQuery = nil
        }
        state.referenceDate = date
        let calendar = state.calendar
        let locale = locale
        let client = client
        return .run { send in
            do {
                let resolved: AssistantQuery
                if let query { resolved = query }
                else { resolved = try await client.interpret(question, locale) }
                try Task.checkCancellation()
                let answer = try await client.answer(resolved, snapshot, date, calendar)
                try Task.checkCancellation()
                await send(.response(id, .success(answer)))
            } catch is CancellationError {
                // Cancel/clear/context changes own state cleanup; late results are also checked by request ID.
            } catch {
                guard !Task.isCancelled else { return }
                await send(.response(id, .failure(error as? AssistantError ?? .calculationFailed)))
            }
        }
        .cancellable(id: CancelID.question, cancelInFlight: true)
    }
}
