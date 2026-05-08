# Flutter Migration Standard

## 1. Purpose

This document defines the current working standard for extending the PTS DATA Flutter app so another engineer or AI agent can continue without re-discovering the project.

This is not a theoretical future stack document. It reflects the stack already in use.

## 2. Source-of-truth rule

Use AqtrisPay as the source of truth for:
- business rules
- provider integrations
- wallet and transaction behavior
- validation rules
- transaction PIN verification
- backend response shapes

Use Flutter as the source of truth for:
- mobile UX
- app routing
- local settings behavior
- biometric interaction
- native layout decisions
- page composition

## 3. Current stack in use

The current project uses:
- `MaterialApp` with `onGenerateRoute`
- feature-local API services built on `http`
- `shared_preferences` for session and low-risk preferences
- `flutter_secure_storage` for stored transaction PIN used with biometric payment fallback
- `local_auth` for device biometrics
- `flutter_svg` for supported SVG assets

Do not introduce a second routing, networking, or persistence pattern casually.

If the app is migrated later to `go_router`, `dio`, or another state layer, that should be a deliberate refactor, not a mixed incremental drift.

## 4. Folder structure standard

The repository follows a feature-first structure:

```text
lib/
  app/
  core/
  features/
    <feature>/
      data/
      presentation/
```

Current rules:
- put API clients in `data/`
- put pages in `presentation/pages`
- put reusable feature widgets in `presentation/widgets`
- keep app-wide helpers in `core/`
- keep shared mobile widgets in `features/shared`

## 5. Routing standard

Routes are centrally defined in:
- `lib/app/app_routes.dart`
- `lib/app/app.dart`

Rules:
- every new page gets a stable named route
- navigation should go through those route constants
- do not scatter hardcoded route strings across widgets

## 6. API client standard

Each API-backed feature should have a dedicated service file.

Examples:
- `auth_api_service.dart`
- `dashboard_api_service.dart`
- `airtime_api_service.dart`
- `fund_wallet_api_service.dart`

Rules:
- return typed result classes, not raw maps
- handle `401` as an explicit session-expired path
- keep feature parsing logic inside the service
- provide debug handlers for widget tests when practical

## 7. Auth and session standard

Current session behavior is handled in:
- `lib/core/auth/app_session_service.dart`
- `lib/core/auth/biometric_auth_service.dart`
- `lib/core/auth/secure_transaction_pin_service.dart`

Rules:
- full login stores remembered user and API token
- direct dashboard access is allowed inside the short unlock window
- after that, quick unlock can use transaction PIN or biometric when enabled
- biometric must be enabled from settings first
- transaction PIN remains the real backend PIN from AqtrisPay

## 8. UI standard

The current design system is based on:
- full-screen mobile layouts
- wallet-first dashboard structure
- fixed bottom navigation
- bottom-sheet confirmation, PIN, and result flows
- compact card surfaces and smaller mobile typography

Shared UI helpers currently live in:
- `lib/features/shared/presentation/widgets/pts_data_mobile_ui.dart`
- `lib/features/navigation/presentation/widgets/app_bottom_navigation.dart`
- `lib/features/shared/presentation/widgets/pts_data_loader_overlay.dart`

Rules:
- keep pages mobile-first
- avoid desktop wrappers
- avoid mixed old and new drawer/result styles
- prefer consistent bottom-drawer confirmation flows across money actions

## 9. Theme standard

Theme is centralized in `lib/app/app.dart`.

Rules:
- do not hardcode unrelated random colors in new pages
- prefer shared PTS DATA lavender/periwinkle tokens
- keep light and dark mode supported
- use native platform typography behavior already configured in the app theme

## 10. Testing standard

The main verification baseline is:
- `flutter analyze`
- `flutter test`

Widget tests already use feature debug handlers to avoid real network calls.

Rules:
- when adding a new API-backed page, add or extend debug handlers
- keep tests aligned with real route names and page labels

## 11. Documentation standard

When a meaningful feature is added or changed, update at least one of:
- `docs/project-report.md`
- `docs/module-page-reference.md`
- `docs/api-contracts/<feature>.md`

If a doc is outdated, update it in the same change rather than leaving contradictory guidance in the repository.

## 12. Current “done” standard for a feature

A feature is treated as done when:
- it has a native Flutter page
- routing is wired
- loading and error states exist
- unauthorized flow is handled
- the backend API shape is understood or documented
- tests and analyze still pass

## 13. Current known exceptions

These areas are still not fully backend-complete:
- Support Center
- backend-synced settings
- password reset deep-link handoff from email into the app

These should be treated as active follow-up work, not forgotten edge cases.
