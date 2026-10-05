# Releases

FinAI uses `main` for released source and `develop` for integration. Feature and maintenance pull requests target `develop`. Releases are reviewed pull requests from `develop` to `main`.

## Versioning

- `0.x.0`: a coherent, tested set of capabilities during early development.
- `0.x.y`: corrections to an existing release.
- `1.0.0`: a release ready for dependable everyday use, after privacy, persistence, migration and usability validation.
- Xcode `MARKETING_VERSION` matches the release version. Git tags add a `v` prefix, such as `v0.1.0`.
- `CURRENT_PROJECT_VERSION` is a separate integer build number. Start at 1 and increase it for every distributed app build; do not reset it when changing the release version.
- GitHub source releases do not imply App Store or TestFlight availability.

## Planned scope

These are provisional capability targets, not delivery dates. Split or adjust scope when validation warrants it.

| Version | Target |
| --- | --- |
| 0.1.0 | Local foundation, demo, CSV import, merchant suggestions, search and basic analytics |
| 0.2.0 | Recurring payments and subscriptions, improved import and duplicate review |
| 0.3.0 | Assistant backed by deterministic financial tools |
| 0.4.0 | Goals, budgets, forecasts and what-if planning |
| 0.5.0 | Document, screenshot and receipt import |
| 1.0.0 | Validated everyday-use experience |

The next import scope is a focused text-based PDF statement format before assistant work. Broader scanned-document and receipt extraction remain separate future work. Connected banking requires a separate investigation before release scope is committed.

## Release checklist

1. Finish the selected scope in `develop`; defer unfinished capabilities explicitly.
2. Prepare version metadata and `CHANGELOG.md` on a focused working branch and merge its reviewed pull request into `develop` after CI passes.
3. Confirm tests, UI journeys and a generic iOS Release build. Check persistence/migration implications and ensure sensitive or personal data is absent.
4. Open `develop` → `main`, check the final diff and wait for required CI. Use a merge commit for this release PR to preserve shared ancestry between the long-lived branches.
5. Confirm the merged `main` build passes, then create an annotated `vX.Y.Z` tag at that exact commit and publish GitHub release notes describing only implemented capabilities and known limitations.
6. Synchronize the release merge back into `develop` through a pull request so both branches share the released history. Close the release milestone.

Never move a published release tag or force-push a protected branch. Critical fixes start from the released `main`, pass through a reviewed pull request and patch release, and are propagated back to `develop`.
