//
//  MerchantRuleStore.swift
//  FinAI
//
//  Created by Tommy on 03.10.26.
//

import Foundation
import SwiftData

/// Synchronous operations run within FinanceDatabase isolation.
struct MerchantRuleStore {
    func load(in context: ModelContext) throws -> [MerchantRule] {
        try Task.checkCancellation()
        return try context.fetch(FetchDescriptor<MerchantRuleRecord>(sortBy: [SortDescriptor(\.pattern)]))
            .map { try $0.domainValue() }
    }

    /// Accepts a validated rule and checks conflicts against saved rules.
    func save(_ rule: MerchantRule, replacingExisting: Bool, in context: ModelContext) throws -> [MerchantRule] {
        try Task.checkCancellation()
        let records = try context.fetch(FetchDescriptor<MerchantRuleRecord>())
        let existing = records.first { $0.id == rule.id }
        guard !replacingExisting || existing != nil else { throw MerchantRule.RuleError.missing }
        guard replacingExisting || existing == nil else { throw MerchantRule.RuleError.conflict }
        let otherRules = try records.filter { $0.id != rule.id }.map { try $0.domainValue() }
        guard !otherRules.contains(where: { rule.conflicts(with: $0) }) else { throw MerchantRule.RuleError.conflict }
        let result = (otherRules + [rule]).sorted { $0.pattern < $1.pattern }
        do {
            if let existing {
                existing.pattern = rule.pattern
                existing.matchMode = rule.matchMode.rawValue
                existing.kind = rule.kind.rawValue
                existing.merchant = rule.merchant
                existing.category = rule.category.rawValue
            } else { context.insert(MerchantRuleRecord(rule)) }
            try Task.checkCancellation()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return result
    }

    func delete(_ id: UUID, in context: ModelContext) throws -> [MerchantRule] {
        try Task.checkCancellation()
        let records = try context.fetch(FetchDescriptor<MerchantRuleRecord>())
        let result = try records.filter { $0.id != id }.map { try $0.domainValue() }.sorted { $0.pattern < $1.pattern }
        do {
            for record in records where record.id == id { context.delete(record) }
            try Task.checkCancellation()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return result
    }
}
