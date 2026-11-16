//
//  AssistantFeatureTests.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct AssistantFeatureTests {
    private let date = TestFixtures.date
    private let calendar = TestFixtures.calendar
    private let id = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))

    @Test func suggestedQuestionWorksWithoutModelAndOpensOnlyContributingTransactions() async throws {
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        let query = AssistantQuery(kind: .spending)
        let answer = try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
        let store = TestStore(initialState: AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)) {
            AssistantFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.availability = { _ in .deviceNotSupported }
            $0.assistantClient.answer = { query, snapshot, date, calendar in
                try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
            }
        }
        await store.send(.task) { $0.availability = .deviceNotSupported }
        await store.send(.suggested(query)) { $0.requestID = id }
        await store.receive(.response(id, .success(answer))) { $0.requestID = nil; $0.answer = answer; $0.previousQuery = answer.query; $0.isAnswerPresented = true }
        await store.send(.showTransactions(answer.report.month, .eur)) {
            $0.drilldown = SpendingDrilldown(month: answer.report.month, currency: .eur)
            $0.isDrilldownPresented = true
        }
        let transaction = try #require(store.state.drilldownTransactions.first)
        let account = try #require(snapshot.accounts.first { $0.id == transaction.accountID })
        await store.send(.transactionTapped(transaction.id)) {
            $0.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name,
                                                        accounts: snapshot.accounts, original: snapshot.originals[transaction.id])
        }
        #expect(store.state.drilldownTransactions.allSatisfy { $0.kind == .expense || $0.kind == .refund })
    }

    @Test func freeTextRoutesThroughInterpreterThenDeterministicTool() async throws {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.question = "  Compare last month  "
        let query = AssistantQuery(kind: .comparison, period: .lastMonth)
        let answer = try FinancialAssistant().answer(query, snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.interpret = { question, locale in
                #expect(question == "Compare last month")
                #expect(locale.identifier == "en_US")
                return query
            }
            $0.assistantClient.answer = { received, snapshot, receivedDate, receivedCalendar in
                #expect(received == query)
                #expect(snapshot == .empty)
                #expect(receivedDate == TestFixtures.date)
                #expect(receivedCalendar == TestFixtures.calendar)
                return answer
            }
        }
        await store.send(.askTapped) { $0.requestID = id }
        await store.receive(.response(id, .success(answer))) { $0.requestID = nil; $0.answer = answer; $0.previousQuery = answer.query; $0.isAnswerPresented = true }
    }

    @Test(arguments: [AssistantError.modelUnavailable, .unsupportedQuestion, .interpretationFailed])
    func interpretationFailuresDoNotCallFinancialTool(_ failure: AssistantError) async {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.question = "Question"
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.availability = { _ in .notReady }
            $0.assistantClient.interpret = { _, _ in throw failure }
        }
        await store.send(.askTapped) { $0.requestID = id }
        await store.receive(.response(id, .failure(failure))) { $0.requestID = nil; $0.failure = failure }
    }

    @Test func invalidQuestionNeverStartsAnEffect() async {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.question = String(repeating: "a", count: 1_001)
        let store = TestStore(initialState: state) { AssistantFeature() }
        await store.send(.askTapped) { $0.failure = .unsupportedQuestion }
    }

    @Test func arithmeticFailureIsDisplayedWithoutAStaleAnswer() async throws {
        let answer = try FinancialAssistant().answer(.init(kind: .spending), snapshot: .empty, date: date, calendar: calendar)
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.answer = answer
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.answer = { _, _, _, _ in throw ValidationError.arithmeticFailure }
        }
        await store.send(.suggested(.init(kind: .spending))) { $0.requestID = id; $0.answer = nil }
        await store.receive(.response(id, .failure(.calculationFailed))) { $0.requestID = nil; $0.failure = .calculationFailed }
    }

    @Test func cancellationAndContextChangesPreventLateResults() async throws {
        let clock = TestClock()
        let answer = try FinancialAssistant().answer(.init(kind: .spending), snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)) {
            AssistantFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.answer = { _, _, _, _ in
                try await clock.sleep(for: .seconds(10))
                return answer
            }
        }
        await store.send(.suggested(.init(kind: .spending))) { $0.requestID = id }
        await store.send(.cancelTapped) { $0.requestID = nil }
        await clock.advance(by: .seconds(10))
        await store.send(.response(id, .success(answer)))
        await store.send(.suggested(.init(kind: .spending))) { $0.requestID = id }
        let nextMonth = try #require(calendar.date(byAdding: .month, value: 1, to: date))
        await store.send(.contextUpdated(.empty, nextMonth, calendar)) { $0.referenceDate = nextMonth; $0.requestID = nil }
        await clock.advance(by: .seconds(10))
        await store.send(.response(id, .success(answer)))
        #expect(store.state.answer == nil)
    }

    @Test func aNewQuestionCancelsThePreviousRequest() async throws {
        let clock = TestClock()
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        let first = AssistantQuery(kind: .spending)
        let second = AssistantQuery(kind: .comparison)
        let answer = try FinancialAssistant().answer(second, snapshot: snapshot, date: date, calendar: calendar)
        let store = TestStore(initialState: AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)) {
            AssistantFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.answer = { query, snapshot, date, calendar in
                try await clock.sleep(for: .seconds(1))
                return try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
            }
        }
        await store.send(.suggested(first)) { $0.requestID = UUID(0) }
        await store.send(.suggested(second)) { $0.requestID = UUID(1) }
        await store.send(.response(UUID(0), .success(answer)))
        await clock.advance(by: .seconds(1))
        await store.receive(.response(UUID(1), .success(answer))) {
            $0.requestID = nil
            $0.answer = answer
            $0.previousQuery = answer.query
            $0.isAnswerPresented = true
        }
    }

    @Test func clearRemovesQuestionAnswerAndNavigation() async throws {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.question = "Question"
        state.answer = try FinancialAssistant().answer(.init(kind: .spending), snapshot: .empty, date: date, calendar: calendar)
        state.previousQuery = state.answer?.query
        state.drilldown = SpendingDrilldown(month: date, currency: .eur)
        state.isDrilldownPresented = true
        let store = TestStore(initialState: state) { AssistantFeature() }
        await store.send(.clearTapped) {
            $0.question = ""; $0.answer = nil; $0.previousQuery = nil; $0.drilldown = nil; $0.isDrilldownPresented = false
        }
    }

    @Test func periodFollowUpPreservesMerchantAndNavigationWithoutModel() async throws {
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        let merchant = try #require(snapshot.transactions.first(where: { $0.kind == .expense })?.merchant)
        let first = AssistantQuery(kind: .merchant, merchant: merchant)
        let second = AssistantQuery(kind: .merchant, period: .lastMonth, merchant: merchant)
        var state = AssistantFeature.State(snapshot: snapshot, referenceDate: date, calendar: calendar)
        state.answer = try FinancialAssistant().answer(first, snapshot: snapshot, date: date, calendar: calendar)
        state.previousQuery = first
        state.isAnswerPresented = true
        let answer = try FinancialAssistant().answer(second, snapshot: snapshot, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.answer = { query, snapshot, date, calendar in
                #expect(query == second)
                return try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
            }
        }
        await store.send(.followUp(.lastMonth)) { $0.requestID = id; $0.answer = nil }
        await store.receive(.response(id, .success(answer))) {
            $0.requestID = nil; $0.answer = answer; $0.previousQuery = second
        }
        #expect(store.state.isAnswerPresented)
        let currency = try #require(answer.report.currencies.first?.currency)
        await store.send(.showTransactions(answer.report.month, currency)) {
            $0.drilldown = SpendingDrilldown(month: answer.report.month, currency: currency, group: .merchant(merchant))
            $0.isDrilldownPresented = true
        }
        #expect(store.state.drilldownTransactions.isEmpty == false)
        #expect(store.state.drilldownTransactions.allSatisfy { $0.merchant == merchant })
    }

    @Test func typedFollowUpUsesLastSuccessfulScopeWithoutInterpreter() async throws {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.previousQuery = .init(kind: .comparison)
        state.question = "А за прошлый месяц?"
        let query = AssistantQuery(kind: .comparison, period: .lastMonth)
        let answer = try FinancialAssistant().answer(query, snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.answer = { query, snapshot, date, calendar in
                #expect(query.kind == .comparison)
                #expect(query.period == .lastMonth)
                return try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
            }
        }
        await store.send(.askTapped) { $0.requestID = id }
        await store.receive(.response(id, .success(answer))) {
            $0.requestID = nil; $0.answer = answer; $0.previousQuery = query; $0.isAnswerPresented = true
        }
    }

    @Test func followUpWithoutContextNeverCallsModel() async {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.question = "And last month?"
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: { $0.date.now = date }
        await store.send(.askTapped) { $0.failure = .unsupportedQuestion }
        await store.send(.followUp(.lastMonth))
    }

    @Test func monthRolloverInvalidatesContextBeforeFollowUp() async throws {
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.previousQuery = .init(kind: .merchant, merchant: "REWE")
        state.question = "And last month?"
        let nextMonth = try #require(calendar.date(byAdding: .month, value: 1, to: date))
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.date.now = nextMonth
            $0.locale = Locale(identifier: "en_US")
            $0.assistantClient.availability = { _ in .notReady }
        }
        await store.send(.askTapped) { $0.failure = .unsupportedQuestion }
        await store.send(.followUp(.lastMonth))
        await store.send(.task)
        await store.receive(.contextUpdated(.empty, nextMonth, calendar)) {
            $0.previousQuery = nil; $0.referenceDate = nextMonth; $0.failure = nil
        }
    }

    @Test func cancelledFollowUpKeepsSuccessfulContextAndRejectsLateResponse() async throws {
        let first = AssistantQuery(kind: .comparison)
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.previousQuery = first
        state.answer = try FinancialAssistant().answer(first, snapshot: .empty, date: date, calendar: calendar)
        state.isAnswerPresented = true
        let answer = try #require(state.answer)
        let clock = TestClock()
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.uuid = .constant(id)
            $0.assistantClient.answer = { _, _, _, _ in
                try await clock.sleep(for: .seconds(1))
                return answer
            }
        }
        await store.send(.followUp(.lastMonth)) { $0.requestID = id; $0.answer = nil }
        await store.send(.cancelTapped) { $0.requestID = nil; $0.isAnswerPresented = false }
        await clock.advance(by: .seconds(1))
        await store.send(.response(id, .success(answer)))
        #expect(store.state.previousQuery == first)
    }

    @Test func failedNewQuestionDoesNotReplaceSuccessfulContext() async {
        let previous = AssistantQuery(kind: .merchant, merchant: "REWE")
        var state = AssistantFeature.State(snapshot: .empty, referenceDate: date, calendar: calendar)
        state.previousQuery = previous
        let store = TestStore(initialState: state) { AssistantFeature() } withDependencies: {
            $0.date.now = date
            $0.locale = Locale(identifier: "en_US")
            $0.uuid = .constant(id)
            $0.assistantClient.answer = { _, _, _, _ in throw AssistantError.calculationFailed }
        }
        await store.send(.suggested(.init(kind: .comparison))) { $0.requestID = id }
        await store.receive(.response(id, .failure(.calculationFailed))) {
            $0.requestID = nil; $0.failure = .calculationFailed
        }
        #expect(store.state.previousQuery == previous)
    }
}
