# Welcome Page Contract

## Purpose

This is the first native Flutter screen.

The screen is based on the Laravel mobile welcome component, but it is now implemented directly in Flutter.

## Source of truth

Laravel reference files:
- `/var/www/html/AqtrisPay/resources/js/Pages/Welcome.tsx`
- `/var/www/html/AqtrisPay/resources/js/Components/MobileAppWelcome.tsx`

Flutter implementation:
- `/var/www/html/VtuMobileAppBusiness/lib/features/welcome/presentation/welcome_page.dart`

## Design elements carried over

- branded header with logo and product text
- theme toggle in the top-right corner
- rotating welcome slides
- centered mobile card / phone mockup illustration
- service accent icons around the main hero card
- dot indicators for the active slide
- bottom CTA buttons for `Register` and `Log In`

## Current behavior

- slide rotation runs automatically every 4.5 seconds
- tapping a dot changes the active slide
- `Register` and `Log In` currently show a temporary message because auth pages are not implemented yet

## Network/API contract

- none

This screen is fully local Flutter UI and does not depend on the Laravel backend at runtime.

## Known gaps

- auth navigation is still pending
- typography is approximated in Flutter and does not yet bundle the exact web font
- this is the native mobile version only, not the larger desktop landing page from Laravel
