# Changelog

## 0.2.0 — 2026-10-05

Second source release, improving local import review and recurring-payment analysis.

- Inspect possible weekly, monthly and yearly recurring expenses, with payment evidence, estimated next dates, stale-pattern warnings and subscription hints.
- Review exact and conservative similar-transaction duplicate hints with matching evidence and explicit skip or keep-both choices.
- Save local merchant and category rules from import previews, and edit or delete them from Accounts.
- Preserve imported financial fields while applying user rules before built-in merchant suggestions.
- Strengthen persistence regression coverage for migration, reopening, concurrent retries, cancellation and rollback after save failures.
- Use typed localized strings and shared UI resources consistently across the app and UI tests.
- Explain currencies with no current-month expenses or refunds instead of showing empty breakdown sections.

### Scope and limitations

Requires Xcode 27 or later and iOS 26 or later. This is a source release, with no App Store or TestFlight build.

Recurring payments are conservative suggestions based on at least three matching expenses. Missing periods, changed prices or irregular dates may prevent detection; suggestions are not confirmed subscriptions or account balances. Duplicate hints require user review and never merge or delete saved transactions automatically. Merchant rules apply to newly built previews and do not change saved history.

Data stays on the device. Currencies remain separate, and no exchange-rate conversion is performed. General transaction editing/deletion, manual entry, PDF/document import, AI assistance, planning and bank connections remain unimplemented.

## 0.1.0 — 2026-09-28

First source release of FinAI for iOS.

- Explore synthetic transactions across multiple accounts without connecting a bank.
- Import CSV files with column mapping, validation, editable previews and confirmation before saving.
- Review local merchant and category suggestions, with warnings for exact duplicates.
- Keep accounts and transactions on the device, preserving original amounts, currencies and descriptions.
- View monthly income, expenses, refunds and net flow, with currencies kept separate.
- Search transactions and combine date, account, category, type and currency filters.
- Explore spending by category and merchant, and compare net spending with the previous month.

### Scope and limitations

Requires Xcode 27 or later and iOS 26 or later. This release is built from source; it does not include an App Store or TestFlight build. General transaction editing/deletion, manual entry, automatic recurring-payment detection, AI assistance, planning, document extraction and bank connections are not implemented yet.

Analytics uses saved transactions. The current month can be incomplete; refunds reduce spending in their recorded month and category. No exchange-rate conversion is performed.
