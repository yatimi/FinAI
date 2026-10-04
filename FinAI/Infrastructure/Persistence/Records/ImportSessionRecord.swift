//
//  ImportSessionRecord.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData

@Model
final class ImportSessionRecord {
    @Attribute(.unique) var id: UUID
    var sourceName: String
    var importedAt: Date
    var accountID: UUID
    var transactionIDs: [UUID]
    var rowNumbers: [Int]

    init(_ batch: ImportBatch) {
        id = batch.id
        sourceName = batch.sourceName
        importedAt = batch.importedAt
        accountID = batch.account.id
        transactionIDs = batch.transactions.map(\.id)
        rowNumbers = batch.rowNumbers
    }
}
