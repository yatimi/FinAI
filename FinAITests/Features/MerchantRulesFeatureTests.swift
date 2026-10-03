//
//  MerchantRulesFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 02.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct MerchantRulesFeatureTests {
    @Test func creatingRuleRequiresExplicitSaveAndFailureKeepsDraftForRetry() async {
        let id = UUID()
        var state = MerchantRulesFeature.State()
        state.isEditorPresented = true
        state.pattern = "REWE"
        state.merchant = "My shop"
        state.category = .family
        let store = TestStore(initialState: state) { MerchantRulesFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.merchantRulesClient.save = { rule, replacing in
                #expect(rule.id == id)
                #expect(rule.category == .family)
                #expect(replacing == false)
                throw MerchantRule.RuleError.conflict
            }
        }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.conflict))) {
            $0.phase = .idle
            $0.failure = .conflict
        }
        #expect(store.state.pattern == "REWE")
        #expect(store.state.isEditorPresented)
    }

    @Test func successfulEditUpdatesListAndClosesEditor() async {
        let rule = MerchantRule(id: UUID(), pattern: "Shop", matchMode: .exact, kind: .expense, merchant: "Shop", category: .family)
        var state = MerchantRulesFeature.State()
        state.rules = [rule]
        let store = TestStore(initialState: state) { MerchantRulesFeature() } withDependencies: {
            $0.merchantRulesClient.save = { saved, replacing in
                #expect(replacing)
                return [saved]
            }
        }
        await store.send(.editTapped(rule.id)) {
            $0.editingID = rule.id
            $0.pattern = rule.pattern
            $0.merchant = rule.merchant
            $0.category = .family
            $0.isEditorPresented = true
        }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.success([rule]))) {
            $0.phase = .idle
            $0.isEditorPresented = false
            $0.editingID = nil
        }
    }

    @Test func deletionWaitsForConfirmationAndCanBeCancelled() async {
        let rule = MerchantRule(id: UUID(), pattern: "Shop", matchMode: .exact, kind: .expense, merchant: "Shop", category: .family)
        var state = MerchantRulesFeature.State()
        state.rules = [rule]
        let store = TestStore(initialState: state) { MerchantRulesFeature() } withDependencies: {
            $0.merchantRulesClient.delete = { id in
                #expect(id == rule.id)
                return []
            }
        }
        let alert = AlertState<MerchantRulesFeature.Action.Alert> {
            TextState("Delete merchant rule?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(rule.id)) { TextState("Delete rule") }
            ButtonState(role: .cancel) { TextState("Cancel") }
        } message: { TextState("Saved transactions will stay unchanged.") }
        await store.send(.deleteTapped(rule.id)) { $0.alert = alert }
        await store.send(.alert(.dismiss)) { $0.alert = nil }
        await store.send(.deleteTapped(rule.id)) { $0.alert = alert }
        await store.send(.alert(.presented(.confirmDelete(rule.id)))) {
            $0.alert = nil
            $0.phase = .saving
        }
        await store.receive(.saved(.success([]))) {
            $0.phase = .idle
            $0.rules = []
        }
    }

    @Test func dismissingScreenCancelsLoading() async {
        let clock = TestClock()
        var state = AppFeature.State()
        state.merchantRules = MerchantRulesFeature.State()
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.merchantRulesClient.load = {
                try await clock.sleep(for: .seconds(10))
                return []
            }
        }
        await store.send(.merchantRules(.presented(.task))) { $0.merchantRules?.phase = .loading }
        await store.send(.merchantRules(.dismiss)) { $0.merchantRules = nil }
        await store.finish()
    }

    @Test func loadFailureBlocksWritesUntilRetrySucceeds() async {
        let store = TestStore(initialState: MerchantRulesFeature.State()) { MerchantRulesFeature() } withDependencies: {
            $0.merchantRulesClient.load = { throw MerchantRule.RuleError.invalid }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.response(.failure(.loading))) {
            $0.phase = .idle
            $0.failure = .loading
        }
        await store.send(.addTapped)
        await store.send(.saveTapped)
        store.dependencies.merchantRulesClient.load = { [] }
        await store.send(.task) {
            $0.phase = .loading
            $0.failure = nil
        }
        await store.receive(.response(.success([]))) { $0.phase = .idle }
        await store.send(.addTapped) { $0.isEditorPresented = true }
    }

    @Test func invalidDraftDoesNotWrite() async {
        let store = TestStore(initialState: MerchantRulesFeature.State()) { MerchantRulesFeature() } withDependencies: {
            $0.uuid = .constant(UUID())
        }
        await store.send(.saveTapped) { $0.failure = .invalid }
    }

    @Test func openingFromImportPrefillsCorrectionWithoutChangingPreview() async throws {
        var state = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
        state.preview = try ImportFixtures.preview()
        let candidate = try #require(state.preview?.candidates.first)
        let store = TestStore(initialState: state) { ImportFeature() }
        await store.send(.saveRuleTapped(candidate.id)) { $0.merchantRules = MerchantRulesFeature.State(candidate: candidate) }
        await store.send(.merchantRules(.dismiss)) { $0.merchantRules = nil }
        #expect(store.state.preview == state.preview)
    }
}
