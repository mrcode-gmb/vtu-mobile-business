# Modules and Page Reference

Last updated: 2026-03-25

This document is the current reference for the PTS DATA Flutter app modules and every named page route.

## 1. Core App Modules

| Area | Purpose | Main files |
|---|---|---|
| App shell | app bootstrap, theme, route wiring | `lib/app/app.dart`, `lib/app/app_routes.dart` |
| Session/auth core | remembered user, quick unlock timing, token persistence | `lib/core/auth/app_session_service.dart` |
| Biometric auth | device biometric prompt support | `lib/core/auth/biometric_auth_service.dart` |
| Secure PIN storage | stored transaction PIN for biometric payment fallback | `lib/core/auth/secure_transaction_pin_service.dart` |
| App config | API base URL resolution | `lib/core/config/app_config.dart` |
| App settings | theme, fingerprint, quick unlock, notification, and visibility settings | `lib/core/settings/app_settings_service.dart` |
| Export helpers | CSV/web download support | `lib/core/utils/export_download.dart`, `lib/core/utils/export_download_web.dart`, `lib/core/utils/export_download_stub.dart` |
| Shared mobile UI | common page shell, colors, field helpers | `lib/features/shared/presentation/widgets/pts_data_mobile_ui.dart` |
| Shared loader | full-screen processing overlay | `lib/features/shared/presentation/widgets/pts_data_loader_overlay.dart` |
| Bottom navigation | fixed app navigation | `lib/features/navigation/presentation/widgets/app_bottom_navigation.dart` |

## 2. Page Inventory

### Auth

| Route | Page | Purpose | Backend status | Main files |
|---|---|---|---|---|
| `/` | Welcome | entry landing page | Local/native | `lib/features/welcome/presentation/welcome_page.dart` |
| `/login` | Login | full login with email or username | API-backed | `lib/features/auth/presentation/pages/login_page.dart`, `lib/features/auth/data/auth_api_service.dart` |
| `/quick-login` | Quick Login | quick relogin with 4-digit transaction PIN or biometric | Hybrid: local session + backend PIN verify | `lib/features/auth/presentation/pages/quick_login_page.dart`, `lib/features/auth/data/auth_api_service.dart` |
| `/register` | Register | account creation flow | API-backed | `lib/features/auth/presentation/pages/register_page.dart`, `lib/features/auth/data/auth_api_service.dart` |
| `/forgot-password` | Forgot Password | send password reset link | API-backed | `lib/features/auth/presentation/pages/forgot_password_page.dart`, `lib/features/auth/data/auth_api_service.dart` |
| `/reset-password` | Reset Password | submit token, email, and new password | API-backed | `lib/features/auth/presentation/pages/reset_password_page.dart`, `lib/features/auth/data/auth_api_service.dart` |

### Main User and Money Pages

| Route | Page | Purpose | Backend status | Main files |
|---|---|---|---|---|
| `/dashboard` | Dashboard | wallet-first home page | API-backed | `lib/features/dashboard/presentation/pages/dashboard_page.dart`, `lib/features/dashboard/data/dashboard_api_service.dart` |
| `/buy-airtime` | Buy Airtime | airtime purchase flow | API-backed | `lib/features/airtime/presentation/pages/buy_airtime_page.dart`, `lib/features/airtime/data/airtime_api_service.dart` |
| `/buy-data` | Buy Data | data plan purchase flow | API-backed | `lib/features/data/presentation/pages/buy_data_page.dart`, `lib/features/data/data/data_api_service.dart` |
| `/fund-wallet` | Fund Wallet | receiving accounts, manual funding submit, history | API-backed | `lib/features/wallet/presentation/pages/fund_wallet_page.dart`, `lib/features/wallet/data/fund_wallet_api_service.dart` |
| `/transaction-history` | Transaction History | ledger, filters, export | API-backed | `lib/features/transactions/presentation/pages/transaction_history_page.dart`, `lib/features/transactions/data/transaction_history_api_service.dart` |
| `/tv-subscription` | TV Subscription | cable/decoder payment flow | API-backed | `lib/features/tv/presentation/pages/tv_subscription_page.dart`, `lib/features/tv/data/tv_subscription_api_service.dart` |
| `/bill-payment` | Bill Payment | electricity meter payment flow | API-backed | `lib/features/bills/presentation/pages/bill_payment_page.dart`, `lib/features/bills/data/bill_payment_api_service.dart` |
| `/transfer` | Transfer | user-to-user wallet transfer | API-backed | `lib/features/transfer/presentation/pages/transfer_page.dart`, `lib/features/transfer/data/transfer_api_service.dart` |
| `/referrals` | Referrals | referral overview and claim flow | API-backed | `lib/features/referrals/presentation/pages/referrals_page.dart`, `lib/features/referrals/data/referrals_api_service.dart` |
| `/cashback` | Cashback | cashback balance and convert-to-wallet flow | API-backed | `lib/features/cashback/presentation/pages/cashback_page.dart`, `lib/features/cashback/data/cashback_api_service.dart` |
| `/cards` | Cards & E-PIN | recharge cards and ePIN generation | API-backed | `lib/features/cards/presentation/pages/cards_page.dart`, `lib/features/cards/data/cards_api_service.dart` |

