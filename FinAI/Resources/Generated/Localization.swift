// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum FinanceStrings {
  /// Account
  internal static let account = FinanceStrings.tr("Localizable", "account", fallback: "Account")
  /// Account kind
  internal static let accountKind = FinanceStrings.tr("Localizable", "accountKind", fallback: "Account kind")
  /// Account name
  internal static let accountName = FinanceStrings.tr("Localizable", "accountName", fallback: "Account name")
  /// Accounts
  internal static let accounts = FinanceStrings.tr("Localizable", "accounts", fallback: "Accounts")
  /// A CSV field is too long.
  internal static let aCsvFieldIsTooLong = FinanceStrings.tr("Localizable", "aCsvFieldIsTooLong", fallback: "A CSV field is too long.")
  /// Add goal
  internal static let addGoal = FinanceStrings.tr("Localizable", "addGoal", fallback: "Add goal")
  /// Add rule
  internal static let addRule = FinanceStrings.tr("Localizable", "addRule", fallback: "Add rule")
  /// Adjustment
  internal static let adjustment = FinanceStrings.tr("Localizable", "adjustment", fallback: "Adjustment")
  /// A file can contain up to 5,000 data rows.
  internal static let aFileCanContainUpTo5000DataRows = FinanceStrings.tr("Localizable", "aFileCanContainUpTo5000DataRows", fallback: "A file can contain up to 5,000 data rows.")
  /// A file can contain up to 64 columns.
  internal static let aFileCanContainUpTo64Columns = FinanceStrings.tr("Localizable", "aFileCanContainUpTo64Columns", fallback: "A file can contain up to 64 columns.")
  /// All accounts
  internal static let allAccounts = FinanceStrings.tr("Localizable", "allAccounts", fallback: "All accounts")
  /// All amounts are money in
  internal static let allAmountsAreMoneyIn = FinanceStrings.tr("Localizable", "allAmountsAreMoneyIn", fallback: "All amounts are money in")
  /// All amounts are money out
  internal static let allAmountsAreMoneyOut = FinanceStrings.tr("Localizable", "allAmountsAreMoneyOut", fallback: "All amounts are money out")
  /// All categories
  internal static let allCategories = FinanceStrings.tr("Localizable", "allCategories", fallback: "All categories")
  /// All currencies
  internal static let allCurrencies = FinanceStrings.tr("Localizable", "allCurrencies", fallback: "All currencies")
  /// All dates
  internal static let allDates = FinanceStrings.tr("Localizable", "allDates", fallback: "All dates")
  /// All types
  internal static let allTypes = FinanceStrings.tr("Localizable", "allTypes", fallback: "All types")
  /// Amount column
  internal static let amountColumn = FinanceStrings.tr("Localizable", "amountColumn", fallback: "Amount column")
  /// Analytics
  internal static let analytics = FinanceStrings.tr("Localizable", "analytics", fallback: "Analytics")
  /// Bank
  internal static let bank = FinanceStrings.tr("Localizable", "bank", fallback: "Bank")
  /// Bonus
  internal static let bonusIncome = FinanceStrings.tr("Localizable", "bonusIncome", fallback: "Bonus")
  /// Cancel
  internal static let cancel = FinanceStrings.tr("Localizable", "cancel", fallback: "Cancel")
  /// Cancel editing
  internal static let cancelEditing = FinanceStrings.tr("Localizable", "cancelEditing", fallback: "Cancel editing")
  /// Cash
  internal static let cash = FinanceStrings.tr("Localizable", "cash", fallback: "Cash")
  /// Category
  internal static let category = FinanceStrings.tr("Localizable", "category", fallback: "Category")
  /// By category · %@
  internal static func categoryBreakdownHeading(_ p1: Any) -> String {
    return FinanceStrings.tr("Localizable", "categoryBreakdownHeading", String(describing: p1), fallback: "By category · %@")
  }
  /// Change in net spending
  internal static let changeInNetSpending = FinanceStrings.tr("Localizable", "changeInNetSpending", fallback: "Change in net spending")
  /// Choose a column
  internal static let chooseAColumn = FinanceStrings.tr("Localizable", "chooseAColumn", fallback: "Choose a column")
  /// Choose a file smaller than 2 MB.
  internal static let chooseAFileSmallerThan2Mb = FinanceStrings.tr("Localizable", "chooseAFileSmallerThan2Mb", fallback: "Choose a file smaller than 2 MB.")
  /// Choose CSV file
  internal static let chooseCsvFile = FinanceStrings.tr("Localizable", "chooseCsvFile", fallback: "Choose CSV file")
  /// Choose different columns for date, amount and description.
  internal static let chooseDifferentColumnsForDateAmountAndDescription = FinanceStrings.tr("Localizable", "chooseDifferentColumnsForDateAmountAndDescription", fallback: "Choose different columns for date, amount and description.")
  /// Choose CSV or PDF file
  internal static let chooseImportFile = FinanceStrings.tr("Localizable", "chooseImportFile", fallback: "Choose CSV or PDF file")
  /// Close
  internal static let close = FinanceStrings.tr("Localizable", "close", fallback: "Close")
  /// Column %lld: %@
  internal static func column(_ p1: Int, _ p2: Any) -> String {
    return FinanceStrings.tr("Localizable", "column", p1, String(describing: p2), fallback: "Column %lld: %@")
  }
  /// Column mapping
  internal static let columnMapping = FinanceStrings.tr("Localizable", "columnMapping", fallback: "Column mapping")
  /// Compact review
  internal static let compactReview = FinanceStrings.tr("Localizable", "compactReview", fallback: "Compact review")
  /// Confirm import
  internal static let confirmImport = FinanceStrings.tr("Localizable", "confirmImport", fallback: "Confirm import")
  /// A rule for this description, match mode and transaction type already exists. Edit that rule instead.
  internal static let conflictingMerchantRuleMessage = FinanceStrings.tr("Localizable", "conflictingMerchantRuleMessage", fallback: "A rule for this description, match mode and transaction type already exists. Edit that rule instead.")
  /// Credit
  internal static let credit = FinanceStrings.tr("Localizable", "credit", fallback: "Credit")
  /// CSV file
  internal static let csvFile = FinanceStrings.tr("Localizable", "csvFile", fallback: "CSV file")
  /// UTF-8 or UTF-16. Comma, semicolon and tab delimiters are detected automatically. Up to 2 MB and 5,000 rows.
  internal static let csvRequirementsExplanation = FinanceStrings.tr("Localizable", "csvRequirementsExplanation", fallback: "UTF-8 or UTF-16. Comma, semicolon and tab delimiters are detected automatically. Up to 2 MB and 5,000 rows.")
  /// Currency
  internal static let currency = FinanceStrings.tr("Localizable", "currency", fallback: "Currency")
  /// Currency column
  internal static let currencyColumn = FinanceStrings.tr("Localizable", "currencyColumn", fallback: "Currency column")
  /// Current month net spending
  internal static let currentMonthNetSpending = FinanceStrings.tr("Localizable", "currentMonthNetSpending", fallback: "Current month net spending")
  /// Custom dates
  internal static let customDates = FinanceStrings.tr("Localizable", "customDates", fallback: "Custom dates")
  /// Net spending is expenses minus refunds. Net flow is income minus net spending. Transfers, adjustments and unknown transactions are excluded. These totals are not account balances.
  internal static let dashboardTotalsExplanation = FinanceStrings.tr("Localizable", "dashboardTotalsExplanation", fallback: "Net spending is expenses minus refunds. Net flow is income minus net spending. Transfers, adjustments and unknown transactions are excluded. These totals are not account balances.")
  /// Data rows: %lld
  internal static func dataRows(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "dataRows", p1, fallback: "Data rows: %lld")
  }
  /// Date
  internal static let date = FinanceStrings.tr("Localizable", "date", fallback: "Date")
  /// Date column
  internal static let dateColumn = FinanceStrings.tr("Localizable", "dateColumn", fallback: "Date column")
  /// Date format
  internal static let dateFormat = FinanceStrings.tr("Localizable", "dateFormat", fallback: "Date format")
  /// Debit
  internal static let debit = FinanceStrings.tr("Localizable", "debit", fallback: "Debit")
  /// Default currency (EUR, USD…)
  internal static let defaultCurrencyEurUsd = FinanceStrings.tr("Localizable", "defaultCurrencyEurUsd", fallback: "Default currency (EUR, USD…)")
  /// Default transaction type
  internal static let defaultTransactionType = FinanceStrings.tr("Localizable", "defaultTransactionType", fallback: "Default transaction type")
  /// Delete merchant rule?
  internal static let deleteMerchantRule = FinanceStrings.tr("Localizable", "deleteMerchantRule", fallback: "Delete merchant rule?")
  /// Delete rule
  internal static let deleteRule = FinanceStrings.tr("Localizable", "deleteRule", fallback: "Delete rule")
  /// Synthetic accounts and transactions will be saved on this device. No bank connection is needed.
  internal static let demoConfirmationMessage = FinanceStrings.tr("Localizable", "demoConfirmationMessage", fallback: "Synthetic accounts and transactions will be saved on this device. No bank connection is needed.")
  /// Demo data · stored on this device
  internal static let demoDataOnDevice = FinanceStrings.tr("Localizable", "demoDataOnDevice", fallback: "Demo data · stored on this device")
  /// Demo data will be replaced only after you confirm this import.
  internal static let demoDataWillBeReplacedOnlyAfterYouConfirmThisImport = FinanceStrings.tr("Localizable", "demoDataWillBeReplacedOnlyAfterYouConfirmThisImport", fallback: "Demo data will be replaced only after you confirm this import.")
  /// Demo data will be replaced. Selected: %lld. Skipped: %lld. Your source file will not be changed.
  internal static func demoImportConfirmationMessage(_ p1: Int, _ p2: Int) -> String {
    return FinanceStrings.tr("Localizable", "demoImportConfirmationMessage", p1, p2, fallback: "Demo data will be replaced. Selected: %lld. Skipped: %lld. Your source file will not be changed.")
  }
  /// Description column
  internal static let descriptionColumn = FinanceStrings.tr("Localizable", "descriptionColumn", fallback: "Description column")
  /// Description starts with
  internal static let descriptionStartsWith = FinanceStrings.tr("Localizable", "descriptionStartsWith", fallback: "Description starts with")
  /// Description to match
  internal static let descriptionToMatch = FinanceStrings.tr("Localizable", "descriptionToMatch", fallback: "Description to match")
  /// Destination account
  internal static let destinationAccount = FinanceStrings.tr("Localizable", "destinationAccount", fallback: "Destination account")
  /// Direction
  internal static let direction = FinanceStrings.tr("Localizable", "direction", fallback: "Direction")
  /// Discard changes
  internal static let discardChanges = FinanceStrings.tr("Localizable", "discardChanges", fallback: "Discard changes")
  /// Discard goal changes?
  internal static let discardGoalChanges = FinanceStrings.tr("Localizable", "discardGoalChanges", fallback: "Discard goal changes?")
  /// Discard changes?
  internal static let discardTransactionChanges = FinanceStrings.tr("Localizable", "discardTransactionChanges", fallback: "Discard changes?")
  /// Done
  internal static let done = FinanceStrings.tr("Localizable", "done", fallback: "Done")
  /// Possible duplicates are unchecked. Up to three matches are shown for review. Keep both only if they are separate transactions. Unknown types are excluded from overview totals.
  internal static let duplicateReviewExplanation = FinanceStrings.tr("Localizable", "duplicateReviewExplanation", fallback: "Possible duplicates are unchecked. Up to three matches are shown for review. Keep both only if they are separate transactions. Unknown types are excluded from overview totals.")
  /// Edit goal
  internal static let editGoal = FinanceStrings.tr("Localizable", "editGoal", fallback: "Edit goal")
  /// Edit account
  internal static let editImportAccount = FinanceStrings.tr("Localizable", "editImportAccount", fallback: "Edit account")
  /// Edit mapping
  internal static let editMapping = FinanceStrings.tr("Localizable", "editMapping", fallback: "Edit mapping")
  /// Edit merchant rule
  internal static let editMerchantRule = FinanceStrings.tr("Localizable", "editMerchantRule", fallback: "Edit merchant rule")
  /// Edit rule
  internal static let editRule = FinanceStrings.tr("Localizable", "editRule", fallback: "Edit rule")
  /// Edit transaction
  internal static let editTransaction = FinanceStrings.tr("Localizable", "editTransaction", fallback: "Edit transaction")
  /// Enter a merchant or payee for each selected transaction.
  internal static let enterAMerchantOrPayeeForEachSelectedTransaction = FinanceStrings.tr("Localizable", "enterAMerchantOrPayeeForEachSelectedTransaction", fallback: "Enter a merchant or payee for each selected transaction.")
  /// Entertainment
  internal static let entertainment = FinanceStrings.tr("Localizable", "entertainment", fallback: "Entertainment")
  /// Excluded
  internal static let excluded = FinanceStrings.tr("Localizable", "excluded", fallback: "Excluded")
  /// Expense
  internal static let expense = FinanceStrings.tr("Localizable", "expense", fallback: "Expense")
  /// Expenses
  internal static let expenses = FinanceStrings.tr("Localizable", "expenses", fallback: "Expenses")
  /// Explore demo
  internal static let exploreDemo = FinanceStrings.tr("Localizable", "exploreDemo", fallback: "Explore demo")
  /// Explore demo data from Overview to get started.
  internal static let exploreDemoDataFromOverviewToGetStarted = FinanceStrings.tr("Localizable", "exploreDemoDataFromOverviewToGetStarted", fallback: "Explore demo data from Overview to get started.")
  /// Explore demo data or import CSV or a supported PDF statement from Overview to get started.
  internal static let exploreDemoDataOrImportACsvFromOverviewToGetStarted = FinanceStrings.tr("Localizable", "exploreDemoDataOrImportACsvFromOverviewToGetStarted", fallback: "Explore demo data or import CSV or a supported PDF statement from Overview to get started.")
  /// Explore with demo data?
  internal static let exploreWithDemoData = FinanceStrings.tr("Localizable", "exploreWithDemoData", fallback: "Explore with demo data?")
  /// Family
  internal static let family = FinanceStrings.tr("Localizable", "family", fallback: "Family")
  /// Filters
  internal static let filters = FinanceStrings.tr("Localizable", "filters", fallback: "Filters")
  /// FinAI
  internal static let finAI = FinanceStrings.tr("Localizable", "finAI", fallback: "FinAI")
  /// First observed
  internal static let firstObserved = FinanceStrings.tr("Localizable", "firstObserved", fallback: "First observed")
  /// First rows
  internal static let firstRows = FinanceStrings.tr("Localizable", "firstRows", fallback: "First rows")
  /// Freelance
  internal static let freelanceIncome = FinanceStrings.tr("Localizable", "freelanceIncome", fallback: "Freelance")
  /// From
  internal static let from = FinanceStrings.tr("Localizable", "from", fallback: "From")
  /// Full description
  internal static let fullDescription = FinanceStrings.tr("Localizable", "fullDescription", fallback: "Full description")
  /// Import CSV or a supported PDF statement using the toolbar, or explore with synthetic demo data.
  internal static let gettingStartedExplanation = FinanceStrings.tr("Localizable", "gettingStartedExplanation", fallback: "Import CSV or a supported PDF statement using the toolbar, or explore with synthetic demo data.")
  /// This goal has changed. Close and reopen goals before editing again.
  internal static let goalChangedFailure = FinanceStrings.tr("Localizable", "goalChangedFailure", fallback: "This goal has changed. Close and reopen goals before editing again.")
  /// Goal completed
  internal static let goalCompleted = FinanceStrings.tr("Localizable", "goalCompleted", fallback: "Goal completed")
  /// Deadline
  internal static let goalDeadline = FinanceStrings.tr("Localizable", "goalDeadline", fallback: "Deadline")
  /// Goal details
  internal static let goalDetails = FinanceStrings.tr("Localizable", "goalDetails", fallback: "Goal details")
  /// Enter a name, positive target, nonnegative savings, valid currency code and date.
  internal static let goalInvalidInput = FinanceStrings.tr("Localizable", "goalInvalidInput", fallback: "Enter a name, positive target, nonnegative savings, valid currency code and date.")
  /// Required per month
  internal static let goalMonthlyContribution = FinanceStrings.tr("Localizable", "goalMonthlyContribution", fallback: "Required per month")
  /// Goal name
  internal static let goalName = FinanceStrings.tr("Localizable", "goalName", fallback: "Goal name")
  /// Deadline passed — revise the date or savings amount.
  internal static let goalOverdue = FinanceStrings.tr("Localizable", "goalOverdue", fallback: "Deadline passed — revise the date or savings amount.")
  /// Record savings manually. Goals do not move money or change account balances. Monthly contributions include the current and deadline months and are rounded up. This schedule does not assess affordability.
  internal static let goalPlanningExplanation = FinanceStrings.tr("Localizable", "goalPlanningExplanation", fallback: "Record savings manually. Goals do not move money or change account balances. Monthly contributions include the current and deadline months and are rounded up. This schedule does not assess affordability.")
  /// Remaining
  internal static let goalRemainingAmount = FinanceStrings.tr("Localizable", "goalRemainingAmount", fallback: "Remaining")
  /// Already saved
  internal static let goalSavedAmount = FinanceStrings.tr("Localizable", "goalSavedAmount", fallback: "Already saved")
  /// Unable to load goals. Try again before editing.
  internal static let goalsLoadFailure = FinanceStrings.tr("Localizable", "goalsLoadFailure", fallback: "Unable to load goals. Try again before editing.")
  /// Unable to save the goal. Your draft is preserved; try again.
  internal static let goalsSaveFailure = FinanceStrings.tr("Localizable", "goalsSaveFailure", fallback: "Unable to save the goal. Your draft is preserved; try again.")
  /// Target amount
  internal static let goalTargetAmount = FinanceStrings.tr("Localizable", "goalTargetAmount", fallback: "Target amount")
  /// Groceries
  internal static let groceries = FinanceStrings.tr("Localizable", "groceries", fallback: "Groceries")
  /// Health
  internal static let health = FinanceStrings.tr("Localizable", "health", fallback: "Health")
  /// Housing
  internal static let housing = FinanceStrings.tr("Localizable", "housing", fallback: "Housing")
  /// Selected: %lld. Skipped: %lld. Your source file will not be changed.
  internal static func importConfirmationMessage(_ p1: Int, _ p2: Int) -> String {
    return FinanceStrings.tr("Localizable", "importConfirmationMessage", p1, p2, fallback: "Selected: %lld. Skipped: %lld. Your source file will not be changed.")
  }
  /// Import CSV
  internal static let importCsv = FinanceStrings.tr("Localizable", "importCsv", fallback: "Import CSV")
  /// The sign controls direction, not the transaction type. Unknown transactions are excluded from overview totals until you choose a type in the preview.
  internal static let importDirectionExplanation = FinanceStrings.tr("Localizable", "importDirectionExplanation", fallback: "The sign controls direction, not the transaction type. Unknown transactions are excluded from overview totals until you choose a type in the preview.")
  /// Imported data
  internal static let importedData = FinanceStrings.tr("Localizable", "importedData", fallback: "Imported data")
  /// Import file
  internal static let importFile = FinanceStrings.tr("Localizable", "importFile", fallback: "Import file")
  /// CSV: UTF-8 or UTF-16 with a header row. PDF: supported German Sparkasse statements with selectable text. Files are processed on this device.
  internal static let importFileRequirementsExplanation = FinanceStrings.tr("Localizable", "importFileRequirementsExplanation", fallback: "CSV: UTF-8 or UTF-16 with a header row. PDF: supported German Sparkasse statements with selectable text. Files are processed on this device.")
  /// Import needs attention
  internal static let importNeedsAttention = FinanceStrings.tr("Localizable", "importNeedsAttention", fallback: "Import needs attention")
  /// Original description and editing
  internal static let importRowDetails = FinanceStrings.tr("Localizable", "importRowDetails", fallback: "Original description and editing")
  /// Import selected
  internal static let importSelected = FinanceStrings.tr("Localizable", "importSelected", fallback: "Import selected")
  /// Import selected transactions?
  internal static let importSelectedTransactions = FinanceStrings.tr("Localizable", "importSelectedTransactions", fallback: "Import selected transactions?")
  /// The import could not be saved. Your previous data is preserved. Try again or reopen the import.
  internal static let importStorageChangedMessage = FinanceStrings.tr("Localizable", "importStorageChangedMessage", fallback: "The import could not be saved. Your previous data is preserved. Try again or reopen the import.")
  /// Import transactions
  internal static let importTransactions = FinanceStrings.tr("Localizable", "importTransactions", fallback: "Import transactions")
  /// Included
  internal static let included = FinanceStrings.tr("Localizable", "included", fallback: "Included")
  /// Income
  internal static let income = FinanceStrings.tr("Localizable", "income", fallback: "Income")
  /// Income source
  internal static let incomeSource = FinanceStrings.tr("Localizable", "incomeSource", fallback: "Income source")
  /// Interest
  internal static let interestIncome = FinanceStrings.tr("Localizable", "interestIncome", fallback: "Interest")
  /// Interpretation
  internal static let interpretation = FinanceStrings.tr("Localizable", "interpretation", fallback: "Interpretation")
  /// Interval
  internal static let interval = FinanceStrings.tr("Localizable", "interval", fallback: "Interval")
  /// Choose an account or enter a new account name of up to 100 characters.
  internal static let invalidImportAccountMessage = FinanceStrings.tr("Localizable", "invalidImportAccountMessage", fallback: "Choose an account or enter a new account name of up to 100 characters.")
  /// The amount does not match the selected number format or exceeds supported precision.
  internal static let invalidImportAmountMessage = FinanceStrings.tr("Localizable", "invalidImportAmountMessage", fallback: "The amount does not match the selected number format or exceeds supported precision.")
  /// The date does not match the selected format or is not a valid calendar date.
  internal static let invalidImportDateMessage = FinanceStrings.tr("Localizable", "invalidImportDateMessage", fallback: "The date does not match the selected format or is not a valid calendar date.")
  /// The type must be expense, income, transfer, refund, adjustment or unknown.
  internal static let invalidImportKindMessage = FinanceStrings.tr("Localizable", "invalidImportKindMessage", fallback: "The type must be expense, income, transfer, refund, adjustment or unknown.")
  /// Enter a description with letters or numbers (up to 500 characters) and a merchant (up to 200 characters).
  internal static let invalidMerchantRuleMessage = FinanceStrings.tr("Localizable", "invalidMerchantRuleMessage", fallback: "Enter a description with letters or numbers (up to 500 characters) and a merchant (up to 200 characters).")
  /// Invalid rows to skip: %lld
  internal static func invalidRowsToSkip(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "invalidRowsToSkip", p1, fallback: "Invalid rows to skip: %lld")
  }
  /// Keep both transactions
  internal static let keepBothTransactions = FinanceStrings.tr("Localizable", "keepBothTransactions", fallback: "Keep both transactions")
  /// Keep editing
  internal static let keepEditing = FinanceStrings.tr("Localizable", "keepEditing", fallback: "Keep editing")
  /// Last month
  internal static let lastMonth = FinanceStrings.tr("Localizable", "lastMonth", fallback: "Last month")
  /// Last observed
  internal static let lastObserved = FinanceStrings.tr("Localizable", "lastObserved", fallback: "Last observed")
  /// Possible duplicates are unchecked. Include them only if they are separate transactions. Unknown types are excluded from overview totals.
  internal static let legacyDuplicateReviewExplanation = FinanceStrings.tr("Localizable", "legacyDuplicateReviewExplanation", fallback: "Possible duplicates are unchecked. Include them only if they are separate transactions. Unknown types are excluded from overview totals.")
  /// Load demo data
  internal static let loadDemoData = FinanceStrings.tr("Localizable", "loadDemoData", fallback: "Load demo data")
  /// Loading local data…
  internal static let loadingLocalData = FinanceStrings.tr("Localizable", "loadingLocalData", fallback: "Loading local data…")
  /// Local data · stored on this device
  internal static let localDataOnDevice = FinanceStrings.tr("Localizable", "localDataOnDevice", fallback: "Local data · stored on this device")
  /// Local data unavailable
  internal static let localDataUnavailable = FinanceStrings.tr("Localizable", "localDataUnavailable", fallback: "Local data unavailable")
  /// This PDF is password protected. Choose an unlocked copy.
  internal static let lockedPdfMessage = FinanceStrings.tr("Localizable", "lockedPdfMessage", fallback: "This PDF is password protected. Choose an unlocked copy.")
  /// The row has invalid CSV formatting or a different number of columns.
  internal static let malformedCSVMessage = FinanceStrings.tr("Localizable", "malformedCSVMessage", fallback: "The row has invalid CSV formatting or a different number of columns.")
  /// The statement could not be read completely. No data was imported. Choose a complete original PDF.
  internal static let malformedStatementMessage = FinanceStrings.tr("Localizable", "malformedStatementMessage", fallback: "The statement could not be read completely. No data was imported. Choose a complete original PDF.")
  /// Match
  internal static let match = FinanceStrings.tr("Localizable", "match", fallback: "Match")
  /// Matches a saved transaction on this account
  internal static let matchesASavedTransactionOnThisAccount = FinanceStrings.tr("Localizable", "matchesASavedTransactionOnThisAccount", fallback: "Matches a saved transaction on this account")
  /// Matches earlier import row %lld
  internal static func matchesEarlierImportRow(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "matchesEarlierImportRow", p1, fallback: "Matches earlier import row %lld")
  }
  /// Matching payments
  internal static let matchingPayments = FinanceStrings.tr("Localizable", "matchingPayments", fallback: "Matching payments")
  /// Matching transactions: %lld
  internal static func matchingTransactions(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "matchingTransactions", p1, fallback: "Matching transactions: %lld")
  }
  /// By merchant · %@
  internal static func merchantBreakdownHeading(_ p1: Any) -> String {
    return FinanceStrings.tr("Localizable", "merchantBreakdownHeading", String(describing: p1), fallback: "By merchant · %@")
  }
  /// Merchant or description
  internal static let merchantOrDescription = FinanceStrings.tr("Localizable", "merchantOrDescription", fallback: "Merchant or description")
  /// Merchant or payee
  internal static let merchantOrPayee = FinanceStrings.tr("Localizable", "merchantOrPayee", fallback: "Merchant or payee")
  /// Matching ignores case, punctuation and spacing, and uses whole words. A short prefix can match many transactions; review every suggestion.
  internal static let merchantRuleMatchingExplanation = FinanceStrings.tr("Localizable", "merchantRuleMatchingExplanation", fallback: "Matching ignores case, punctuation and spacing, and uses whole words. A short prefix can match many transactions; review every suggestion.")
  /// Merchant rules
  internal static let merchantRules = FinanceStrings.tr("Localizable", "merchantRules", fallback: "Merchant rules")
  /// Rules run locally before built-in suggestions. They apply to future previews only. Exact descriptions take priority, then the longest prefix. Transaction types, amounts and currencies stay unchanged.
  internal static let merchantRulesExplanation = FinanceStrings.tr("Localizable", "merchantRulesExplanation", fallback: "Rules run locally before built-in suggestions. They apply to future previews only. Exact descriptions take priority, then the longest prefix. Transaction types, amounts and currencies stay unchanged.")
  /// Known merchants and categories are suggested locally. Review and correct them before saving. Changing the transaction type resets its category suggestion.
  internal static let merchantSuggestionsExplanation = FinanceStrings.tr("Localizable", "merchantSuggestionsExplanation", fallback: "Known merchants and categories are suggested locally. Review and correct them before saving. Changing the transaction type resets its category suggestion.")
  /// Money direction
  internal static let moneyDirection = FinanceStrings.tr("Localizable", "moneyDirection", fallback: "Money direction")
  /// Money in
  internal static let moneyIn = FinanceStrings.tr("Localizable", "moneyIn", fallback: "Money in")
  /// Money out
  internal static let moneyOut = FinanceStrings.tr("Localizable", "moneyOut", fallback: "Money out")
  /// Monthly
  internal static let monthly = FinanceStrings.tr("Localizable", "monthly", fallback: "Monthly")
  /// Current calendar month compared with the full previous month. The current month may be incomplete. Only saved transactions are included; missing activity is treated as zero.
  internal static let monthlyComparisonExplanation = FinanceStrings.tr("Localizable", "monthlyComparisonExplanation", fallback: "Current calendar month compared with the full previous month. The current month may be incomplete. Only saved transactions are included; missing activity is treated as zero.")
  /// Negative out, positive in
  internal static let negativeOutPositiveIn = FinanceStrings.tr("Localizable", "negativeOutPositiveIn", fallback: "Negative out, positive in")
  /// Net flow
  internal static let netFlow = FinanceStrings.tr("Localizable", "netFlow", fallback: "Net flow")
  /// Net spending
  internal static let netSpending = FinanceStrings.tr("Localizable", "netSpending", fallback: "Net spending")
  /// New account
  internal static let newAccount = FinanceStrings.tr("Localizable", "newAccount", fallback: "New account")
  /// New merchant rule
  internal static let newMerchantRule = FinanceStrings.tr("Localizable", "newMerchantRule", fallback: "New merchant rule")
  /// Next date from pattern
  internal static let nextDateFromPattern = FinanceStrings.tr("Localizable", "nextDateFromPattern", fallback: "Next date from pattern")
  /// No accounts yet
  internal static let noAccountsYet = FinanceStrings.tr("Localizable", "noAccountsYet", fallback: "No accounts yet")
  /// No expenses or refunds in these two months.
  internal static let noExpensesOrRefundsInTheseTwoMonths = FinanceStrings.tr("Localizable", "noExpensesOrRefundsInTheseTwoMonths", fallback: "No expenses or refunds in these two months.")
  /// No savings goals yet.
  internal static let noGoalsYet = FinanceStrings.tr("Localizable", "noGoalsYet", fallback: "No savings goals yet.")
  /// No matching transactions
  internal static let noMatchingTransactions = FinanceStrings.tr("Localizable", "noMatchingTransactions", fallback: "No matching transactions")
  /// No merchant rules saved.
  internal static let noMerchantRulesSaved = FinanceStrings.tr("Localizable", "noMerchantRulesSaved", fallback: "No merchant rules saved.")
  /// No regular payment patterns found. More transaction history may be needed.
  internal static let noRecurringPaymentsExplanation = FinanceStrings.tr("Localizable", "noRecurringPaymentsExplanation", fallback: "No regular payment patterns found. More transaction history may be needed.")
  /// No expenses or refunds in %@ this month.
  internal static func noSpendingForCurrencyThisMonth(_ p1: Any) -> String {
    return FinanceStrings.tr("Localizable", "noSpendingForCurrencyThisMonth", String(describing: p1), fallback: "No expenses or refunds in %@ this month.")
  }
  /// No transactions this month.
  internal static let noTransactionsThisMonth = FinanceStrings.tr("Localizable", "noTransactionsThisMonth", fallback: "No transactions this month.")
  /// No transactions yet
  internal static let noTransactionsYet = FinanceStrings.tr("Localizable", "noTransactionsYet", fallback: "No transactions yet")
  /// Number format
  internal static let numberFormat = FinanceStrings.tr("Localizable", "numberFormat", fallback: "Number format")
  /// Optional columns use the default currency and transaction type below. Type values: expense, income, transfer, refund, adjustment, unknown.
  internal static let optionalImportColumnsExplanation = FinanceStrings.tr("Localizable", "optionalImportColumnsExplanation", fallback: "Optional columns use the default currency and transaction type below. Type values: expense, income, transfer, refund, adjustment, unknown.")
  /// Original description
  internal static let originalDescription = FinanceStrings.tr("Localizable", "originalDescription", fallback: "Original description")
  /// Original values
  internal static let originalTransactionValues = FinanceStrings.tr("Localizable", "originalTransactionValues", fallback: "Original values")
  /// Other
  internal static let other = FinanceStrings.tr("Localizable", "other", fallback: "Other")
  /// Overview
  internal static let overview = FinanceStrings.tr("Localizable", "overview", fallback: "Overview")
  /// Choose a PDF smaller than 10 MB with at most 100 pages and 2 MB of extracted text.
  internal static let pdfSizeLimitMessage = FinanceStrings.tr("Localizable", "pdfSizeLimitMessage", fallback: "Choose a PDF smaller than 10 MB with at most 100 pages and 2 MB of extracted text.")
  /// Every PDF page must contain selectable text. Scanned or image-only statements are not supported yet.
  internal static let pdfTextRequiredMessage = FinanceStrings.tr("Localizable", "pdfTextRequiredMessage", fallback: "Every PDF page must contain selectable text. Scanned or image-only statements are not supported yet.")
  /// Percentage change
  internal static let percentageChange = FinanceStrings.tr("Localizable", "percentageChange", fallback: "Percentage change")
  /// Percentage change is unavailable when previous net spending is zero or negative.
  internal static let percentageChangeUnavailableExplanation = FinanceStrings.tr("Localizable", "percentageChangeUnavailableExplanation", fallback: "Percentage change is unavailable when previous net spending is zero or negative.")
  /// Period
  internal static let period = FinanceStrings.tr("Localizable", "period", fallback: "Period")
  /// Possible duplicate
  internal static let possibleDuplicate = FinanceStrings.tr("Localizable", "possibleDuplicate", fallback: "Possible duplicate")
  /// Possible subscription
  internal static let possibleSubscription = FinanceStrings.tr("Localizable", "possibleSubscription", fallback: "Possible subscription")
  /// Preparing import…
  internal static let preparingImport = FinanceStrings.tr("Localizable", "preparingImport", fallback: "Preparing import…")
  /// Preview import
  internal static let previewImport = FinanceStrings.tr("Localizable", "previewImport", fallback: "Preview import")
  /// Previous month
  internal static let previousMonth = FinanceStrings.tr("Localizable", "previousMonth", fallback: "Previous month")
  /// Previous month net spending
  internal static let previousMonthNetSpending = FinanceStrings.tr("Localizable", "previousMonthNetSpending", fallback: "Previous month net spending")
  /// Possible recurring expenses, not confirmed contracts. Matching uses at least three equal payments to the same saved merchant, on one account and in one currency. Weekly dates may vary by one day; monthly and yearly dates by three days.
  internal static let recurringDetectionExplanation = FinanceStrings.tr("Localizable", "recurringDetectionExplanation", fallback: "Possible recurring expenses, not confirmed contracts. Matching uses at least three equal payments to the same saved merchant, on one account and in one currency. Weekly dates may vary by one day; monthly and yearly dates by three days.")
  /// Estimated from saved activity. Future payment dates and amounts are not guaranteed.
  internal static let recurringEstimateExplanation = FinanceStrings.tr("Localizable", "recurringEstimateExplanation", fallback: "Estimated from saved activity. Future payment dates and amounts are not guaranteed.")
  /// Only positive expenses are considered. Transfers, refunds, income and future transactions are excluded. Changed amounts, missing periods and irregular groups may not be detected. The subscription label also requires every matched payment to use the Subscriptions category. Nothing is changed or scheduled automatically.
  internal static let recurringLimitationsExplanation = FinanceStrings.tr("Localizable", "recurringLimitationsExplanation", fallback: "Only positive expenses are considered. Transfers, refunds, income and future transactions are excluded. Changed amounts, missing periods and irregular groups may not be detected. The subscription label also requires every matched payment to use the Subscriptions category. Nothing is changed or scheduled automatically.")
  /// Refresh
  internal static let refresh = FinanceStrings.tr("Localizable", "refresh", fallback: "Refresh")
  /// Refund
  internal static let refund = FinanceStrings.tr("Localizable", "refund", fallback: "Refund")
  /// Refunds
  internal static let refunds = FinanceStrings.tr("Localizable", "refunds", fallback: "Refunds")
  /// Regular payments
  internal static let regularPayments = FinanceStrings.tr("Localizable", "regularPayments", fallback: "Regular payments")
  /// Reimbursement
  internal static let reimbursementIncome = FinanceStrings.tr("Localizable", "reimbursementIncome", fallback: "Reimbursement")
  /// Reset search and filters
  internal static let resetSearchAndFilters = FinanceStrings.tr("Localizable", "resetSearchAndFilters", fallback: "Reset search and filters")
  /// Restaurants
  internal static let restaurants = FinanceStrings.tr("Localizable", "restaurants", fallback: "Restaurants")
  /// Review before saving
  internal static let reviewBeforeSaving = FinanceStrings.tr("Localizable", "reviewBeforeSaving", fallback: "Review before saving")
  /// Review import
  internal static let reviewImport = FinanceStrings.tr("Localizable", "reviewImport", fallback: "Review import")
  /// Row %lld
  internal static func row(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "row", p1, fallback: "Row %lld")
  }
  /// Rows that cannot be imported
  internal static let rowsThatCannotBeImported = FinanceStrings.tr("Localizable", "rowsThatCannotBeImported", fallback: "Rows that cannot be imported")
  /// Rules need attention
  internal static let rulesNeedAttention = FinanceStrings.tr("Localizable", "rulesNeedAttention", fallback: "Rules need attention")
  /// Salary
  internal static let salaryIncome = FinanceStrings.tr("Localizable", "salaryIncome", fallback: "Salary")
  /// Same amount and a similar description within three days
  internal static let sameAmountAndASimilarDescriptionWithinThreeDays = FinanceStrings.tr("Localizable", "sameAmountAndASimilarDescriptionWithinThreeDays", fallback: "Same amount and a similar description within three days")
  /// Same date, amount and original description
  internal static let sameDateAmountAndOriginalDescription = FinanceStrings.tr("Localizable", "sameDateAmountAndOriginalDescription", fallback: "Same date, amount and original description")
  /// Same day and amount with a similar description
  internal static let sameDayAndAmountWithASimilarDescription = FinanceStrings.tr("Localizable", "sameDayAndAmountWithASimilarDescription", fallback: "Same day and amount with a similar description")
  /// Saved goals
  internal static let savedGoals = FinanceStrings.tr("Localizable", "savedGoals", fallback: "Saved goals")
  /// Saved merchant rules
  internal static let savedMerchantRules = FinanceStrings.tr("Localizable", "savedMerchantRules", fallback: "Saved merchant rules")
  /// Saved transactions will stay unchanged.
  internal static let savedTransactionsWillStayUnchanged = FinanceStrings.tr("Localizable", "savedTransactionsWillStayUnchanged", fallback: "Saved transactions will stay unchanged.")
  /// Save goal
  internal static let saveGoal = FinanceStrings.tr("Localizable", "saveGoal", fallback: "Save goal")
  /// Save merchant rule
  internal static let saveMerchantRule = FinanceStrings.tr("Localizable", "saveMerchantRule", fallback: "Save merchant rule")
  /// Save rule
  internal static let saveRule = FinanceStrings.tr("Localizable", "saveRule", fallback: "Save rule")
  /// Save
  internal static let saveTransaction = FinanceStrings.tr("Localizable", "saveTransaction", fallback: "Save")
  /// Savings
  internal static let savings = FinanceStrings.tr("Localizable", "savings", fallback: "Savings")
  /// Savings goals
  internal static let savingsGoals = FinanceStrings.tr("Localizable", "savingsGoals", fallback: "Savings goals")
  /// Saving transaction…
  internal static let savingTransaction = FinanceStrings.tr("Localizable", "savingTransaction", fallback: "Saving transaction…")
  /// Select at least one valid transaction.
  internal static let selectAtLeastOneValidTransaction = FinanceStrings.tr("Localizable", "selectAtLeastOneValidTransaction", fallback: "Select at least one valid transaction.")
  /// Selected transactions: %lld
  internal static func selectedTransactions(_ p1: Int) -> String {
    return FinanceStrings.tr("Localizable", "selectedTransactions", p1, fallback: "Selected transactions: %lld")
  }
  /// Shopping
  internal static let shopping = FinanceStrings.tr("Localizable", "shopping", fallback: "Shopping")
  /// Skip this transaction
  internal static let skipThisTransaction = FinanceStrings.tr("Localizable", "skipThisTransaction", fallback: "Skip this transaction")
  /// Source
  internal static let source = FinanceStrings.tr("Localizable", "source", fallback: "Source")
  /// Breakdowns show the current month, ordered by net spending. Refunds reduce spending in their recorded month and category. Merchant names use saved values. Transfers, income, adjustments and unknown transactions are excluded.
  internal static let spendingBreakdownExplanation = FinanceStrings.tr("Localizable", "spendingBreakdownExplanation", fallback: "Breakdowns show the current month, ordered by net spending. Refunds reduce spending in their recorded month and category. Merchant names use saved values. Transfers, income, adjustments and unknown transactions are excluded.")
  /// Expected date has passed without a matching saved payment. This pattern may have ended, changed, or be missing imported data.
  internal static let staleRecurringPaymentExplanation = FinanceStrings.tr("Localizable", "staleRecurringPaymentExplanation", fallback: "Expected date has passed without a matching saved payment. This pattern may have ended, changed, or be missing imported data.")
  /// The extracted transactions do not reconcile with the statement balances. No data was imported.
  internal static let statementBalanceMismatchMessage = FinanceStrings.tr("Localizable", "statementBalanceMismatchMessage", fallback: "The extracted transactions do not reconcile with the statement balances. No data was imported.")
  /// Statement currency: %@
  internal static func statementCurrency(_ p1: Any) -> String {
    return FinanceStrings.tr("Localizable", "statementCurrency", String(describing: p1), fallback: "Statement currency: %@")
  }
  /// Statement balances were verified before preview. Review all transaction types, especially credits and transfers. Booking dates are used; value dates and fee appendices do not create extra transactions. Nothing is saved until you confirm.
  internal static let statementReviewExplanation = FinanceStrings.tr("Localizable", "statementReviewExplanation", fallback: "Statement balances were verified before preview. Review all transaction types, especially credits and transfers. Booking dates are used; value dates and fee appendices do not create extra transactions. Nothing is saved until you confirm.")
  /// Subscriptions
  internal static let subscriptions = FinanceStrings.tr("Localizable", "subscriptions", fallback: "Subscriptions")
  /// Synthetic demo data
  internal static let syntheticDemoData = FinanceStrings.tr("Localizable", "syntheticDemoData", fallback: "Synthetic demo data")
  /// The description is empty.
  internal static let theDescriptionIsEmpty = FinanceStrings.tr("Localizable", "theDescriptionIsEmpty", fallback: "The description is empty.")
  /// The end date must be on or after the start date.
  internal static let theEndDateMustBeOnOrAfterTheStartDate = FinanceStrings.tr("Localizable", "theEndDateMustBeOnOrAfterTheStartDate", fallback: "The end date must be on or after the start date.")
  /// The file needs a header and at least one data row.
  internal static let theFileNeedsAHeaderAndAtLeastOneDataRow = FinanceStrings.tr("Localizable", "theFileNeedsAHeaderAndAtLeastOneDataRow", fallback: "The file needs a header and at least one data row.")
  /// The transaction type conflicts with the selected money direction.
  internal static let theTransactionTypeConflictsWithTheSelectedMoneyDirection = FinanceStrings.tr("Localizable", "theTransactionTypeConflictsWithTheSelectedMoneyDirection", fallback: "The transaction type conflicts with the selected money direction.")
  /// This month
  internal static let thisMonth = FinanceStrings.tr("Localizable", "thisMonth", fallback: "This month")
  /// This rule no longer exists. Close and reopen merchant rules.
  internal static let thisRuleNoLongerExistsCloseAndReopenMerchantRules = FinanceStrings.tr("Localizable", "thisRuleNoLongerExistsCloseAndReopenMerchantRules", fallback: "This rule no longer exists. Close and reopen merchant rules.")
  /// Through
  internal static let through = FinanceStrings.tr("Localizable", "through", fallback: "Through")
  /// Transaction
  internal static let transaction = FinanceStrings.tr("Localizable", "transaction", fallback: "Transaction")
  /// Amount
  internal static let transactionAmount = FinanceStrings.tr("Localizable", "transactionAmount", fallback: "Amount")
  /// Enter a nonnegative amount. Money in or out is selected separately.
  internal static let transactionAmountExplanation = FinanceStrings.tr("Localizable", "transactionAmountExplanation", fallback: "Enter a nonnegative amount. Money in or out is selected separately.")
  /// Your transaction changes have not been saved.
  internal static let transactionChangesNotSaved = FinanceStrings.tr("Localizable", "transactionChangesNotSaved", fallback: "Your transaction changes have not been saved.")
  /// Transaction details
  internal static let transactionDetails = FinanceStrings.tr("Localizable", "transactionDetails", fallback: "Transaction details")
  /// The selected account is no longer available. Close and reopen this transaction.
  internal static let transactionEditInvalidAccount = FinanceStrings.tr("Localizable", "transactionEditInvalidAccount", fallback: "The selected account is no longer available. Close and reopen this transaction.")
  /// Enter a valid nonnegative amount using your locale’s decimal separator.
  internal static let transactionEditInvalidAmount = FinanceStrings.tr("Localizable", "transactionEditInvalidAmount", fallback: "Enter a valid nonnegative amount using your locale’s decimal separator.")
  /// Enter a supported three-letter currency code, such as EUR or USD.
  internal static let transactionEditInvalidCurrency = FinanceStrings.tr("Localizable", "transactionEditInvalidCurrency", fallback: "Enter a supported three-letter currency code, such as EUR or USD.")
  /// Choose a valid date.
  internal static let transactionEditInvalidDate = FinanceStrings.tr("Localizable", "transactionEditInvalidDate", fallback: "Choose a valid date.")
  /// Expenses require money out. Income and refunds require money in.
  internal static let transactionEditInvalidDirection = FinanceStrings.tr("Localizable", "transactionEditInvalidDirection", fallback: "Expenses require money out. Income and refunds require money in.")
  /// Enter a merchant or payee.
  internal static let transactionEditMissingMerchant = FinanceStrings.tr("Localizable", "transactionEditMissingMerchant", fallback: "Enter a merchant or payee.")
  /// Your changes could not be saved. Try again.
  internal static let transactionEditSaveFailed = FinanceStrings.tr("Localizable", "transactionEditSaveFailed", fallback: "Your changes could not be saved. Try again.")
  /// This transaction changed since you opened it. Your edits are still here. Close and reopen it to review the latest values.
  internal static let transactionEditStorageChanged = FinanceStrings.tr("Localizable", "transactionEditStorageChanged", fallback: "This transaction changed since you opened it. Your edits are still here. Close and reopen it to review the latest values.")
  /// This amount would exceed the supported precision for financial totals.
  internal static let transactionEditUnsupportedTotals = FinanceStrings.tr("Localizable", "transactionEditUnsupportedTotals", fallback: "This amount would exceed the supported precision for financial totals.")
  /// Transaction filters
  internal static let transactionFilters = FinanceStrings.tr("Localizable", "transactionFilters", fallback: "Transaction filters")
  /// Filters apply together. Custom dates include both the first and last day.
  internal static let transactionFiltersExplanation = FinanceStrings.tr("Localizable", "transactionFiltersExplanation", fallback: "Filters apply together. Custom dates include both the first and last day.")
  /// Your original imported values and description are preserved when you save corrections.
  internal static let transactionOriginalPreserved = FinanceStrings.tr("Localizable", "transactionOriginalPreserved", fallback: "Your original imported values and description are preserved when you save corrections.")
  /// Transactions
  internal static let transactions = FinanceStrings.tr("Localizable", "transactions", fallback: "Transactions")
  /// Transactions to review
  internal static let transactionsToReview = FinanceStrings.tr("Localizable", "transactionsToReview", fallback: "Transactions to review")
  /// Transaction type
  internal static let transactionType = FinanceStrings.tr("Localizable", "transactionType", fallback: "Transaction type")
  /// Transfer
  internal static let transfer = FinanceStrings.tr("Localizable", "transfer", fallback: "Transfer")
  /// Transfers
  internal static let transfers = FinanceStrings.tr("Localizable", "transfers", fallback: "Transfers")
  /// Transport
  internal static let transport = FinanceStrings.tr("Localizable", "transport", fallback: "Transport")
  /// Travel
  internal static let travel = FinanceStrings.tr("Localizable", "travel", fallback: "Travel")
  /// Try again
  internal static let tryAgain = FinanceStrings.tr("Localizable", "tryAgain", fallback: "Try again")
  /// Try another search or reset your filters.
  internal static let tryAnotherSearchOrResetYourFilters = FinanceStrings.tr("Localizable", "tryAnotherSearchOrResetYourFilters", fallback: "Try another search or reset your filters.")
  /// Type column
  internal static let typeColumn = FinanceStrings.tr("Localizable", "typeColumn", fallback: "Type column")
  /// Unable to load local data. Your saved data has not been replaced.
  internal static let unableToLoadLocalDataYourSavedDataHasNotBeenReplaced = FinanceStrings.tr("Localizable", "unableToLoadLocalDataYourSavedDataHasNotBeenReplaced", fallback: "Unable to load local data. Your saved data has not been replaced.")
  /// Unable to load merchant rules. Try again before editing.
  internal static let unableToLoadMerchantRulesTryAgainBeforeEditing = FinanceStrings.tr("Localizable", "unableToLoadMerchantRulesTryAgainBeforeEditing", fallback: "Unable to load merchant rules. Try again before editing.")
  /// Unable to save demo data. Please try again.
  internal static let unableToSaveDemoDataPleaseTryAgain = FinanceStrings.tr("Localizable", "unableToSaveDemoDataPleaseTryAgain", fallback: "Unable to save demo data. Please try again.")
  /// Unable to save merchant rules. Please try again.
  internal static let unableToSaveMerchantRulesPleaseTryAgain = FinanceStrings.tr("Localizable", "unableToSaveMerchantRulesPleaseTryAgain", fallback: "Unable to save merchant rules. Please try again.")
  /// Understand your finances
  internal static let understandYourFinances = FinanceStrings.tr("Localizable", "understandYourFinances", fallback: "Understand your finances")
  /// Unknown
  internal static let unknown = FinanceStrings.tr("Localizable", "unknown", fallback: "Unknown")
  /// Unknown merchant
  internal static let unknownMerchant = FinanceStrings.tr("Localizable", "unknownMerchant", fallback: "Unknown merchant")
  /// The file could not be read. Choose it again and check access in Files.
  internal static let unreadableImportFileMessage = FinanceStrings.tr("Localizable", "unreadableImportFileMessage", fallback: "The file could not be read. Choose it again and check access in Files.")
  /// Unspecified
  internal static let unspecifiedIncomeSource = FinanceStrings.tr("Localizable", "unspecifiedIncomeSource", fallback: "Unspecified")
  /// These amounts cannot be combined with your saved data without losing precision. Check the amounts and number format.
  internal static let unsupportedImportTotalsMessage = FinanceStrings.tr("Localizable", "unsupportedImportTotalsMessage", fallback: "These amounts cannot be combined with your saved data without losing precision. Check the amounts and number format.")
  /// This PDF format is not supported. Choose a complete German Sparkasse statement with the Datum / Erläuterung / Betrag EUR table.
  internal static let unsupportedStatementMessage = FinanceStrings.tr("Localizable", "unsupportedStatementMessage", fallback: "This PDF format is not supported. Choose a complete German Sparkasse statement with the Datum / Erläuterung / Betrag EUR table.")
  /// Updating goals…
  internal static let updatingGoals = FinanceStrings.tr("Localizable", "updatingGoals", fallback: "Updating goals…")
  /// Updating rules…
  internal static let updatingRules = FinanceStrings.tr("Localizable", "updatingRules", fallback: "Updating rules…")
  /// Use a supported three-letter currency code, such as EUR or USD.
  internal static let useASupportedThreeLetterCurrencyCodeSuchAsEurOrUsd = FinanceStrings.tr("Localizable", "useASupportedThreeLetterCurrencyCodeSuchAsEurOrUsd", fallback: "Use a supported three-letter currency code, such as EUR or USD.")
  /// Use a UTF-8 or UTF-16 CSV file.
  internal static let useAUtf8OrUtf16CsvFile = FinanceStrings.tr("Localizable", "useAUtf8OrUtf16CsvFile", fallback: "Use a UTF-8 or UTF-16 CSV file.")
  /// Use default
  internal static let useDefault = FinanceStrings.tr("Localizable", "useDefault", fallback: "Use default")
  /// Utilities
  internal static let utilities = FinanceStrings.tr("Localizable", "utilities", fallback: "Utilities")
  /// Weekly
  internal static let weekly = FinanceStrings.tr("Localizable", "weekly", fallback: "Weekly")
  /// Yearly
  internal static let yearly = FinanceStrings.tr("Localizable", "yearly", fallback: "Yearly")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension FinanceStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
