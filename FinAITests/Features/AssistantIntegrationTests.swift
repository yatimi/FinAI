//
//  AssistantIntegrationTests.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct AssistantIntegrationTests {
    @Test func rootOpensAssistantOnlyWithLoadedDataAndPreservesTransactionSearch() async throws {
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: date, calendar: calendar)
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.assistantTapped)
        await store.send(.task) { $0.isLoading = true }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false; $0.overview = overview
            $0.transactions.update(snapshot: snapshot, date: date, calendar: calendar)
        }
        await store.send(.assistantTapped) {
            $0.assistant = AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)
        }
        #expect(store.state.transactions.query == TransactionQuery())
    }

    @Test func refreshInvalidatesAnAnswerWhenFinancialDataChanges() async throws {
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        var state = AppFeature.State()
        state.overview = try FinanceOverview.make(snapshot: snapshot, date: date, calendar: calendar)
        state.assistant = AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)
        state.assistant?.answer = try FinancialAssistant().answer(.init(kind: .spending), snapshot: snapshot, date: date, calendar: calendar)
        state.assistant?.previousQuery = .init(kind: .spending)
        state.transactions.query.text = "Existing search"
        let fresh = try FinanceOverview.make(snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
            $0.financeClient.load = { _, _ in fresh }
        }
        await store.send(.refresh) { $0.isLoading = true }
        await store.receive(.response(.success(fresh))) {
            $0.isLoading = false; $0.overview = fresh
            $0.transactions.update(snapshot: .empty, date: date, calendar: calendar)
        }
        await store.receive(.assistant(.presented(.contextUpdated(.empty, date, calendar)))) {
            $0.assistant?.snapshot = .empty
            $0.assistant?.answer = nil
            $0.assistant?.previousQuery = nil
        }
        #expect(store.state.transactions.query.text == "Existing search")
    }
    @Test func aCorrectionFromAssistantRefreshesRootAnalyticsAndInvalidatesItsAnswer() async throws {
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        var state = AppFeature.State()
        state.overview = try FinanceOverview.make(snapshot: snapshot, date: date, calendar: calendar)
        state.analytics.update(snapshot: snapshot, date: date, calendar: calendar)
        state.transactions.query.text = "Existing search"
        state.assistant = AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)
        state.assistant?.answer = try FinancialAssistant().answer(.init(kind: .spending), snapshot: snapshot, date: date, calendar: calendar)
        state.assistant?.previousQuery = .init(kind: .spending)
        state.assistant?.isAnswerPresented = true
        let fresh = try FinanceOverview.make(snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
        }
        await store.send(.assistant(.presented(.delegate(.didUpdate(fresh))))) {
            $0.overview = fresh
            $0.analytics.update(snapshot: .empty, date: date, calendar: calendar)
            $0.transactions.update(snapshot: .empty, date: date, calendar: calendar)
        }
        await store.receive(.assistant(.presented(.contextUpdated(.empty, date, calendar)))) {
            $0.assistant?.snapshot = .empty
            $0.assistant?.answer = nil
            $0.assistant?.previousQuery = nil
            $0.assistant?.isAnswerPresented = false
        }
        #expect(store.state.transactions.query.text == "Existing search")
    }

}
