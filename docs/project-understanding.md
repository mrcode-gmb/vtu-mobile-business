# Project Understanding

## 1. What this repository is now

`/var/www/html/VtuMobileAppBusiness` is now an active Flutter mobile application for PTS DATA.

It already contains:
- full app entry and named routing
- light and dark theme support
- session management and quick login logic
- biometric quick unlock support
- user dashboard
- core service pages
- profile and security pages
- API clients for most user flows

This repository is no longer a blank starter project.

## 2. Where the backend and original business logic live

The mobile app still depends on `/var/www/html/AqtrisPay` for backend logic.

That Laravel project currently provides:
- the real database models
- provider integrations
- wallet logic
- referral logic
- transaction PIN verification
- user security flows
- mobile API routes under `api/mobile/*`

The web product in AqtrisPay is also still the best reference for business rules and page intent when a mobile flow needs to be clarified.

## 3. The current architecture split

### Flutter is now the source of truth for
- native mobile navigation
- page layout and component composition
- mobile bottom navigation and utility pages
- quick login interaction
- local settings and stored session behavior
- native biometric handoff

### Laravel is still the source of truth for
- wallet balance and virtual account records
- transaction processing
- airtime/data/TV/bill purchase logic
- transfer logic
- referral and cashback rules
- user profile and security updates
- transaction history data

## 4. Current mobile app scope

The current Flutter app is intentionally user-only.

Included:
- auth
- dashboard
- airtime
- data
- fund wallet
- transfer
- transaction history
- TV subscription
- electricity bill payment
- referrals
- cashback
- cards/ePIN
- profile/security
- settings
- news
- virtual accounts

Explicitly not included as a mobile admin scope:
- admin dashboard
- agent management modules
- admin approval panels

## 5. Current app structure

### App layer
- `lib/app/app.dart`
- `lib/app/app_routes.dart`

### Core layer
- `lib/core/auth`
- `lib/core/config`
- `lib/core/settings`
- `lib/core/utils`

### Feature layer
- one folder per product module under `lib/features`
- each API-backed module generally has `data/`
- each screen lives under `presentation/pages`
- shared mobile widgets live under `features/shared`

## 6. Current navigation model

Main user routes are defined in `lib/app/app_routes.dart`.

Primary routes:
- Welcome
- Login
- Quick Login
- Register
- Forgot Password
- Reset Password
- Dashboard
- Airtime
- Data
- Fund Wallet
- Transaction History
- TV Subscription
- Bill Payment
- Transfer
- Referrals
- Cashback
- Cards
- More Services
- Support
- Settings
- Me
- Personal Information
- Verification & Limits
- Change Password
- Transaction PIN
- Notifications
- News
- Virtual Accounts

## 7. Current backend API reality

The Laravel backend already exposes a broad mobile API set under `api/mobile/*`.

This includes:
- auth
- dashboard
- airtime
- data
- fund wallet
- virtual accounts
- notifications
- news
- profile
- security
- referrals
- transfers
- cashback
- transaction history
- TV
- bills
- cards

So the project is no longer in the earlier “API missing everywhere” phase. The main remaining work is finishing the few local-only mobile features and tightening documentation.

## 8. What is fully native vs still transitional

### Native and API-backed
Most user money and account flows are now native Flutter pages backed by AqtrisPay APIs.

### Native but still local/UI-first
These areas still need real backend completion or richer backend sync:
- Support Center
- some app settings preferences
- reset-password email deep-link handoff into the app

## 9. Important product behaviors already implemented

- direct dashboard access inside the quick session window
- quick re-login after lock using real transaction PIN
- optional biometric unlock after user enables it from Settings
- real wallet balance on dashboard and wallet-related screens
- real virtual accounts from backend
- real user profile data
- real transaction history export

## 10. Known gaps and risks

- Support Center is still mostly UI-first
- Settings are mostly device-local and not yet backend-synced
- reset-password page is API-backed, but email-link-to-app deep linking is still not finished
- some older docs in `docs/api-contracts/` do not yet cover every single implemented feature

## 11. Practical conclusion

This is now a working Flutter mobile application with a substantial backend integration surface, not a prototype shell.

The next work should focus on:
1. finishing the remaining local-only modules
2. tightening documentation coverage
3. polishing any inconsistent UX between older and newer pages
