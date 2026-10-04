//
//  ExchangeRateProvider.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

/// Future boundary for historical, transaction-date rates. No live provider is installed.
protocol ExchangeRateProvider: Sendable {
    func rate(from source: Currency, to destination: Currency, on date: Date) async throws -> Decimal
}
