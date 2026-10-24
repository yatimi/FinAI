# FinAI

A local-first personal finance app for iOS for importing transactions, understanding spending and planning savings.

Version **0.2.0** is the latest source release. Build and run it with Xcode; no App Store or TestFlight distribution is included. See the [changelog](CHANGELOG.md) and [release process](docs/RELEASING.md).

## Available today

- Synthetic demo data across bank, savings and credit accounts
- CSV import with column mapping, validation, editable preview and explicit confirmation
- Local text-based German Sparkasse PDF statement import with balance reconciliation and the same editable review flow
- Local merchant normalization and category suggestions, editable before import
- Saved local merchant and category rules, with explicit matching and rule management
- Exact and conservative similar-transaction duplicate hints, with match evidence and explicit skip/keep-both review
- Atomic, retry-safe import persistence
- Persistent on-device accounts and transactions using SwiftData
- Monthly income, expenses, refunds, net spending and net flow, grouped by original currency
- Current-month spending by category and saved merchant, with previous-month net spending comparisons per currency
- Possible weekly, monthly and yearly recurring expenses, with evidence counts, estimated dates and subscription hints
- Transaction search across merchant names and original descriptions, with combined date, account, category, type and currency filters
- Transaction details with original descriptions, categories, source and account information
- An explainable month-end spending and net-flow forecast using previous-month activity and detected recurring expenses, separated by currency
- Temporary current-month what-if scenarios for additional expenses/income or reductions of estimated remaining amounts
- Repeating monthly category budgets with exact limits, net spending, remaining amounts and overspend per original currency
- Local savings goals with editable targets, deadlines and manually recorded savings; deterministic remaining amounts and monthly contribution schedules
- Saved-transaction editing from a list swipe action or transaction details, with validation, explicit saving and preserved original values
- A read-only spending assistant with suggested questions, optional on-device free-text interpretation, currency-separated results and transaction drilldowns
- English String Catalog localization and locale-aware money and date formatting

Demo data is loaded only after confirmation and only into an empty store. It includes salary, rent, groceries, transport, subscriptions, utilities, shopping, refunds and transfers across three months. No bank account or personal data is needed.

## How it works

The three tabs are **Home**, **Transactions** and **Plan**. Home links to analytics and accounts. Plan shows monthly budget limits, net spending, remaining amounts and overspend alongside manually recorded goal savings, remaining targets and deadline status. Progress bars accompany exact currency amounts. Create a budget or goal from the plus menu and open a saved item to edit it.

Swift code calculates every total using `Decimal`. Currencies are kept separate, transfers are excluded from spending and income, and refunds reduce net spending without becoming income. Adjustments and unknown transactions are excluded from the monthly summary. The overview describes activity, not account balances. Analytics compares the current calendar month with the full previous month using saved transactions; the current month may be incomplete. Refunds apply to their recorded month and category. Percentage changes are shown only for a positive previous net spending total.

The app preserves original amounts, currencies, descriptions and source metadata. CSV and supported PDF statements are parsed locally. Nothing is saved until the selected transactions are confirmed. Import sessions retain the source filename and record numbers; the original file is neither copied into storage nor modified.

## Architecture

```text
SwiftUI → TCA feature → dependency client → domain services / persistence
```

- **Domain:** value types and deterministic financial calculations, independent of UI and persistence frameworks
- **Features:** TCA state, actions, navigation, confirmation, loading, errors and cancellation
- **Dependencies:** an injectable client connecting features to domain services and storage
- **Infrastructure:** actor-isolated SwiftData access with explicit saves and no model contexts exposed to features

The project uses Swift 6 with strict concurrency checking, SwiftUI, The Composable Architecture 1.26.2, SwiftData, PDFKit, Swift Testing and XCTest UI tests. Package versions are checked in for reproducible resolution with Xcode 27.

## Getting started

Requirements: Xcode 27 or later and an iOS 26 or later simulator or device.

1. Open `FinAI.xcodeproj` and let Xcode resolve Swift packages.
2. Enable the package macros when Xcode prompts.
3. Select the shared **FinAI** scheme and an iOS simulator, then run.
4. Choose **Explore demo**, or use **Import transactions** to load CSV or a supported PDF statement.

