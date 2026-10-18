//
//  AssistantError.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

enum AssistantError: Error, Equatable {
    case unsupportedQuestion
    case merchantNotFound
    case ambiguousMerchant
    case modelUnavailable
    case interpretationFailed
    case calculationFailed
}
