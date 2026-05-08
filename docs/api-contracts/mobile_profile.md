# Mobile Profile API

## Endpoint

- `GET /api/mobile/profile`

## Authentication

- Sanctum bearer token
- Header: `Authorization: Bearer <token>`

## Purpose

Returns the authenticated mobile user's profile details for the native `Me`
page, including identity, wallet summary, cashback summary, verification
status, and transaction PIN status.

## Response shape

```json
{
  "message": "Profile loaded successfully.",
  "data": {
    "name": "Abubakar Bello",
    "email": "abubakar@ptsdata.ng",
    "mobile_number": "08012345678",
    "username": "abubakar",
    "referral_code": "abubakar",
    "referral_username": "",
    "role": "user",
    "role_label": "Standard",
    "account_type": "2",
    "tier_label": "Tier 2",
    "status": "active",
    "status_label": "Active",
    "verification_label": "Verified",
    "pin_status_label": "Enabled",
    "profile_completed": true,
    "is_email_verified": true,
    "has_transaction_pin": true,
    "wallet_balance": 248500,
    "cashback_balance": 12750,
    "joined_at": "2026-02-10T08:30:00.000000Z",
    "joined_label": "Joined Feb 10, 2026"
  }
}
```
