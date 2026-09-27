//
//  ImportFeature.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ImportFeature {
    enum Phase: Equatable { case idle, reading, previewing, saving }
    private enum CancelID { case work }

    @ObservableState
    struct State: Equatable {
        let snapshot: FinanceSnapshot
        let newAccountID: UUID
        var isFilePickerPresented = false
        var document: CSVDocument?
        var mapping = CSVMapping()
        var selectedAccountID: UUID?
        var newAccountName = ""
        var newAccountKind = Account.Kind.bank
        var phase = Phase.idle
        var preview: ImportPreview?
        var previewAccount: Account?
        var sessionID: UUID?
        var excludedIDs: Set<UUID> = []
        var error: ImportError?
        @Presents var alert: AlertState<Action.Alert>?

        var replacingDemo: Bool { snapshot.transactions.contains { $0.source == .demo } }
        var eligibleAccounts: [Account] {
            let demoIDs = Set(snapshot.transactions.filter { $0.source == .demo }.map(\.accountID))
            return snapshot.accounts.filter { !demoIDs.contains($0.id) }
        }
        var selectedCandidates: [ImportCandidate] {
            preview?.candidates.filter { !excludedIDs.contains($0.id) } ?? []
        }
        func account() throws -> Account {
            if let selectedAccountID {
                guard let account = eligibleAccounts.first(where: { $0.id == selectedAccountID }) else { throw ImportError.invalidAccount }
                return account
            }
            let name = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 100 else { throw ImportError.invalidAccount }
            guard let currency = try? Currency(code: mapping.currencyCode) else { throw ImportError.invalidCurrency }
            return Account(id: newAccountID, name: name, kind: newAccountKind, currency: currency)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case fileChosen(URL)
        case fileSelectionFailed
        case fileRead(Result<CSVDocument, ImportError>)
        case previewTapped
        case previewResponse(Result<ImportPreview, ImportError>)
        case editMappingTapped
        case toggleRow(UUID)
        case kindChanged(UUID, Transaction.Kind)
        case categoryChanged(UUID, Category)
        case merchantChanged(UUID, String)
        case importTapped
        case alert(PresentationAction<Alert>)
        case saveResponse(Result<VoidSuccess, ImportError>)
        case closeTapped
        case delegate(Delegate)
        enum Alert: Equatable { case confirmImport }
        enum Delegate: Equatable { case didImport }
    }
    struct VoidSuccess: Equatable, Sendable {}

    @Dependency(\.importClient) var client
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.selectedAccountID):
                if let account = state.eligibleAccounts.first(where: { $0.id == state.selectedAccountID }) {
                    state.mapping.currencyCode = account.currency.code
                }
                state.error = nil
                return .none
            case .binding:
                state.error = nil
                return .none
            case let .fileChosen(url):
                guard state.phase == .idle else { return .none }
                state.document = nil
                state.preview = nil
                state.error = nil
                state.phase = .reading
                let client = client
                return .run { send in
                    do {
                        let document = try await client.readFile(url)
                        try Task.checkCancellation()
                        await send(.fileRead(.success(document)))
                    } catch is CancellationError {} catch {
                        await send(.fileRead(.failure(error as? ImportError ?? .unreadableFile)))
                    }
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .fileSelectionFailed:
                state.error = .unreadableFile
                return .none
            case let .fileRead(.success(document)):
                guard state.phase == .reading else { return .none }
                state.phase = .idle
                state.document = document
                var mapping = CSVMapping.suggested(for: document)
                mapping.currencyCode = state.mapping.currencyCode
                state.mapping = mapping
                return .none
            case let .fileRead(.failure(error)), let .previewResponse(.failure(error)):
                state.phase = .idle
                state.error = error
                return .none
            case .previewTapped:
                guard state.phase == .idle, let document = state.document else { return .none }
                do {
                    let account = try state.account()
                    try state.mapping.validate(columnCount: document.headers.count)
                    state.phase = .previewing
                    state.error = nil
                    state.previewAccount = account
                    state.sessionID = uuid()
                    let mapping = state.mapping
                    let existing = state.snapshot.transactions
                    let timeZone = calendar.timeZone
                    let client = client
                    return .run { send in
                        do {
                            let preview = try await client.preview(document, mapping, account, existing, timeZone)
                            try Task.checkCancellation()
                            await send(.previewResponse(.success(preview)))
                        } catch is CancellationError {} catch {
                            await send(.previewResponse(.failure(error as? ImportError ?? .invalidMapping)))
                        }
                    }.cancellable(id: CancelID.work, cancelInFlight: true)
                } catch {
                    state.error = error as? ImportError ?? .invalidMapping
                    return .none
                }
            case let .previewResponse(.success(preview)):
                guard state.phase == .previewing else { return .none }
                state.phase = .idle
                state.preview = preview
                state.excludedIDs = Set(preview.candidates.filter(\.isPossibleDuplicate).map(\.id))
                return .none
            case .editMappingTapped:
                guard state.phase == .idle else { return .none }
                state.preview = nil
                state.previewAccount = nil
                state.error = nil
                return .none
            case let .toggleRow(id):
                guard state.phase == .idle else { return .none }
                if !state.excludedIDs.insert(id).inserted { state.excludedIDs.remove(id) }
                return .none
            case let .kindChanged(id, kind):
                guard state.phase == .idle,
                      let index = state.preview?.candidates.firstIndex(where: { $0.id == id }),
                      state.preview?.candidates[index].kind != kind,
                      state.preview?.candidates[index].allowedKinds.contains(kind) == true else { return .none }
                state.preview?.candidates[index].kind = kind
                if let candidate = state.preview?.candidates[index] {
                    state.preview?.candidates[index].category = TransactionClassificationService()
                        .suggest(description: candidate.merchant, kind: kind).category
                }
                return .none
            case let .merchantChanged(id, merchant):
                guard state.phase == .idle, let index = state.preview?.candidates.firstIndex(where: { $0.id == id }) else { return .none }
                state.preview?.candidates[index].merchant = merchant
                state.error = nil
                return .none
            case let .categoryChanged(id, category):
                guard state.phase == .idle, let index = state.preview?.candidates.firstIndex(where: { $0.id == id }) else { return .none }
                state.preview?.candidates[index].category = category
                return .none
            case .importTapped:
                guard state.phase == .idle, !state.selectedCandidates.isEmpty else { return .none }
                let count = state.selectedCandidates.count
                let skipped = (state.document?.rows.count ?? 0) - count
                let replacingDemo = state.replacingDemo
                state.alert = AlertState {
                    TextState("Import selected transactions?")
                } actions: {
                    ButtonState(action: .confirmImport) { TextState("Confirm import") }
                    ButtonState(role: .cancel) { TextState("Cancel") }
                } message: {
                    if replacingDemo {
                        TextState("Demo data will be replaced. Selected: \(count). Skipped: \(skipped). Your CSV file will not be changed.")
                    } else {
                        TextState("Selected: \(count). Skipped: \(skipped). Your CSV file will not be changed.")
                    }
                }
                return .none
            case .alert(.presented(.confirmImport)):
                guard state.phase == .idle, let account = state.previewAccount,
                      let sessionID = state.sessionID, let document = state.document else { return .none }
                do {
                    let candidates = state.selectedCandidates
                    let batch = try ImportBatch(
                        id: sessionID, sourceName: document.name, importedAt: now, account: account,
                        transactions: candidates.map { try $0.transaction(accountID: account.id) },
                        rowNumbers: candidates.map(\.rowNumber), replacingDemo: state.replacingDemo
                    )
                    try batch.validate()
                    state.phase = .saving
                    state.error = nil
                    let client = client
                    return .run { send in
                        do {
                            try await client.save(batch)
                            await send(.saveResponse(.success(VoidSuccess())))
                        } catch is CancellationError {} catch {
                            await send(.saveResponse(.failure(error as? ImportError ?? .storageChanged)))
                        }
                    }.cancellable(id: CancelID.work, cancelInFlight: true)
                } catch {
                    state.error = error as? ImportError ?? .emptySelection
                    return .none
                }
            case .saveResponse(.success):
                state.phase = .idle
                return .send(.delegate(.didImport))
            case let .saveResponse(.failure(error)):
                state.phase = .idle
                state.error = error
                return .none
            case .closeTapped:
                guard state.phase != .saving else { return .none }
                return .merge(.cancel(id: CancelID.work), .run { _ in await dismiss() })
            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