### Utility and Discover Pages

| Route | Page | Purpose | Backend status | Main files |
|---|---|---|---|---|
| `/more-services` | More Services | grouped utility/service launcher | Local/native navigation page | `lib/features/more/presentation/pages/more_services_page.dart` |
| `/notifications` | Notifications | user alerts, unread state, and mark-as-read actions | API-backed | `lib/features/notifications/presentation/pages/notifications_page.dart`, `lib/features/notifications/data/notification_api_service.dart` |
| `/support` | Support Center | help channels and request UI | Local/UI-first | `lib/features/support/presentation/pages/support_page.dart` |
| `/news` | News & Updates | system announcements and updates | API-backed | `lib/features/news/presentation/pages/news_page.dart`, `lib/features/news/data/news_api_service.dart` |
| `/virtual-accounts` | Virtual Accounts | real assigned account details and copy actions | API-backed | `lib/features/virtual_accounts/presentation/pages/virtual_accounts_page.dart`, `lib/features/virtual_accounts/data/virtual_accounts_api_service.dart` |

### Profile, Security, and Settings

| Route | Page | Purpose | Backend status | Main files |
|---|---|---|---|---|
| `/me` | Me | profile hub and account launcher | API-backed profile data | `lib/features/me/presentation/pages/me_page.dart`, `lib/features/me/data/profile_api_service.dart` |
| `/settings` | Settings | fingerprint, quick unlock, theme, local preferences | Local/device settings | `lib/features/settings/presentation/pages/settings_page.dart`, `lib/core/settings/app_settings_service.dart` |
| `/personal-information` | Personal Information | edit name, email, phone | API-backed | `lib/features/account/presentation/pages/personal_information_page.dart`, `lib/features/me/data/profile_api_service.dart` |
| `/verification-limits` | Verification & Limits | verification and account status view | API-backed profile read | `lib/features/account/presentation/pages/verification_limits_page.dart`, `lib/features/me/data/profile_api_service.dart` |
| `/change-password` | Change Password | account password update | API-backed | `lib/features/account/presentation/pages/change_password_page.dart`, `lib/features/account/data/account_security_api_service.dart` |
| `/transaction-pin` | Transaction PIN | create, change, or reset transaction PIN | API-backed | `lib/features/account/presentation/pages/transaction_pin_page.dart`, `lib/features/account/data/account_security_api_service.dart` |

## 3. Backend Mobile API Modules

These AqtrisPay backend modules currently support the mobile app:

| Backend area | Main controller |
|---|---|
| Auth | `AqtrisPay/app/Http/Controllers/Api/MobileAuthController.php` |
| Dashboard | `AqtrisPay/app/Http/Controllers/Api/MobileDashboardController.php` |
| Airtime | `AqtrisPay/app/Http/Controllers/Api/MobileAirtimeController.php` |
| Data | `AqtrisPay/app/Http/Controllers/Api/MobileDataController.php` |
| Fund Wallet | `AqtrisPay/app/Http/Controllers/Api/MobileFundWalletController.php` |
| Virtual Accounts | `AqtrisPay/app/Http/Controllers/Api/MobileVirtualAccountsController.php` |
| News | `AqtrisPay/app/Http/Controllers/Api/MobileNewsController.php` |
| Profile | `AqtrisPay/app/Http/Controllers/Api/MobileProfileController.php` |
| Security | `AqtrisPay/app/Http/Controllers/Api/MobileSecurityController.php` |
| Referrals | `AqtrisPay/app/Http/Controllers/Api/MobileReferralController.php` |
| Transfers | `AqtrisPay/app/Http/Controllers/Api/MobileTransferController.php` |
| Cashback | `AqtrisPay/app/Http/Controllers/Api/MobileCashbackController.php` |
| Transaction History | `AqtrisPay/app/Http/Controllers/Api/MobileTransactionHistoryController.php` |
| TV Subscription | `AqtrisPay/app/Http/Controllers/Api/MobileTvSubscriptionController.php` |
| Electricity Bills | `AqtrisPay/app/Http/Controllers/Api/MobileBillPaymentController.php` |
| Cards | `AqtrisPay/app/Http/Controllers/Api/MobileCardsController.php` |
| Notifications | `AqtrisPay/app/Http/Controllers/Api/MobileNotificationsController.php` |

## 4. Modules Still Requiring Backend Completion

These Flutter pages exist, but their backend is still not fully finished:
- Support Center
- Settings sync across devices

## 5. Practical Reading Order for New Contributors

If you need to understand the app quickly, read in this order:
1. `lib/app/app.dart`
2. `lib/app/app_routes.dart`
3. `lib/core/auth/app_session_service.dart`
4. `lib/features/shared/presentation/widgets/pts_data_mobile_ui.dart`
5. `lib/features/dashboard/presentation/pages/dashboard_page.dart`
6. the feature page and API service you want to change next
