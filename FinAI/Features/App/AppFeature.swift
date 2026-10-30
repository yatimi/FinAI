//
//  AppFeature.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    enum Tab: Equatable { case dashboard, transactions, plan }
    private enum CancelID { case loading }

    @ObservableState
    struct State: Equatable {
        var analytics = AnalyticsFeature.State()
        var plan = PlanFeature.State()
        var selectedTab = Tab.dashboard
        var isRecurringPaymentsPresented = false
        var transactions = TransactionsFeature.State()
        var overview: FinanceOverview?
        var isLoading = false
        var failure: LoadError?
        @Presents var assistant: AssistantFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var importFlow: ImportFeature.State?
        @Presents var merchantRules: MerchantRulesFeature.State?
        @Presents var detail: TransactionDetailFeature.State?
        @Presents var budgets: BudgetsFeature.State?
        @Presents var goals: GoalsFeature.State?
        @Presents var debts: DebtsFeature.State?
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case assistantTapped
        case assistant(PresentationAction<AssistantFeature.Action>)
        case analyticsOpened
        case analytics(AnalyticsFeature.Action)
        case plan(PlanFeature.Action)
        case task
        case refresh
        case cancelLoading
        case demoTapped
        case response(Result<FinanceOverview, LoadError>)
        case merchantRulesTapped
        case addBudgetTapped
        case budgetTapped(UUID)
        case addGoalTapped
        case goalTapped(UUID)
        case budgetsTapped
        case budgets(PresentationAction<BudgetsFeature.Action>)
        case addDebtTapped
        case debtsTapped
        case debts(PresentationAction<DebtsFeature.Action>)
        case goalsTapped
        case goals(PresentationAction<GoalsFeature.Action>)
        case merchantRules(PresentationAction<MerchantRulesFeature.Action>)
        case importTapped
        case importFlow(PresentationAction<ImportFeature.Action>)
        case transactions(TransactionsFeature.Action)
        case alert(PresentationAction<Alert>)
        case detail(PresentationAction<TransactionDetailFeature.Action>)
        enum Alert: Equatable { case confirmDemo }
    }
    enum LoadError: Error, Equatable { case loading, saving }

    @Dependency(\.financeClient) var financeClient
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.analytics, action: \.analytics) { AnalyticsFeature() }
        Scope(state: \.plan, action: \.plan) { PlanFeature() }
        Scope(state: \.transactions, action: \.transactions) { TransactionsFeature() }
        core
        .ifLet(\.$assistant, action: \.assistant) { AssistantFeature() }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$merchantRules, action: \.merchantRules) { MerchantRulesFeature() }
        .ifLet(\.$budgets, action: \.budgets) { BudgetsFeature() }
        .ifLet(\.$goals, action: \.goals) { GoalsFeature() }
        .ifLet(\.$debts, action: \.debts) { DebtsFeature() }
        .ifLet(\.$detail, action: \.detail) { TransactionDetailFeature() }
        .ifLet(\.$importFlow, action: \.importFlow) { ImportFeature() }
    }

    private var core: Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .assistantTapped:
                guard !state.isLoading, let overview = state.overview else { return .none }
                state.assistant = AssistantFeature.State(snapshot: overview.snapshot, referenceDate: now, calendar: calendar)
                return .none
            case .analyticsOpened:
                state.analytics.hasBeenOpened = true
                if let overview = state.overview {
                    state.analytics.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                } else {
                    state.analytics.hasFailure = state.failure != nil
                }
                return .none
            case .analytics(.retryTapped):
                return .send(.refresh)
            case .task:
                guard state.overview == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.failure = nil
                return loadDemo(false)
            case .refresh:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.failure = nil
                return loadDemo(false)
            case .cancelLoading:
                state.isLoading = false
                return .cancel(id: CancelID.loading)
            case .demoTapped:
                guard !state.isLoading, let overview = state.overview,
                      overview.snapshot.accounts.isEmpty, overview.snapshot.transactions.isEmpty else { return .none }
                state.alert = AlertState {
                    TextState(.exploreWithDemoData)
                } actions: {
                    ButtonState(action: .confirmDemo) { TextState(.loadDemoData) }
                    ButtonState(role: .cancel) { TextState(.cancel) }
                } message: {
                    TextState(.demoConfirmationMessage)
                }
                return .none
            case .alert(.presented(.confirmDemo)):
                guard !state.isLoading, let overview = state.overview,
                      overview.snapshot.accounts.isEmpty, overview.snapshot.transactions.isEmpty else { return .none }
                state.isLoading = true
                state.failure = nil
                return loadDemo(true)
            case let .response(.success(overview)):
                guard state.isLoading else { return .none }
                state.isLoading = false
                state.overview = overview
                if state.analytics.hasBeenOpened {
                    state.analytics.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                }
                state.transactions.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                state.failure = nil
                return .merge(
                    state.budgets != nil ? .send(.budgets(.presented(.transactionsUpdated(overview.snapshot.transactions)))) : .none,
                    state.assistant != nil ? .send(.assistant(.presented(.contextUpdated(overview.snapshot, now, calendar)))) : .none
                )
            case let .response(.failure(error)):
                guard state.isLoading else { return .none }
                state.isLoading = false
                state.failure = error
                if state.analytics.hasBeenOpened && state.analytics.report == nil {
                    state.analytics.hasFailure = true
                }
                return .none
            case .merchantRulesTapped:
                state.merchantRules = MerchantRulesFeature.State()
                return .none
            case .addBudgetTapped:
                state.budgets = BudgetsFeature.State(editorRequest: .add, transactions: state.overview?.snapshot.transactions ?? [])
                return .none
            case let .budgetTapped(id):
                state.budgets = BudgetsFeature.State(editorRequest: .edit(id), transactions: state.overview?.snapshot.transactions ?? [])
                return .none
            case .addGoalTapped:
                state.goals = GoalsFeature.State(editorRequest: .add)
                return .none
            case let .goalTapped(id):
                state.goals = GoalsFeature.State(editorRequest: .edit(id))
                return .none
            case .budgetsTapped:
                state.budgets = BudgetsFeature.State(transactions: state.overview?.snapshot.transactions ?? [])
                return .none
            case .addDebtTapped:
                state.debts = DebtsFeature.State(addAfterLoading: true)
                return .none
            case .debtsTapped:
                state.debts = DebtsFeature.State()
                return .none
            case .goalsTapped:
                state.goals = GoalsFeature.State()
                return .none
            case .importTapped:
                guard !state.isLoading, let overview = state.overview else { return .none }
                state.importFlow = ImportFeature.State(snapshot: overview.snapshot, newAccountID: uuid())
                return .none
            case .importFlow(.presented(.delegate(.didImport))):
                state.importFlow = nil
                state.transactions.query = TransactionQuery()
                state.selectedTab = .transactions
                state.isLoading = true
                state.failure = nil
                return loadDemo(false)
            case let .transactions(.transactionTapped(id)), let .transactions(.editTapped(id)), let .analytics(.transactionTapped(id)):
                guard let snapshot = state.overview?.snapshot,
                      let transaction = snapshot.transactions.first(where: { $0.id == id }),
                      let account = snapshot.accounts.first(where: { $0.id == transaction.accountID }) else { return .none }
                state.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name, accounts: snapshot.accounts, original: snapshot.originals[transaction.id])
                if case .transactions(.editTapped) = action { return .send(.detail(.presented(.editTapped))) }
                return .none
            case let .detail(.presented(.delegate(.didUpdate(overview)))),
                 let .assistant(.presented(.delegate(.didUpdate(overview)))):
                state.overview = overview
                if state.analytics.hasBeenOpened {
                    state.analytics.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                }
                state.transactions.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                state.isLoading = false
                state.failure = nil
                return .merge(
                    .cancel(id: CancelID.loading),
                    state.assistant != nil ? .send(.assistant(.presented(.contextUpdated(overview.snapshot, now, calendar)))) : .none
                )
            case .goals(.dismiss), .budgets(.dismiss):
                return .send(.plan(.task))
            case .assistant, .analytics, .plan, .binding, .alert, .detail, .importFlow, .transactions, .merchantRules, .goals, .budgets, .debts:
                return .none
            }
        }
    }

    private func loadDemo(_ shouldAddDemo: Bool) -> Effect<Action> {
        let date = now
        let calendar = calendar
        let client = financeClient
        return .run { send in
            do {
                let result = try await shouldAddDemo ? client.addDemo(date, calendar) : client.load(date, calendar)
                try Task.checkCancellation()
                await send(.response(.success(result)))
            } catch is CancellationError {
                // Lifecycle cancellation is handled by cancelLoading, without showing an error.
            } catch {
                await send(.response(.failure(shouldAddDemo ? .saving : .loading)))
            }
        }
        .cancellable(id: CancelID.loading, cancelInFlight: true)
    }
}
