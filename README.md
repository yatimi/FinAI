# FinAI

A local-first personal finance app for iOS, building toward an assistant that helps explain financial activity and plan ahead.

## Available today

- Synthetic demo data across bank, savings and credit accounts
- CSV import with column mapping, validation, editable preview and explicit confirmation
- Local merchant normalization and category suggestions, editable before import
- Exact duplicate warnings and atomic, retry-safe import persistence
- Persistent on-device accounts and transactions using SwiftData
- Monthly income, expenses, refunds, net spending and net flow, grouped by original currency
- Current-month spending by category and saved merchant, with previous-month net spending comparisons per currency
- Transaction search across merchant names and original descriptions, with combined date, account, category, type and currency filters
- Transaction details with original descriptions, categories, source and account information
- English String Catalog localization and locale-aware money and date formatting

Demo data is loaded only after confirmation and only into an empty store. It includes salary, rent, groceries, transport, subscriptions, utilities, shopping, refunds and transfers across three months. No bank account or personal data is needed.

## How it works

Swift code calculates every total using `Decimal`. Currencies are kept separate, transfers are excluded from spending and income, and refunds reduce net spending without becoming income. Adjustments and unknown transactions are excluded from the monthly summary. The overview describes activity, not account balances. Analytics compares the current calendar month with the full previous month using saved transactions; the current month may be incomplete. Refunds apply to their recorded month and category. Percentage changes are shown only for a positive previous net spending total.

The app preserves original amounts, currencies, descriptions and source metadata. CSV files are parsed locally. Nothing is saved until the selected transactions are confirmed. Import sessions retain the source filename and record numbers; the original file is neither copied into storage nor modified.

## Architecture

```text
SwiftUI → TCA feature → dependency client → domain services / persistence
```

- **Domain:** value types and deterministic financial calculations, independent of UI and persistence frameworks
- **Features:** TCA state, actions, navigation, confirmation, loading, errors and cancellation
- **Dependencies:** an injectable client connecting features to domain services and storage
- **Infrastructure:** actor-isolated SwiftData access with explicit saves and no model contexts exposed to features

The project uses Swift 6 with strict concurrency checking, SwiftUI, The Composable Architecture 1.26.2, SwiftData, Swift Testing and XCTest UI tests. Package versions are checked in for reproducible resolution with Xcode 27.

## Getting started

Requirements: Xcode 27 or later and an iOS 26 or later simulator or device.

1. Open `FinAI.xcodeproj` and let Xcode resolve Swift packages.
2. Enable the package macros when Xcode prompts.
3. Select the shared **FinAI** scheme and an iOS simulator, then run.
4. Choose **Explore demo**, or use **Import CSV** to load a file.

For a physical device, choose your own signing team for the app and test targets. Data persists between launches. The first confirmed import replaces synthetic demo records, with a warning before confirmation. General editing and deletion are not available yet.

## CSV import

1. Choose a file from Files and select an existing account or name a new one.
2. Map date, amount and description columns. Currency and transaction type are optional.
3. Choose the date format, decimal separator and money direction convention.
4. Review valid rows and validation errors, adjust merchant names, transaction types and categories, and select which rows to keep.
5. Confirm the import. Invalid rows are skipped and possible duplicates start unchecked.

Try [the synthetic sample](Examples/transactions.csv) to exercise expenses, income, transfers and refunds without personal data.

Supported files have a header row and use UTF-8 or BOM-marked UTF-16. Comma, semicolon and tab separators are detected automatically; quoted fields, escaped quotes and multiline descriptions are supported. Limits are 2 MiB, 5,000 data rows, 64 columns and 8 KiB per field.

Dates use `yyyy-MM-dd`, `dd.MM.yyyy`, `dd/MM/yyyy` or `MM/dd/yyyy` in the device time zone. Amounts use explicit dot/comma decimal formats, with optional thousands separators. Currency symbols and ambiguous or unsupported numeric precision are rejected. Amounts and combined totals must fit exact `Decimal` arithmetic.

A negative sign describes money leaving the account; it does not classify the transaction. Without a type column or an explicit default, rows remain **Unknown** and do not affect overview totals. Supported type values are `expense`, `income`, `transfer`, `refund`, `adjustment` and `unknown`. Types and categories can be adjusted in the preview.

Duplicate warnings compare exact dates, trimmed descriptions, amounts, currencies and directions within the file and the selected account. They are review hints: distinct payments may share those fields. Fuzzy duplicate matching is planned. Normalization does not change the exact duplicate comparison.

Known descriptions such as `REWE MARKT`, `AMZN` and `DB VERTRIEB` receive local merchant and category suggestions. Rules match the start of the description on word boundaries, with more specific aliases taking precedence. Unknown merchants retain their original name. Income and transfer categories follow the explicit transaction type; unknown and adjustment types remain uncategorized. Review suggestions before saving: merchants and categories are editable, and changing the type resets its category suggestion. Corrections apply to the current row; reusable user rules are planned. Existing saved transactions are unchanged.

## Transaction search

Search is local, ignores case and accents, and matches merchant names or original descriptions. Filters apply together: choose all dates, this month, last month or an inclusive custom date range, plus an account, category, transaction type and currency. Results retain their original amounts and currencies.

Search and filters stay in place when switching tabs or refreshing. Reset clears them together; a successful import also clears them so newly imported transactions are visible. Filters are not saved between app launches.

## Tests

Use **Product → Test** in Xcode, or select an installed simulator from `xcrun simctl list devices available` and run:

```sh
xcodebuild test \
  -project FinAI.xcodeproj \
  -scheme FinAI \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -skipMacroValidation \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO
```

Tests cover decimal arithmetic and validation, currency separation, transfers and refunds, date boundaries, demo integrity, persistence and repeated seeding, feature loading/error/cancellation flows, CSV parsing and locale validation, import confirmation, duplicate hints, migration and retry-safe persistence. Analytics tests cover category and merchant totals, month boundaries, refund-only periods, currencies missing from one month, percentage baselines and arithmetic overflow. UI journeys cover the demo, import preview/confirmation, transaction search and analytics. UI tests use an isolated in-memory store. GitHub Actions builds and tests pull requests to `develop` and `main` using the Xcode 27 runner image.

## Privacy

The app stores data locally, with no account, bank connection, remote AI service, analytics SDK or custom backend. SwiftData CloudKit integration is disabled. Future remote processing will require explicit consent and a defined privacy boundary.

## Planned

1. Reusable merchant rules, broader categorization, richer duplicate review and expanded deterministic analytics
2. An assistant that queries and explains calculated results
3. Budgets, goals, forecasts and what-if planning
4. Document and receipt import, followed by investigation of connected banking

These capabilities are not yet implemented.
