# Mobile TV Subscription API

Base URL:
- local web/iOS/desktop: `http://127.0.0.1:8000/api`
- Android emulator: `http://10.0.2.2:8000/api`

Auth:
- Sanctum bearer token
- header: `Authorization: Bearer <token>`

Endpoints:

## `GET /mobile/tv/catalog`
Returns:
- `service_charge`
- `providers`
- recent TV subscription `history`

Provider fields:
- `id`
- `name`
- `service_id`
- `meter_types`
- `image`

## `GET /mobile/tv/plans?service_id=dstv`
Returns:
- `plans`

Plan fields:
- `id`
- `variation_code`
- `name`
- `amount`

## `POST /mobile/tv/validate`
Payload:
```json
{
  "service_id": "dstv",
  "smart_card_number": "4508123490",
  "meter_type": "prepaid"
}
```

Success fields:
- `customer_name`
- `message`

## `POST /mobile/tv/purchase`
Payload:
```json
{
  "service_id": "dstv",
  "smart_card_number": "4508123490",
  "meter_type": "prepaid",
  "amount": 15700,
  "phone": "08031234567",
  "pin": "1234",
  "variation_code": "compact",
  "plan_name": "Compact"
}
```

Success fields:
- `message`
- `reference`
- `provider_token`
- `history_item`

Notes:
- purchase uses the real AqtrisPay `user_pin` table
- wallet balance is debited only after provider success
- TV history is stored in `tv_subscriptions`
