# Mobile Registration API

Backend source:
- `/var/www/html/AqtrisPay/routes/api.php`
- `/var/www/html/AqtrisPay/app/Http/Controllers/Api/MobileAuthController.php`
- `/var/www/html/AqtrisPay/app/Services/RegistrationService.php`

Endpoint:
- `POST /api/mobile/auth/register`

Headers:
- `Accept: application/json`
- `Content-Type: application/json`
- `X-Airplug-App: 1`

Request body:
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "mobile_number": "08012345678",
  "username": "janedoe",
  "password": "password123",
  "password_confirmation": "password123",
  "r_username": "ABUBAKAR"
}
```

Success response:
```json
{
  "message": "Account created successfully.",
  "token": "sanctum-token",
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "mobile_number": "08012345678",
    "username": "janedoe",
    "referral_username": "ABUBAKAR",
    "role": "user",
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
- Flutter maps these keys into the step form UI:
  - `mobile_number -> mobile`
  - `password_confirmation -> confirm`
  - `r_username -> r_username`

Notes:
- Web and mobile now share the same backend registration business logic through `RegistrationService`.
- This is preferred over putting all mobile endpoints into one large `MobileApplicationController`.
- Future mobile auth endpoints should follow the same pattern:
  - thin API controller
  - shared service/action
  - JSON response for mobile
