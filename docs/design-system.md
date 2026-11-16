# UI foundations

FinAI uses semantic colors from the asset catalog, system fonts with Dynamic Type,
and a small set of presentation-only SwiftUI components. `FinanceStyle` defines
spacing, typography and semantic roles. Screens own their actions and TCA owns
loading, errors, cancellation and presentation.

## Resources

Install SwiftGen 6.6.3 and use the configured Xcode toolchain, then run:

```sh
sh Scripts/generate-resources.sh
```

Run `sh Scripts/generate-resources.sh --check` to detect stale generated files
without changing them.

Commit both the source resources and regenerated Swift files. Regular builds use
these checked-in files and do not require SwiftGen. The script compiles the
English String Catalog into temporary `.strings`/`.stringsdict` files with
`xcstringstool`, then generates typed string accessors with SwiftGen. Temporary
files are removed; the `.xcstrings` catalog remains the translation source.
Existing Xcode-generated `LocalizedStringResource` access remains available for
SwiftUI and typed interpolation. Never pass an already localized String back as
a localization key. SwiftGen's generated formatted functions use the caller's
locale; financial formatting remains owned by MoneyText and domain types.

The color template generates computed SwiftUI Color properties, avoiding mutable
cached asset wrappers under Swift 6 concurrency checks. Colors resolve in the app
bundle and retain Light/Dark variants.

## Component behavior

- Action buttons retain a readable label during loading and reject repeat taps.
- Empty states explain the absence and optionally provide a relevant action.
- Loading states use native ProgressView and localized labels.
- Error states expose a retry action; refreshing content should remain visible.
- Cards define presentation only, with no finance calculations or persistence.

Use the component gallery previews for Light/Dark and accessibility text sizes.
Keep action labels multiline, tap targets at least 44 points, and error meaning
available in text rather than color alone. Prefer native sheets and controls.
