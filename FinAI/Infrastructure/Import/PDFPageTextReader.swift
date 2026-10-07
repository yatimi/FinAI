//
//  PDFPageTextReader.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import Foundation
import PDFKit

/// Restores visual reading order instead of relying on PDFKit's platform-specific text stream.
struct PDFPageTextReader {
    private struct Fragment {
        let text: String
        let bounds: CGRect
    }

    func text(from page: PDFPage) throws -> String {
        try Task.checkCancellation()
        guard let selection = page.selection(for: page.bounds(for: .mediaBox)) else { throw ImportError.pdfNeedsText }
        var fragments: [Fragment] = []
        var bytes = 0
        for line in selection.selectionsByLine() {
            try Task.checkCancellation()
            let text = (line.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let bounds = line.bounds(for: page)
            guard !bounds.isEmpty, !bounds.isInfinite, !bounds.isNull,
                  bounds.midY.isFinite, bounds.minX.isFinite else { throw ImportError.malformedStatement }
            bytes += text.utf8.count
            guard bytes <= PDFStatementReader.maximumTextBytes else { throw ImportError.pdfTooLarge }
            fragments.append(Fragment(text: text, bounds: bounds))
        }
        // Sort without a fuzzy comparator, then group adjacent fragments against a fixed
        // baseline. A tolerance inside the comparator would violate strict ordering.
        fragments.sort {
            if $0.bounds.midY != $1.bounds.midY { return $0.bounds.midY > $1.bounds.midY }
            return $0.bounds.minX < $1.bounds.minX
        }
        var lines: [String] = []
        var row: [Fragment] = []
        func appendRow() {
            guard !row.isEmpty else { return }
            lines.append(row.sorted { $0.bounds.minX < $1.bounds.minX }.map(\.text).joined(separator: " "))
            row = []
        }
        for fragment in fragments {
            try Task.checkCancellation()
            if let anchor = row.first, abs(anchor.bounds.midY - fragment.bounds.midY) > 2 {
                appendRow()
            }
            row.append(fragment)
        }
        appendRow()
        guard !lines.isEmpty else { throw ImportError.pdfNeedsText }
        return lines.joined(separator: "\n")
    }
}
