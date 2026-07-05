# Supabase project link for soccer_sys

| Setting      | Value                                      |
|--------------|--------------------------------------------|
| Project name | LifestyleFit                               |
| Project ID   | `legcosmcypmrkyzhvbwo`                     |
| API URL      | `https://legcosmcypmrkyzhvbwo.supabase.co` |
| Region       | ap-southeast-1                             |

## Applied migrations (remote)

- `create_auth_profiles_and_roles` — profiles table + user_role enum + trigger + RLS
- `create_avatars_storage_bucket` — avatar storage
- `add_workouts_tables` — workouts feature
- `020_subscriptions` — trainer plans + trainee subscriptions (apply via CLI/MCP)
- `021_trainer_subscription_revenue` — RPC `trainer_subscription_revenue` for trainer earnings summary
- `023_trainer_and_moyasar` — trainer assign/cancel, legacy Moyasar RPCs (superseded by IAP)
- `028_iap_subscriptions` — Google Play / App Store in-app purchase flow

## Subscriptions

1. Apply migrations through `028_iap_subscriptions.sql` to project `legcosmcypmrkyzhvbwo`.
2. Trainers manage plans in app: **Dashboard → خطط الاشتراك**.
3. Trainers can **assign/cancel** subscriptions for trainees (any plan + custom dates, waived) from **المشتركون**.
4. Trainees subscribe from gated tabs or **عرض الخطط**; chat stays open without subscription.
5. Paid plans use **In-App Purchase** (`initiate_plan_payment` → native store sheet → `verify-store-purchase`).

## In-app purchase (Google Play / App Store)

1. Create non-consumable products in **App Store Connect** and **Google Play Console** with IDs:
   - `lifestyle_fit_sub_30d` (30 days)
   - `lifestyle_fit_sub_90d` (90 days)
   - `lifestyle_fit_sub_180d` (180 days)
2. Apply migration `028_iap_subscriptions.sql` (if not already on remote):
   ```bash
   supabase db push --project-ref legcosmcypmrkyzhvbwo
   ```
   Or paste the SQL from `supabase/migrations/028_iap_subscriptions.sql` in **Dashboard → SQL Editor**.
3. Deploy Edge Function:
   ```bash
   supabase login
   supabase link --project-ref legcosmcypmrkyzhvbwo
   supabase functions deploy verify-store-purchase --project-ref legcosmcypmrkyzhvbwo
   ```
4. Test on **physical iOS/Android devices** (IAP does not work on web).
5. Optional: add server-side receipt validation (Apple App Store Server API / Google Play Developer API) in `verify-store-purchase`.

> **Note:** Supabase MCP may lack permission to apply migrations from Cursor; use CLI or Dashboard above.

## Agora voice/video calls

1. Create a project at [Agora Console](https://console.agora.io/) and copy **App ID** + **App Certificate**.
2. Add to `.env`: `AGORA_APP_ID=<your-app-id>`
3. Set Supabase Edge Function secrets (Dashboard → Edge Functions → Secrets):
   - `AGORA_APP_ID`
   - `AGORA_APP_CERTIFICATE`
4. Deploy the token function:
   ```bash
   supabase functions deploy generate-agora-token --project-ref legcosmcypmrkyzhvbwo
   ```
5. Test on **two physical Android/iOS devices** (simulators have limited A/V).

## Push notifications (FCM)

1. Firebase project **lifestyle-fit** is linked via FlutterFire (`firebase_options.dart`, `google-services.json`).
2. Migration `018_profiles_fcm_token.sql` adds `fcm_token`, `fcm_platform`, `fcm_token_updated_at` on `profiles`.
3. Set Supabase Edge Function secrets (Dashboard → Project Settings → Edge Functions → Secrets, or CLI below):
   - `FIREBASE_SERVICE_ACCOUNT_JSON` — paste the **entire** JSON from Firebase Console → Project settings → Service accounts → Generate new private key. Use project **lifestyle-fit** (same as `firebase_options.dart`). Paste as a single line; `\n` in `private_key` is fine.
   **Or run the helper script** (from project root, after `supabase login`):
   ```powershell
   .\scripts\set-firebase-push-secret.ps1 "C:\Users\bsmq2\Downloads\lifestyle-fit-firebase-adminsdk-fbsvc-fd658ec758.json"
   ```
   **Or paste in Dashboard:** Project Settings → Edge Functions → Secrets → `FIREBASE_SERVICE_ACCOUNT_JSON` = full contents of the JSON file.
   - Optional: `PUSH_WEBHOOK_SECRET` — shared secret for the database webhook header `x-webhook-secret`
4. Deploy the push function:
   ```bash
   supabase functions deploy send-push-notification --project-ref legcosmcypmrkyzhvbwo
   ```
5. Create a **Database Webhook** (Dashboard → Database → Webhooks):
   - Table: `chat_messages`
   - Events: `INSERT`
   - Type: Supabase Edge Function → `send-push-notification`
   - Or HTTP POST to the function URL with header `x-webhook-secret` if using external webhook
6. **iOS**: run `flutterfire configure` and add APNs key in Firebase Console; ensure `GoogleService-Info.plist` is in `ios/Runner/`.
7. Test on **two physical devices** with the app killed: send a chat message and start a call invite.

## Phone OTP auth (SMS)

1. Supabase Dashboard → **Authentication** → **Providers** → enable **Phone**.
2. Configure an SMS provider (Twilio recommended): Account SID, Auth Token, Message Service SID.
3. Apply migration `027_phone_auth_profiles.sql` (makes `profiles.email` optional, stores `phone_number`, updates `handle_new_user`).
4. In the app: **Login/Register** → tab **الهاتف / Phone** → enter Saudi mobile `05xxxxxxxx` → verify 6-digit OTP.

## Local setup

2. Config is in `lib/core/config/env_config.dart` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AGORA_APP_ID`)

## Managing schema

Use the Supabase MCP plugin or Dashboard to inspect/apply changes.  
Do not re-apply `001_profiles_and_roles.sql` on LifestyleFit — it already exists.
