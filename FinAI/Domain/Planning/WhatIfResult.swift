//
//  WhatIfResult.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

struct WhatIfResult: Equatable, Sendable {
    let scenario: WhatIfScenario
    let baseline: MonthForecast.Projection
    let expenses: Money
    let income: Money
    let netSpending: Money
    let netFlow: Money
    let netFlowChange: Money
}
