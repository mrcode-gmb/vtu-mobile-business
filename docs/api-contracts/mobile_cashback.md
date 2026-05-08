# Mobile Cashback API

## Endpoints

- `GET /api/mobile/cashback`
- `POST /api/mobile/cashback/convert`

## Authentication

- Sanctum bearer token
- Header: `Authorization: Bearer <token>`

## Purpose

Supports the native cashback page in Flutter:
- fetch cashback wallet balances and recent activity
- convert cashback into the main wallet

## Fetch response

```json
{
  "message": "Cashback loaded successfully.",
  "data": {
    "balance": 12750,
    "total_earned": 38100,
    "total_converted": 25350,
    "wallet_balance": 248500,
    "recent_transactions": [
      {
        "id": 1,
        "type": "earned",
        "amount": 10,
        "description": "MTN 10GB direct gifting",
        "transaction_type": "data",
        "reference": "CBK-001",
        "created_at": "2026-03-24T09:10:00.000000Z",
        "balance_before": 12740,
        "balance_after": 12750
      }
    ]
  }
}
```

## Convert request

```json
{
  "amount": 1000,
  "pin": "1234"
}
```

## Convert notes

- amount must be greater than `0`
- conversion checks the user's real `user_pin` record
- conversion moves funds from `cashback_wallets` into `wallets`
- conversion writes a cashback transaction record with a mobile reference
