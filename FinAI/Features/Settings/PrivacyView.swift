//
//  PrivacyView.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section(.privacyLocalTitle) { Text(.privacyLocalDetails) }
            Section(.privacyAssistantTitle) { Text(.privacyAssistantDetails) }
            Section(.privacyBackupTitle) { Text(.privacyBackupDetails) }
            Section(.privacyProtectionTitle) { Text(.privacyProtectionDetails) }
            Section(.privacyImportTitle) { Text(.privacyImportDetails) }
        }
        .navigationTitle(.settingsPrivacy)
    }
}
