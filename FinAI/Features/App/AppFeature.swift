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
    enum Tab: Equatable { case dashboard, transactions, analytics, accounts }
    private enum CancelID { case loading }

    @ObservableState
    struct State: Equatable {
        var selectedTab = Tab.dashboard
        var isRecurringPaymentsPresented = false
        var transactions = TransactionsFeature.State()
        var overview: FinanceOverview?
        var isLoading = false
        var failure: LoadError?
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var importFlow: ImportFeature.State?
        @Presents var merchantRules: MerchantRulesFeature.State?
        @Presents var detail: TransactionDetailFeature.State?
        @Presents var budgets: BudgetsFeature.State?
        @Presents var goals: GoalsFeature.State?
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case refresh
        case cancelLoading
        case demoTapped
        case response(Result<FinanceOverview, LoadError>)
        case merchantRulesTapped
        case budgetsTapped
        case budgets(PresentationAction<BudgetsFeature.Action>)
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
        Scope(state: \.transactions, action: \.transactions) { TransactionsFeature() }
        Reduce { state, action in
            switch action {
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
                state.transactions.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                state.failure = nil
                if state.budgets != nil {
                    return .send(.budgets(.presented(.transactionsUpdated(overview.snapshot.transactions))))
                }
                return .none
            case let .response(.failure(error)):
                guard state.isLoading else { return .none }
                state.isLoading = false
                state.failure = error
                return .none
            case .merchantRulesTapped:
                state.merchantRules = MerchantRulesFeature.State()
                return .none
            case .budgetsTapped:
                state.budgets = BudgetsFeature.State(transactions: state.overview?.snapshot.transactions ?? [])
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
            case let .transactions(.transactionTapped(id)), let .transactions(.editTapped(id)):
                guard let snapshot = state.overview?.snapshot,
                      let transaction = snapshot.transactions.first(where: { $0.id == id }),
                      let account = snapshot.accounts.first(where: { $0.id == transaction.accountID }) else { return .none }
                state.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name, accounts: snapshot.accounts, original: snapshot.originals[transaction.id])
                if case .transactions(.editTapped) = action { return .send(.detail(.presented(.editTapped))) }
                return .none
            case let .detail(.presented(.delegate(.didUpdate(overview)))):
                state.overview = overview
                state.transactions.update(snapshot: overview.snapshot, date: now, calendar: calendar)
                state.isLoading = false
                state.failure = nil
                return .cancel(id: CancelID.loading)
            case .binding, .alert, .detail, .importFlow, .transactions, .merchantRules, .goals, .budgets:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$merchantRules, action: \.merchantRules) { MerchantRulesFeature() }
        .ifLet(\.$budgets, action: \.budgets) { BudgetsFeature() }
        .ifLet(\.$goals, action: \.goals) { GoalsFeature() }
        .ifLet(\.$detail, action: \.detail) { TransactionDetailFeature() }
        .ifLet(\.$importFlow, action: \.importFlow) { ImportFeature() }
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
