//
//  AssistantRentMerchantView.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import SwiftUI

struct AssistantRentMerchantView: View {
    let merchants: [String]
    let choose: (String) -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section { Text(.assistantRentMerchantExplanation).font(.footnote) }
                ForEach(merchants, id: \.self) { merchant in
                    Button { choose(merchant) } label: {
                        Text(verbatim: merchant).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle(.assistantChooseRentMerchant)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(.cancel, action: cancel) }
            }
        }
    }
}
