//
//  AssistantScopeFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 30.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct AssistantScopeFeatureTests {
    @Test func typedCategoryWorksWithoutCallingInterpreter() async throws {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        state.question = "Сколько потратил на продукты?"
        let query = AssistantQuery(kind: .spending, category: .groceries)
        let answer = try FinancialAssistant().answer(query, snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.locale = Locale(identifier: "en_US"); $0.uuid = .constant(UUID(0))
            $0.assistantClient.answer = { received, _, _, _ in #expect(received == query); return answer }
        }
        await store.send(.askTapped) { $0.requestID = UUID(0) }
        await store.receive(.response(UUID(0), .success(answer))) {
            $0.requestID = nil; $0.answer = answer; $0.previousQuery = query; $0.isAnswerPresented = true
        }
    }

    @Test func rentRefinementRequiresSelectionAndDrilldownPreservesEveryFilter() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let merchant = try #require(snapshot.transactions.first { $0.merchant == "Demo rent" }?.merchant)
        let first = AssistantQuery(kind: .spending, category: .groceries)
        var state = AssistantFeature.State(snapshot: snapshot, referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        state.previousQuery = first
        state.question = "А без аренды?"
        state.isAnswerPresented = true
        let query = AssistantQuery(kind: .spending, category: .groceries, excludedMerchant: merchant)
        let answer = try FinancialAssistant().answer(query, snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.locale = Locale(identifier: "en_US"); $0.uuid = .constant(UUID(0))
            $0.assistantClient.answer = { received, _, _, _ in #expect(received == query); return answer }
        }
        await store.send(.askTapped) { $0.pendingRentQuery = first; $0.isRentMerchantSelectionPresented = true }
        await store.send(.rentMerchantChosen("Invented merchant"))
        #expect(store.state.previousQuery == first)
        await store.send(.rentMerchantChosen(merchant)) {
            $0.pendingRentQuery = nil; $0.isRentMerchantSelectionPresented = false; $0.requestID = UUID(0)
        }
        await store.receive(.response(UUID(0), .success(answer))) {
            $0.requestID = nil; $0.answer = answer; $0.previousQuery = query
        }
        let currency = try #require(answer.report.currencies.first?.currency)
        await store.send(.showTransactions(answer.report.month, currency)) {
            $0.drilldown = SpendingDrilldown(month: answer.report.month, currency: currency,
                                            group: .category(.groceries), excludedMerchant: merchant)
            $0.isDrilldownPresented = true
        }
        #expect(store.state.drilldownTransactions.isEmpty == false)
        #expect(store.state.drilldownTransactions.allSatisfy { $0.category == .groceries && $0.merchant != merchant })
    }

    @Test func rentSelectionCancellationAndMonthChangeDoNotMutateContext() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let query = AssistantQuery(kind: .comparison, category: .groceries)
        var state = AssistantFeature.State(snapshot: snapshot, referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        state.previousQuery = query
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: { $0.date.now = TestFixtures.date }
        await store.send(.withoutRentTapped) { $0.pendingRentQuery = query; $0.isRentMerchantSelectionPresented = true }
        await store.send(.rentSelectionCancelled) { $0.pendingRentQuery = nil; $0.isRentMerchantSelectionPresented = false }
        #expect(store.state.previousQuery == query)
        await store.send(.withoutRentTapped) { $0.pendingRentQuery = query; $0.isRentMerchantSelectionPresented = true }
        let next = try #require(TestFixtures.calendar.date(byAdding: .month, value: 1, to: TestFixtures.date))
        await store.send(.contextUpdated(snapshot, next, TestFixtures.calendar)) {
            $0.referenceDate = next; $0.previousQuery = nil; $0.pendingRentQuery = nil; $0.isRentMerchantSelectionPresented = false
        }
        await store.send(.rentMerchantChosen("Demo rent"))
    }

    @Test func rentWithoutPreviousAnswerIsRejectedWithoutModel() async {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        state.question = "А без аренды?"
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: { $0.date.now = TestFixtures.date }
        await store.send(.askTapped) { $0.failure = .unsupportedQuestion }
    }
}
