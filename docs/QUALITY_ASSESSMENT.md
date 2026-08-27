# Quality assessment process

This document defines corevia_mobile's quality acceptance process: how a
change gets validated before it is considered "done". It covers the ESP902
rattrapage deliverables 3.4.B08 (unit test coverage), 3.4.B09 (functional
test sequence) and 3.1.B04 (this process itself). The standards referenced
throughout are detailed in [STANDARDS.md](STANDARDS.md).

## Test pyramid

| Layer | What it covers | How | Where |
|---|---|---|---|
| Unit — domain | Entities/models: `fromJson`/`toJson`, validation rules (`RegisterModel`), pure helpers (`route_persistence.dart`, `validators.dart`) | Plain `flutter_test`, no mocking | `test/features/**/domain/`, `test/core/` |
| Unit — data | `*RepositoryImpl` classes, `LoginController`/`RegisterController` | `http.MockClient` via the `ApiService` test seam (see below) | `test/features/**/data/`, `test/features/auth/presentation/controllers/` |
| Unit — presentation | `ChangeNotifier` providers (`BookingProvider`, `PillboxProvider`, `MedicationSearchProvider`, `UserProvider`, `HomeProvider`) | `mocktail`, mocking the repository interface each provider depends on | `test/features/**/presentation/providers/` |
| Functional | 4 key user journeys through the real widget tree (screens + providers + `go_router`), against a scripted fake data layer | `integration_test` package | `integration_test/` |

As of this document, the suite has 151 unit tests and 4 functional journeys,
all green.

## The ApiService test seam

`ApiService` (`lib/networking/api_service.dart`) is a static class that owns
the app's single `http.Client`. Every `*RepositoryImpl` and both auth
controllers call it directly rather than receiving an injected HTTP client —
that's the existing pattern across the app.

To reach real unit coverage on that layer without a broader dependency-
injection rewrite (out of scope for an individual, time-boxed rattrapage),
`ApiService` exposes two `@visibleForTesting` methods:

```dart
ApiService.debugOverrideClient(client); // swap in an http.MockClient
ApiService.debugResetClient();          // restore the real client
```

Tests stub HTTP responses per route with `http.MockClient` (from the `http`
package — already a dependency, no new production code path). This is a
deliberate, minimal seam: it changes nothing about production behavior (the
client still defaults to the real one) and keeps every repository/controller
test readable and explainable on its own.

## Functional test sequence

Four journeys in `integration_test/`, each driving the actual `MyApp` /
`createRouter` widget tree wired to hand-written fake repositories
(`integration_test/support/fakes.dart`) instead of the network:

1. `onboarding_flow_test.dart` — fresh install shows onboarding; finishing it
   redirects to `/login`.
2. `session_restoration_test.dart` — an authenticated session with a
   persisted last route reopens directly on that route (`route_persistence.dart`
   + the router's redirect logic).
3. `booking_flow_test.dart` — pick an available slot, confirm, land on the
   booking confirmation screen with the right doctor/date/time.
4. `pillbox_flow_test.dart` — mark today's pending intake as taken; the
   intake card updates to "Pris".

Run one at a time (see below) — running the whole `integration_test/`
directory in one invocation trips a Windows-desktop test-runner limitation
in this environment (only the first app instance's debug connection
attaches); each file passes cleanly on its own, which is what CI and manual
verification actually check.

## Definition of Done / merge gate

Before a change is considered done:

1. `flutter analyze` is clean (no new warnings; pre-existing info-level
   lints in untouched files are tracked separately, not a blocker).
2. `flutter test` (all unit tests) is green.
3. New logic in `domain`, `data`, or a provider ships with tests in the same
   change — see the test pyramid above for where each kind belongs.
4. If the change touches a screen/flow covered by a functional journey, that
   journey is re-run locally before merging.
5. Manual smoke check: run the app (`flutter run -d windows` or an
   emulator) and exercise the golden path once — sign-in redirect, home
   screen loads, and the touched feature.

## How to run everything

```bash
flutter pub get
flutter analyze
flutter test                       # 151 unit tests
flutter test --coverage            # writes coverage/lcov.info

# functional journeys — one file at a time
flutter test integration_test/onboarding_flow_test.dart -d windows
flutter test integration_test/session_restoration_test.dart -d windows
flutter test integration_test/booking_flow_test.dart -d windows
flutter test integration_test/pillbox_flow_test.dart -d windows
```

## Continuous integration

`.github/workflows/flutter_analyze.yml` runs `flutter analyze` on every pull
request. A second job, `Flutter_Test`, runs `flutter test` (the unit suite)
on the same trigger — this is the automated half of the gate above.
Functional journeys need a device/emulator, so they stay a required manual
step before merging a change to a covered flow, documented above rather than
run in CI.
