# API Contract Notes

For project-wide status and the full page inventory, also see:
- `../project-report.md`
- `../module-page-reference.md`

Create one file per implemented feature in this folder.

Suggested filenames:
- `auth.md`
- `dashboard.md`
- `buy_airtime.md`
- `buy_data.md`
- `fund_wallet.md`
- `bill_payment.md`
- `pay_tv.md`
- `transaction_history.md`

Each file should capture:
- endpoint
- method
- auth type
- request payload
- response payload
- validation rules
- known backend gaps
- temporary workarounds

Do not mark a Flutter feature complete until its contract note is updated.

Important note:
- some features are already implemented in Flutter and backend-integrated even if a dedicated per-feature contract file has not been added here yet
- when that happens, update this folder progressively rather than treating the feature as undocumented forever
