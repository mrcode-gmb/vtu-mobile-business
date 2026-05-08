# Mobile Forgot Password API

Backend source:
- `/var/www/html/AqtrisPay/routes/api.php`
- `/var/www/html/AqtrisPay/app/Http/Controllers/Api/MobileAuthController.php`
- `/var/www/html/AqtrisPay/app/Services/PasswordResetLinkService.php`
- `/var/www/html/AqtrisPay/app/Http/Controllers/Auth/PasswordResetLinkController.php`

Endpoint:
- `POST /api/mobile/auth/forgot-password`

Headers:
- `Accept: application/json`
- `Content-Type: application/json`
- `X-Airplug-App: 1`

Request body:
```json
{
  "email": "jane@example.com"
}
```

Success response:
```json
{
  "message": "We have emailed your password reset link."
}
```

Validation behavior:
- Laravel returns `422` with the standard `errors` object.
- Flutter maps:
  - `email -> email`

Current mobile scope:
- The Flutter forgot-password page now sends the reset-link request through the real API.
- The actual password reset still completes through the email link flow from Laravel.
- The native Flutter reset-password page is still not connected to the backend token-reset flow yet.
