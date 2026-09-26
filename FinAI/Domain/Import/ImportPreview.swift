//
//  ImportPreview.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct ImportPreview: Equatable, Sendable {
    struct Issue: Identifiable, Equatable, Sendable {
        let rowNumber: Int
        let error: ImportError
        var id: Int { rowNumber }
    }
    var candidates: [ImportCandidate]
    let issues: [Issue]
}
