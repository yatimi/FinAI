//
//  ValidationError.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

enum ValidationError: Error, Equatable {
    case invalidCurrency
    case invalidAmount
    case currencyMismatch
    case arithmeticFailure
    case invalidTransaction
    case invalidSnapshot
}
