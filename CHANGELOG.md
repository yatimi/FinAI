# Changelog

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