For a physical device, choose your own signing team for the app and test targets. Data persists between launches. The first confirmed import replaces synthetic demo records, with a warning before confirmation. Saved transactions can be edited; deletion and manual entry are not available yet.

## Correcting transactions

Swipe left on a transaction and choose **Edit transaction**, or open its details and tap **Edit transaction**. Change the merchant, date, nonnegative amount, currency, existing account, money direction, type, category or income source, then save. Cancelled edits do not change saved data; unsaved changes require a discard decision.

The app preserves the values before the first correction, along with the original description and import provenance. These original values remain available in transaction details and keep repeat imports from creating duplicates. Corrections update the list, active search results, overview, analytics and recurring-payment hints. Changing a currency corrects the record; it does not perform exchange-rate conversion. If a transaction changed while its editor was open, saving is rejected so it cannot silently overwrite the newer version.

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

Duplicate hints compare transactions within the file and the selected account. Exact matches use dates, trimmed original descriptions, amounts, currencies and directions. Conservative similar matches require the same exact amount, currency and direction, compatible explicit types, and dates within three calendar days. Descriptions are compared without case, accent, punctuation or whitespace differences. Changed descriptions require the same known merchant and strong token overlap; tokens containing numbers must remain identical.

Up to three matches show their original description, date, source and matching reason. Possible duplicates start unchecked. **Skip this transaction** or **Keep both transactions** changes the preview selection; nothing is merged or deleted automatically. These are review hints: distinct payments may share the matching fields. Corrections to the current preview do not recompute duplicate hints; edit the mapping and rebuild the preview to rerun detection.

Known descriptions such as `REWE MARKT`, `AMZN` and `DB VERTRIEB` receive local merchant and category suggestions. Built-in aliases match the start of the description on word boundaries, with more specific aliases taking precedence. Unknown merchants retain their original name. Built-in categories follow the explicit transaction type: income and transfers use their corresponding categories; unknown and adjustment types default to Other. Review suggestions before saving: merchants and categories are editable, and changing the type resets its category suggestion.

Save an optional merchant rule from the preview to reuse a merchant and category for the same transaction type. Rules match full descriptions by default, or an explicitly selected whole-word prefix, ignoring case, punctuation and spacing. User rules run before the built-in catalog; exact matches take priority over prefixes, then the longest prefix wins. Manage rules from **Home → Accounts → Merchant rules**. Saved rules apply when a preview is built again; current corrections and saved transactions remain unchanged.

## PDF statement import

Choose **Import transactions → Choose CSV or PDF file**, select a complete original PDF and choose the destination account. Supported documents use the German Sparkasse layout headed **Datum / Erläuterung / Betrag EUR**, with selectable text, numbered pages, opening/closing balances and a Postanschrift footer. Other layouts, scanned pages and password-protected PDFs are not supported yet.

The parser joins multiline descriptions across pages, preserves booking dates and exact EUR amounts, and verifies that opening balance plus all signed entries equals closing balance. Fee appendices are excluded to avoid importing the same fees twice; zero-value accounting entries remain reviewable adjustments. Missing pages, malformed entries and failed reconciliation block the entire preview. Statement balances validate extraction; they are not saved as account balances.

Card purchases, direct debits and bank fees are suggested as expenses using their bank operation labels. Credits and transfers remain **Unknown** until reviewed; change them to income, refund or transfer as appropriate. Unknown transactions and adjustments are excluded from monthly spending/income summaries. Merchant rules, duplicate hints, editable categories, explicit confirmation and atomic persistence work as in CSV import. Original bank descriptions are preserved; the PDF itself is not stored.

Limits: 10 MiB per PDF, 100 pages, 2 MiB of extracted text and 5,000 entries. Statement row numbers are sequential import references, not physical PDF line numbers. Unsupported formats are rejected rather than guessed.

## Transaction search

Search is local, ignores case and accents, and matches merchant names or original descriptions. Filters apply together: choose all dates, this month, last month or an inclusive custom date range, plus an account, category, transaction type and currency. Results retain their original amounts and currencies.

Search and filters stay in place when switching tabs or refreshing. Reset clears them together; a successful import also clears them so newly imported transactions are visible. Filters are not saved between app launches.

