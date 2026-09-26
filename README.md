# FinAI

FinAI is an iOS personal finance copilot in early development, designed around local processing and user control over financial data.

## Current status

The repository currently contains the initial SwiftUI app and unit/UI test targets. Financial features are not implemented yet.

## Planned direction

- Demo data and a foundation for accounts and transactions
- Import with preview and confirmation
- Deterministic financial analytics
- An assistant that explains calculated results
- Budgets, goals and planning

## Getting started

Open `FinAI.xcodeproj` in Xcode. The current project targets iOS 26.0; building requires an Xcode installation with a compatible SDK. Select the FinAI scheme and a compatible iOS simulator. Device builds require your own signing configuration.

## Privacy

The intended design prioritizes local storage and processing, without a mandatory account or custom backend. Any future remote processing will require explicit user consent.

The app uses Swift 6, SwiftUI and The Composable Architecture.
