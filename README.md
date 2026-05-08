# PTS DATA Flutter App

This repository is the native Flutter mobile client for the PTS DATA product.

The product source of truth is split across:
- Flutter mobile app in `/var/www/html/VtuMobileAppBusiness`
- Laravel backend and legacy web product in `/var/www/html/AqtrisPay`

## Current state

The mobile app is no longer a starter scaffold. It now includes:
- native auth flow
- quick unlock with transaction PIN and biometric option
- user dashboard
- airtime, data, TV, electricity, transfer, cashback, referrals, cards
- fund wallet
- transaction history export
- profile, security, and settings
- notifications, news, and virtual accounts pages

Most money and account pages are already connected to the AqtrisPay mobile API routes under `api/mobile/*`.

## Main docs

- [Current project report](docs/project-report.md)
- [Modules and page reference](docs/module-page-reference.md)
- [Project understanding](docs/project-understanding.md)
- [Flutter migration standard](docs/flutter-migration-standard.md)
- [API contract notes](docs/api-contracts/README.md)

## Current app structure

Top-level Flutter structure:
- `lib/app`
- `lib/core`
- `lib/features`

Important shared areas:
- routing: [app.dart](lib/app/app.dart), [app_routes.dart](lib/app/app_routes.dart)
- session and auth helpers: `lib/core/auth`
- app settings: `lib/core/settings`
- shared UI shell/widgets: `lib/features/shared`

## Current stack actually in use

- Flutter Material `MaterialApp` with named routes
- `http` for API requests
- `shared_preferences` for session and low-risk preferences
- `flutter_secure_storage` for saved transaction PIN used by biometric payment fallback
- `local_auth` for biometric unlock
- `flutter_svg` for selected SVG assets

## Verification

Project verification currently uses:
- `flutter analyze`
- `flutter test`

## Important note

Some older docs were originally written during the discovery phase when the repository was still empty. They have now been updated to match the current implementation state.
