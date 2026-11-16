//
//  GeneratedAssistantQueryTests.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct GeneratedAssistantQueryTests {
    @Test func structuredOutputIsValidatedBeforeUse() throws {
        let valid = GeneratedAssistantQuery(operation: .merchant, period: .lastMonth, merchant: " REWE ")
        #expect(try valid.validated(question: "Spending at REWE last month") == AssistantQuery(kind: .merchant, period: .lastMonth, merchant: "REWE"))
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .unsupported, period: .thisMonth, merchant: "").validated(question: "Question")
        }
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .spending, period: .unsupported, merchant: "").validated(question: "Question")
        }
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .comparison, period: .thisMonth, merchant: "REWE").validated(question: "Question")
        }
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .merchant, period: .thisMonth, merchant: " ").validated(question: "Question")
        }
    }

    @Test func inventedMerchantIsRejectedEvenWhenStructureIsValid() {
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .merchant, period: .thisMonth, merchant: "Amazon")
                .validated(question: "How much did I spend at REWE?")
        }
    }

    @Test func oversizedGeneratedMerchantIsRejected() {
        let name = String(repeating: "a", count: 201)
        #expect(throws: AssistantError.unsupportedQuestion) {
            try GeneratedAssistantQuery(operation: .merchant, period: .thisMonth, merchant: name).validated(question: name)
        }
    }

    @Test func emptyOrOversizedQuestionsAreRejectedBeforeModelUse() async {
        let interpreter = OnDeviceQuestionInterpreter()
        for question in [" ", String(repeating: "a", count: 1_001)] {
            await #expect(throws: AssistantError.unsupportedQuestion) {
                try await interpreter.interpret(question, locale: Locale(identifier: "en_US"))
            }
        }
    }
}
