# Standards referenced

Per ESP902 5.2.B13, this lists the standards this project's quality process
and code are held to. Kept deliberately short — a small set actually applied
and explainable, not an exhaustive list.

## Code style — Effective Dart / `flutter_lints`

Code follows the official [Effective Dart](https://dart.dev/effective-dart)
style guide, enforced via `package:flutter_lints` (already configured in
[analysis_options.yaml](../analysis_options.yaml)). `flutter analyze` is the
automated check for this standard, run locally and in CI.

## Architecture — feature-based layering

The app is organized as `lib/features/<feature>/{data,domain,presentation}`:

- **domain** — entities and repository interfaces, framework-independent.
- **data** — repository implementations, talking to `ApiService`/HTTP.
- **presentation** — `ChangeNotifier` providers and screens/widgets.

This is a lightweight application of the dependency-inversion idea behind
Clean Architecture (Robert C. Martin): presentation depends on domain
interfaces, not on concrete data implementations, which is exactly what
makes the providers unit-testable with `mocktail` (see
[QUALITY_ASSESSMENT.md](QUALITY_ASSESSMENT.md)).

## Quality characteristics — ISO/IEC 25010

The [Definition of Done](QUALITY_ASSESSMENT.md#definition-of-done--merge-gate)
maps to ISO/IEC 25010 product quality characteristics:

| Characteristic | How it's addressed here |
|---|---|
| Functional suitability | Unit + functional test pyramid |
| Reliability | Repository/controller error paths are explicitly tested (network failure, invalid payload, HTTP error status) |
| Maintainability | Layering above + lint-enforced style + tests as executable documentation of behavior |
| Security | See OWASP callout below |

## Security — OWASP Mobile Top 10 (informal reference)

Two practices already in the codebase are worth calling out against
[OWASP's Mobile Top 10](https://owasp.org/www-project-mobile-top-10/):

- **M9 (Insecure Data Storage)** — the auth token is stored with
  `flutter_secure_storage` (platform keychain/keystore), never in
  `shared_preferences` or plain state.
- **M10 (Insufficient Cryptography) / logging hygiene** — `ApiService`
  redacts sensitive fields (`password`, `token`, `authorization`, etc.)
  before logging any request/response body (`ApiService._redact`), so debug
  logs never leak credentials.

This is not a full security audit — it documents the standard the existing
practices are measured against, per the ESP902 requirement to reference one.