## Spending analytics

Open **Home → Analytics** and browse calendar months, or return to **This month**. Each currency has its own comparison with the previous calendar month and a daily net-spending chart. At accessibility text sizes, expandable daily totals replace the chart to keep every amount readable. Expenses add to spending; refunds reduce it on their recorded date. Current-month data may be incomplete, and missing imports can affect any month.

Tap the selected-month total, a category or a merchant to see the contributing expenses and refunds. Open a transaction to inspect or correct it. These drilldowns preserve the search and filters on the Transactions tab. Calculations use exact Decimal amounts; currencies are never combined or converted.

## Spending assistant

Open **Home → Assistant** to ask about recorded net spending for this month or last month, compare a selected month with its previous month, or choose one saved merchant. Suggested questions work without Apple Intelligence. Free-text interpretation uses Apple's on-device Foundation Models when the device, model and current language are supported.

The model receives only the question and returns a structured query. Swift validates the query, resolves an exact saved merchant and calculates results using the same spending analytics as the rest of the app. Answers show the interpreted scope, calendar month, original currencies, recorded category changes and links to contributing transactions. Expenses minus refunds determine net spending; income, transfers, adjustments and unknown entries are excluded. Results reflect saved data and may be incomplete.

After a successful answer, **And last month?** and **And this month?** keep the same spending query and saved merchant while changing the calendar month. These buttons work without the model. The same short follow-ups can be typed in English, Russian or Ukrainian; other free-text questions still require the model. Context uses the last successful query and resets on Clear, data changes or a calendar-month change. Custom date ranges, account/category/currency filters, exclusions, broader contextual follow-ups, advice and data changes remain outside the supported scope. Unsupported or ambiguous queries require rephrasing or a suggested question. Questions and answers remain in memory while the assistant is open and are discarded when it closes. Answers are cleared when the financial data changes. No remote model, conversation storage or transaction upload is used.

## Regular payments

Open **Home → Analytics → Regular payments** to inspect possible repeating expenses. Detection requires at least three positive expenses with the same saved merchant, exact amount, currency and account. All payments in that group must follow consecutive weekly, monthly or yearly dates, anchored to the first payment. Posting tolerance is one day for weekly patterns and three days for monthly/yearly patterns. Same-day duplicates and irregular groups are omitted.

A possible subscription also requires every matching expense to have the Subscriptions category. These are suggestions, not confirmed contracts. The next date is estimated from the observed pattern; if it passes without a matching saved payment, the pattern is marked as potentially ended, changed or incomplete. Changed prices and missing periods may prevent detection. No data is modified, no reminders are scheduled, and currencies are never combined.

## Budgets

Open **Plan → Budgets** to create or edit a monthly category limit in one currency. A category can have one budget per currency. Limits repeat each calendar month across all accounts; they do not move money or change saved transactions.

Spending uses expenses minus refunds recorded in the current month and category. Transfers, income, adjustments and unknown transactions are excluded. Currencies are never converted or combined. Refunds can make net spending negative and the remaining amount larger than the limit. A negative remaining amount is shown alongside the amount over budget. Budgets are stored locally; edits require explicit saving and conflicting changes are rejected.

## Month-end forecast

Open **Plan → Month-end forecast** for an end-of-day estimate of net spending and net flow, separately for each original currency. Expand **How this is calculated** to see recorded expenses, refunds and income alongside assumed remaining amounts. **Assumptions and limits** explains the method.

Ordinary expenses from the previous calendar month are averaged over its calendar days and applied from tomorrow to month end. Active detected recurring expenses are excluded from that average and scheduled by their original cadence and expected dates, preserving month-end anchors. Already posted payments are counted once; stale patterns are not scheduled. Income is assumed to reach the previous month’s recorded total, or the current recorded total if higher. On the final day, only recorded amounts remain. Refunds are included only when recorded; transfers, adjustments, unknown entries and transactions dated after today are excluded.

The estimate requires expense or income history for that currency in the preceding month. Missing history produces an unavailable forecast rather than a zero estimate. Complete imports, stable habits and unchanged income are assumptions, not verified facts. Irregular income, missing payments and changed prices can make the result inaccurate. This is not an account balance, available money or an affordability assessment. Forecasting does not change saved records or use AI. Estimated ordinary expenses round once to the currency’s standard precision; recorded amounts retain their original precision.

