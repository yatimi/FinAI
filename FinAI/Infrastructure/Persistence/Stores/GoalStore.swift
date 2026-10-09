//
//  GoalStore.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation
import SwiftData

struct GoalStore {
    func load(in context: ModelContext) throws -> [SavingsGoal] {
        try Task.checkCancellation()
        return try context.fetch(FetchDescriptor<GoalRecord>(sortBy: [SortDescriptor(\.deadline), SortDescriptor(\.name)]))
            .map { try $0.domainValue() }
    }

    func save(_ goal: SavingsGoal, expected: SavingsGoal?, in context: ModelContext) throws -> [SavingsGoal] {
        try goal.validate()
        try Task.checkCancellation()
        let records = try context.fetch(FetchDescriptor<GoalRecord>())
        let record = records.first { $0.id == goal.id }
        guard expected == nil || expected?.id == goal.id,
              try record?.domainValue() == expected else { throw SavingsGoal.GoalError.changed }
        let result = try records.filter { $0.id != goal.id }.map { try $0.domainValue() } + [goal]
        do {
            if let record { record.apply(goal) } else { context.insert(GoalRecord(goal)) }
            try Task.checkCancellation()
            try context.save()
        } catch { context.rollback(); throw error }
        return result.sorted { $0.deadline == $1.deadline ? $0.name < $1.name : $0.deadline < $1.deadline }
    }
}
