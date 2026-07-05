# Store subscriptions setup (App Store + Google Play)

Package / bundle ID: **`com.sa.lifestylefit`**

The app uses **fixed-duration in-app products** (non-consumable on iOS, one-time product on Android), not auto-renewing subscriptions.

## Product IDs (must match exactly)

| Product ID | Duration | Used when plan is |
|------------|----------|-------------------|
| `lifestyle_fit_sub_30d` | 30 days | 30-day trainer plan |
| `lifestyle_fit_sub_90d` | 90 days | 90-day trainer plan |
| `lifestyle_fit_sub_180d` | 180 days | Any other duration |

Defined in: `lib/modules/subscriptions/constants/store_product_catalog.dart`

## App Store Connect (iOS)

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → Lifestyle Fit
2. **Features → In-App Purchases → +** → **Non-Consumable**
3. Create all three product IDs above
4. Set **Reference Name**, **Price** (SAR), and localized display name/description
5. Submit products for review with the app version
6. **Agreements, Tax, and Banking** must be active
7. Add **Sandbox testers** for testing

## Google Play Console (Android)

1. Open [Google Play Console](https://play.google.com/console) → Lifestyle Fit
2. **Monetize → Products → In-app products → Create product**
3. Create managed products with the same three IDs
4. Set price, title, description, activate each product
5. **Monetize → Monetization setup** — complete merchant account
6. Add **License testers** for internal testing

## Supabase (backend)

Apply migration `028_iap_subscriptions.sql`:

```bash
supabase db push --project-ref legcosmcypmrkyzhvbwo
```

Deploy edge function:

```bash
supabase functions deploy verify-store-purchase --project-ref legcosmcypmrkyzhvbwo
```

## Test flow (trainee)

1. Register as trainee → choose trainer
2. Open subscription plans → select paid plan
3. Checkout loads store price → **Subscribe now**
4. Complete sandbox / test purchase
5. App calls `verify-store-purchase` → subscription becomes **active**
6. Dashboard / workouts / steps unlock via `SubscriptionGate`

## Notes

- Store price is what the user pays; trainer plan price in the app is informational unless you align both.
- **Restore purchases** works on the checkout screen after selecting a plan.
- Production: add Apple / Google receipt validation in `verify-store-purchase` (currently trusts native purchase + transaction id).
