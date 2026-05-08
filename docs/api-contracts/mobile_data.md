# Mobile Data API

Base path:

- `GET /api/mobile/data/catalog`
- `GET /api/mobile/data/recipients`
- `POST /api/mobile/data/purchase`

Auth:

- Sanctum bearer token

Notes:

- `catalog` returns the active provider-backed data networks, data types, plans, and recent recipients for the signed-in user.
- `purchase` uses the real AqtrisPay `DataController` purchase flow.
- payment authorization still uses the real backend `user_pin`
- fingerprint in Flutter is only a secure shortcut to reuse the verified transaction PIN after the user enables it in Settings
- send `Idempotency-Key` on purchase requests
