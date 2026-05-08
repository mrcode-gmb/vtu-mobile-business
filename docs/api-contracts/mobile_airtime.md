# Mobile Airtime API

Base path:
- `POST /api/mobile/airtime/purchase`
- `GET /api/mobile/airtime/recipients`

Auth:
- Sanctum bearer token

Purchase request:
```json
{
  "network": 1,
  "phone_number": "08031234567",
  "amount": 1000,
  "save_recipient": true,
  "pin": "1234"
}
```

Notes:
- The mobile API delegates to AqtrisPay's existing airtime purchase flow.
- Real transaction authorization still uses the backend `user_pin` record.
- Fingerprint is not used as a server-side purchase credential in this flow.
- Send `Idempotency-Key` for safe retries.

Success response fields used by Flutter:
- `message`
- `reference`
- `recent_recipients`

Recipients response fields used by Flutter:
- `id`
- `phone_number`
- `network`
- `network_name`
- `usage_count`
- `last_used_at`
