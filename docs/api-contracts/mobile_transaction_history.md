# Mobile Transaction History API

## Endpoints

- `GET /api/mobile/transaction-history`
- `GET /api/mobile/transaction-history/export`

Both endpoints require:

- Sanctum bearer token
- header `Accept: application/json` for fetch
- header `Accept: text/csv,application/json` for export

## Query Parameters

- `page`: page number, default `1`
- `per_page`: optional, default `20`, max `50`
- `type`: `all`, `airtime`, `data`, `funding`, `transfer`, `electricity`, `cable`, `card_generation`
- `status`: `all`, `success`, `pending`, `failed`
- `date_range`: `all`, `today`, `week`, `month`, `quarter`
- `search`: free text search across description, recipient, reference, network, plan, and amount
- `format`: export only, currently supports `csv`

## Fetch Response

```json
{
  "message": "Transactions loaded successfully.",
  "transactions": {
    "data": [
      {
        "id": "TRANS-20",
        "type": "transfer",
        "amount": 5000,
        "status": "success",
        "direction": "outgoing",
        "date": "2026-03-14T08:12:00.000000Z",
        "description": "Transfer to abubakar",
        "recipient": "abubakar",
        "reference": "TRF-001"
      }
    ],
    "current_page": 1,
    "per_page": 20,
    "total": 2,
    "last_page": 1
  }
}
```

## Export Response

- success returns streamed CSV download
- unsupported formats currently return `422`

## Flutter Usage

Flutter uses:

- [transaction_history_api_service.dart](/var/www/html/VtuMobileAppBusiness/lib/features/transactions/data/transaction_history_api_service.dart)
- [transaction_history_page.dart](/var/www/html/VtuMobileAppBusiness/lib/features/transactions/presentation/pages/transaction_history_page.dart)

Current export behavior:

- CSV download works on Flutter web
- native file saving is not connected yet, so native builds currently show a ready-state message after export response
