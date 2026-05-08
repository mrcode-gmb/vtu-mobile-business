# Auth UI Contract

## Current Flutter scope

These authentication pages are now designed natively in Flutter:
- welcome to login
- welcome to register
- forgot password
- reset password

Flutter files:
- `/var/www/html/VtuMobileAppBusiness/lib/features/auth/presentation/pages/login_page.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/features/auth/presentation/pages/register_page.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/features/auth/presentation/pages/forgot_password_page.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/features/auth/presentation/pages/reset_password_page.dart`
- `/var/www/html/VtuMobileAppBusiness/lib/features/auth/presentation/widgets/auth_screen_shell.dart`

## Laravel UI references

- `/var/www/html/AqtrisPay/resources/js/Pages/Auth/Login.tsx`
- `/var/www/html/AqtrisPay/resources/js/Pages/Auth/Register.tsx`
- `/var/www/html/AqtrisPay/resources/js/Pages/Auth/ForgotPassword.tsx`
- `/var/www/html/AqtrisPay/resources/js/Pages/Auth/ResetPassword.tsx`
- `/var/www/html/AqtrisPay/resources/js/Components/AuthLayoutShell.tsx`

## UI concept carried over

- centered branded hero
- theme toggle in the top-right area
- rounded slate form inputs
- lavender-to-periwinkle gradient primary button
- compact footer links
- mobile-first single-column layout

## Backend status

Backend auth API integration is not connected yet in Flutter.

Current Flutter auth pages are UI-first implementations only:
- local field state
- local validation
- placeholder submit feedback

## Known gaps

- no real login API call yet
- no real signup API call yet
- no real forgot-password email request yet
- no token-based reset flow yet
- Google auth UI is not implemented yet
