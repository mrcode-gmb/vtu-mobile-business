# Mobile Login API

Backend source:
- `/var/www/html/AqtrisPay/routes/api.php`
- `/var/www/html/AqtrisPay/app/Http/Controllers/Api/MobileAuthController.php`
- `/var/www/html/AqtrisPay/app/Services/LoginService.php`
- `/var/www/html/AqtrisPay/app/Http/Requests/Auth/LoginRequest.php`

Endpoint:
- `POST /api/mobile/auth/login`

Headers:
- `Accept: application/json`
- `Content-Type: application/json`
- `X-Airplug-App: 1`

Request body:
```json
{
  "login": "jane@example.com",
  "password": "password123",
  "remember": true
}
```

Notes:
- `login` accepts either email or username.
- Rate limit follows the AqtrisPay web login behavior.
- Suspended or inactive users are blocked with the same validation-style message as web.

Success response:
```json
{
  "message": "Login successful.",
  "token": "sanctum-token",
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "mobile_number": "08012345678",
    "username": "janedoe",
    "referral_username": null,
    "role": "user",
    "status": "active",
    "email_verified_at": null
  },
  "wallet": {
    "balance": 0
  },
  "requires_email_verification": true
}
```

Validation behavior:
- Laravel returns `422` with the standard `errors` object.
- Flutter currently maps:
  - `login -> login`
  - `password -> password`

Architecture note:
- Web and mobile now share login rules through `LoginService`.
- This matches the registration pattern:
  - shared service for business logic
  - thin API controller for JSON response
  - Flutter page consumes the mobile endpoint directly
