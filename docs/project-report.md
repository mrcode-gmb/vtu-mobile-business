# PTS DATA Project Report

Last updated: 2026-03-25

## 1. Executive Summary

The PTS DATA mobile app is now a substantial native Flutter application backed by the AqtrisPay Laravel mobile API.

Current implementation state:
- native Flutter user app is active
- most user money flows are API-backed
- quick login and biometric unlock are implemented
- dashboard and wallet-related pages show real backend data
- missing work is now concentrated in a smaller set of local-only or partially integrated modules

## 2. Repository Roles

### Flutter app
Repository:
- `/var/www/html/VtuMobileAppBusiness`

Responsibilities:
- native mobile UI
- mobile navigation
- quick unlock UX
- local app settings
- biometric interaction
- page composition and mobile experience

### Laravel backend
Repository:
- `/var/www/html/AqtrisPay`

Responsibilities:
- database access
- provider integrations
- wallet transactions
- transaction PIN validation
- referrals and cashback rules
- transaction history
- mobile API routes

## 3. Current Architecture

### Flutter
- app entry and named routes in `lib/app`
- cross-feature helpers in `lib/core`
- feature-first modules in `lib/features`
- API services generally live in `data/`
- pages live in `presentation/pages`

### Backend
- mobile API controllers in `AqtrisPay/app/Http/Controllers/Api`
- business logic concentrated in `AqtrisPay/app/Services`
- mobile API routes under `AqtrisPay/routes/api.php`

## 4. Current Route Coverage

### Flutter app routes
The Flutter app currently defines 30 named routes, including:
- auth pages
- dashboard
- all major service pages
- profile/security pages
- news
- virtual accounts

Main route file:
- `/var/www/html/VtuMobileAppBusiness/lib/app/app_routes.dart`

### Mobile backend routes
The AqtrisPay backend currently exposes 48 mobile API routes under `api/mobile/*`.

This already covers:
- auth
- dashboard
- airtime
- data
- fund wallet
- virtual accounts
- news
- profile
- security
- referrals
- transfer
- cashback
- transaction history
- TV
- bills
- cards

## 5. Module Status

### Native and API-backed
- Auth
- Quick Login
- Dashboard
- Buy Airtime
- Buy Data
- Fund Wallet
- Transfer
- Transaction History
- TV Subscription
- Bill Payment
- Referrals
- Cashback
- Cards & E-PIN
- Profile
- Personal Information
- Change Password
- Transaction PIN
- Verification & Limits
- Notifications
- News
- Virtual Accounts

### Native but mostly local or UI-first
- Welcome
- More Services
- Settings
- Support Center

## 6. Important Behaviors Confirmed

- login and registration persist a mobile session
- after the direct session window, quick unlock uses the real backend transaction PIN
- biometric unlock is opt-in from settings
- enabling biometric requires transaction PIN verification first
- dashboard wallet balance is real
- wallet-related pages use real wallet/account data
- virtual account details come from the backend
- notifications load and mark read through the mobile API
- transaction history export works
- password reset is API-backed and the shared backend reset service is fixed

## 7. Remaining Gaps

Main remaining functional gaps:
- Support Center ticket API
- backend-synced settings/preferences
- full email-link deep linking into the native reset-password page

Documentation gaps still remaining:
- not every implemented feature has its own dedicated `docs/api-contracts/<feature>.md`
- the new overview docs now cover the full app, but some per-feature contract notes still need to be added later

## 8. Risks

- some older pages were built earlier and still need occasional visual consistency passes
- local-only modules may feel complete in UI before backend work is actually done
- password reset works via API, but the app handoff from reset email is still not fully native/deep-linked

## 9. Verification Baseline

Latest confirmed project checks:
- `flutter analyze`
- `flutter test`
- `php /var/www/html/AqtrisPay/artisan route:list --path=api/mobile`

## 10. Recommended Next Steps

Priority next steps:
1. Finish Support Center backend integration
2. Add backend sync for user settings where needed
3. Implement email deep linking for native password reset
4. Backfill missing dedicated API contract docs for the remaining API-backed features

## 11. Source-of-Truth Files

Important Flutter source-of-truth files:
- `/var/www/html/VtuMobileAppBusiness/lib/app/app.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/app/app_routes.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/core/auth/app_session_service.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/core/settings/app_settings_service.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/features/shared/presentation/widgets/pts_data_mobile_ui.dart`

Important backend source-of-truth files:
- `/var/www/html/AqtrisPay/routes/api.php`
- `/var/www/html/AqtrisPay/app/Http/Controllers/Api`
- `/var/www/html/AqtrisPay/app/Services`

## 12. Companion Reference

For a page-by-page and module-by-module breakdown, see:
- [Modules and page reference](module-page-reference.md)