## What-if scenarios

Open **Plan → Month-end forecast → What if?**. Choose one change, its original currency and a positive amount, then tap **Calculate scenario**. Compare baseline and scenario net spending and net flow, alongside the exact change in projected net flow.

A scenario applies one unrecorded change to this month’s forecast. Additional expenses or income increase the corresponding forecast total. Reductions can affect only estimated remaining expenses or assumed remaining income; they cannot erase recorded transactions. Each calculation starts from the baseline, so repeated calculations do not accumulate changes. Refunds retain their recorded treatment and currencies stay separate. A currency needs an available baseline forecast.

Scenarios are temporary: they never change transactions, budgets, goals or account balances. Reset clears the draft and result; closing the forecast discards them. Editing the input clears the old result. When the baseline changes, the result is cleared for recalculation. If its currency is no longer available, the draft amount is also cleared. This is a current-month comparison with the forecast’s existing assumptions; it does not assess affordability or predict goal completion.

## Savings goals

Open **Plan → Savings goals** to create or edit a goal with a name, target amount, original currency, deadline and manually recorded savings. Saving a goal does not move money or change transactions or account balances. Each goal is calculated separately; currencies are never combined.

The remaining target is divided over calendar months including the current month and deadline month. Monthly contributions round upward to the currency's standard precision. A deadline today allows one contribution; a passed deadline with an outstanding target is marked overdue. Savings at or above the target mark the goal completed. This is a contribution schedule, not an assessment of affordability or a forecast of investment returns. Goals are stored locally and drafts require explicit saving.

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

What-if tests cover exact changes, currency boundaries, recorded-amount floors, refunds, invalid input, overflow, independent recalculation, reset and stale-result invalidation. UI journeys exercise scenario calculation, reduction validation, reset, unchanged recorded transactions and accessibility text.

Forecast tests cover recurring-payment double counting, weekly/monthly/yearly dates, month-end anchors, separate accounts and currencies, missing history, future records, refunds, income assumptions, month/year/leap-year boundaries, daylight saving, rounding, overflow and refreshed data. UI journeys cover empty history, calculation details and accessibility text.

Budget tests cover category and currency boundaries, month boundaries, exact amounts, refunds, duplicate limits, migration from schema version 5, reopening storage, cancellation, stale edits, save failures and refreshed transactions. The budget UI journey creates, edits and reopens a budget and rejects a duplicate.

Goal tests cover exact localized input, currency precision, deadline and year boundaries, completion, migration from schema version 4, reopening storage, cancellation, stale edits and save failures. The goals UI journey creates, edits and reopens a saved goal.

Tests cover decimal arithmetic and validation, currency separation, transfers and refunds, date boundaries, demo integrity, persistence and repeated seeding, feature loading/error/cancellation flows, CSV parsing and locale validation, import confirmation, duplicate hints, migration and retry-safe persistence. Analytics tests cover category and merchant totals, month boundaries, refund-only periods, currencies missing from one month, percentage baselines and arithmetic overflow. Recurring-payment tests cover cadence, month ends, posting tolerance, daylight saving, stale patterns, ambiguous history and account/currency separation. Duplicate tests cover normalization, nearby dates, numeric references, semantic/account/currency boundaries, bounded match evidence and cancellation. UI journeys cover the demo, import preview/confirmation, explicit duplicate review, transaction search, analytics and regular payments. UI tests use an isolated in-memory store and a fixed reference date/calendar. GitHub Actions builds and tests pull requests to `develop` and `main` using the Xcode 27 runner image.

## Privacy

The app stores data locally, with no account, bank connection, remote AI service, analytics SDK or custom backend. SwiftData CloudKit integration is disabled. Free-text questions use the on-device language model; financial records are not supplied to it. Future remote processing will require explicit consent and a defined privacy boundary. System iPhone backups remain supported and can include financial data, depending on the user’s backup settings.

## Planned

1. Broader assistant tools and richer contextual follow-ups
2. Longer-term planning and richer goal tracking
3. Broader statement, document and receipt import
4. Investigation of connected banking

These capabilities are not yet implemented.
