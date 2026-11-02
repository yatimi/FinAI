//
//  AssistantCategoryQuestion.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import Foundation

/// Complete supported phrases can select the deterministic tool without a model.
struct AssistantCategoryQuestion {
    func resolve(_ question: String) -> AssistantQuery? {
        let text = AssistantCategoryVocabulary.normalized(question)
        for category in AssistantCategoryVocabulary.categories {
            for alias in AssistantCategoryVocabulary.aliases(for: category) {
                for period in [AssistantQuery.Period.thisMonth, .lastMonth] {
                    let english = period == .thisMonth ? "this month" : "last month"
                    let russian = period == .thisMonth ? "за этот месяц" : "за прошлый месяц"
                    let ukrainian = period == .thisMonth ? "за цей місяць" : "за минулий місяць"
                    var phrases = ["how much did i spend on \(alias) \(english)",
                                   "spending on \(alias) \(english)",
                                   "сколько я потратил на \(alias) \(russian)",
                                   "сколько потратил на \(alias) \(russian)",
                                   "скільки я витратив на \(alias) \(ukrainian)",
                                   "скільки витратив на \(alias) \(ukrainian)"]
                    if period == .thisMonth {
                        phrases += ["how much did i spend on \(alias)", "spending on \(alias)",
                                    "сколько я потратил на \(alias)", "сколько потратил на \(alias)",
                                    "скільки я витратив на \(alias)", "скільки витратив на \(alias)"]
                    }
                    if phrases.contains(text) { return AssistantQuery(kind: .spending, period: period, category: category) }
                }
            }
        }
        return nil
    }
}
