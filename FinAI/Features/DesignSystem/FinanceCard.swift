//
//  FinanceCard.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import SwiftUI

struct FinanceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FinanceStyle.Spacing.standard)
            .background(FinanceStyle.Surface.card, in: .rect(cornerRadius: FinanceStyle.cardRadius))
    }
}
