# Database Schema

> **Supabase project:** LifestyleFit (`legcosmcypmrkyzhvbwo`)  
> **Region:** ap-southeast-1  
> **Migration applied:** `create_auth_profiles_and_roles` (20260603042900)

## profiles

| Column              | Type           | Notes                                      |
|---------------------|----------------|--------------------------------------------|
| id                  | UUID (PK)      | FK → `auth.users(id)` ON DELETE CASCADE    |
| first_name          | VARCHAR        | NOT NULL                                   |
| last_name           | VARCHAR        | NOT NULL                                   |
| email               | VARCHAR        | NOT NULL, UNIQUE                           |
| phone_number        | VARCHAR        | nullable                                   |
| avatar_url          | TEXT           | nullable                                   |
| bio                 | TEXT           | nullable                                   |
| date_of_birth       | DATE           | nullable                                   |
| gender              | VARCHAR        | `male` \| `female`                         |
| role                | user_role      | `trainee` \| `trainer`, default `trainee`  |
| specialization      | VARCHAR        | trainer field, nullable                    |
| years_of_experience | INTEGER        | trainer field, >= 0                        |
| certification       | TEXT           | trainer field, nullable                    |
| hourly_rate         | NUMERIC        | trainer field, >= 0                        |
| fitness_goal        | TEXT           | trainee field, nullable                    |
| current_weight      | NUMERIC        | trainee field, > 0                         |
| target_weight       | NUMERIC        | trainee field, > 0                         |
| height_cm           | NUMERIC        | trainee field, > 0                         |
| activity_level      | VARCHAR        | sedentary \| light \| moderate \| active \| very_active |
| daily_step_goal     | INTEGER        | default `10000`, > 0                       |
| trainer_id          | UUID           | FK → `profiles(id)`, trainee only, nullable  |
| last_seen_at        | TIMESTAMPTZ    | chat presence, nullable                      |
| is_active           | BOOLEAN        | default `true`                             |
| is_verified         | BOOLEAN        | default `false`                            |
| is_deleted          | BOOLEAN        | default `false`                            |
| deleted_at          | TIMESTAMPTZ    | nullable                                   |
| created_at          | TIMESTAMPTZ    | default UTC now                            |
| updated_at          | TIMESTAMPTZ    | default UTC now                            |

## user_role enum

- `trainee`
- `trainer`

## Trigger: handle_new_user

On `auth.users` INSERT, creates a `profiles` row using:

- `first_name` ← `raw_user_meta_data->>'first_name'`
- `last_name` ← `raw_user_meta_data->>'last_name'`
- `role` ← `raw_user_meta_data->>'role'` (default `trainee`)

## RLS Policies

- Users can **SELECT** their own profile (`auth.uid() = id`)
- Users can **UPDATE** their own profile (`auth.uid() = id`)

## Flutter Model

Dart model: [`lib/modules/auth/models/user_model.dart`](../../lib/modules/auth/models/user_model.dart)

## Local migration reference

See [`supabase/migrations/001_profiles_and_roles.sql`](../../supabase/migrations/001_profiles_and_roles.sql) for reference SQL aligned with the remote project.

---

## Chat system (Migration `002_chat_system.sql`)

### message_type enum

- `text`
- `image`
- `file`
- `audio`

### chat_rooms

| Column     | Type        | Notes                    |
|------------|-------------|--------------------------|
| id         | UUID (PK)   | default `gen_random_uuid()` |
| created_at | TIMESTAMPTZ | default UTC now          |
| updated_at | TIMESTAMPTZ | default UTC now          |

### chat_room_members

| Column       | Type        | Notes                              |
|--------------|-------------|------------------------------------|
| room_id      | UUID (FK)   | → `chat_rooms(id)` ON DELETE CASCADE |
| user_id      | UUID (FK)   | → `profiles(id)` ON DELETE CASCADE |
| last_read_at | TIMESTAMPTZ | nullable                           |
| joined_at    | TIMESTAMPTZ | default UTC now                    |

Primary key: `(room_id, user_id)`

### chat_messages

| Column             | Type          | Notes                              |
|--------------------|---------------|------------------------------------|
| id                 | UUID (PK)     | default `gen_random_uuid()`        |
| room_id            | UUID (FK)     | → `chat_rooms(id)` ON DELETE CASCADE |
| sender_id          | UUID (FK)     | → `profiles(id)`                   |
| type               | message_type  | NOT NULL                           |
| content            | TEXT          | nullable (text messages)           |
| media_url          | TEXT          | storage path in `chat-media` bucket |
| file_name          | TEXT          | nullable                           |
| file_size          | INTEGER       | nullable                           |
| audio_duration_ms  | INTEGER       | nullable                           |
| created_at         | TIMESTAMPTZ   | default UTC now                    |

### RPC functions

- **`get_or_create_direct_room(p_peer_id UUID)`** — creates or returns existing 1:1 room between trainer ↔ trainee
- **`get_chat_rooms_for_user()`** — room list with peer profile, last message preview, unread count
- **`mark_chat_room_read(p_room_id UUID)`** — sets `last_read_at = now()` for current user

### Storage

- Bucket: **`chat-media`** (private)
- Path pattern: `{room_id}/{message_id}/{filename}`

### Realtime

- Publication enabled on `chat_messages` (INSERT)

### RLS summary

- Room members can SELECT messages in their rooms; INSERT only as self (`sender_id = auth.uid()`)
- Members can SELECT/UPDATE own `chat_room_members` row (`last_read_at`)
- Profiles SELECT allowed for own row and opposite role (chat picker via `get_auth_user_role()`)
- Room creation via RPC only (validates trainer ↔ trainee roles)

See [`supabase/migrations/002_chat_system.sql`](../../supabase/migrations/002_chat_system.sql) and [`003_fix_profiles_rls_recursion.sql`](../../supabase/migrations/003_fix_profiles_rls_recursion.sql).

---

## Daily activity (Migration `004_daily_activity.sql`)

### daily_activity

| Column        | Type        | Notes                              |
|---------------|-------------|------------------------------------|
| id            | UUID (PK)   | default `gen_random_uuid()`        |
| user_id       | UUID (FK)   | → `profiles(id)` ON DELETE CASCADE |
| activity_date | DATE        | unique per user                    |
| steps         | INTEGER     | >= 0                               |
| calories      | NUMERIC     | derived at sync                    |
| distance_km   | NUMERIC     | derived at sync                    |
| goal_steps    | INTEGER     | snapshot of goal that day          |
| source        | TEXT        | default `pedometer`                |
| created_at    | TIMESTAMPTZ | default UTC now                    |
| updated_at    | TIMESTAMPTZ | default UTC now                    |

Unique: `(user_id, activity_date)`

### RPC functions

- **`upsert_daily_activity(p_date, p_steps, p_calories, p_distance_km, p_goal_steps)`** — idempotent daily sync for `auth.uid()`
- **`get_activity_summary(p_from_date, p_to_date)`** — date-range history for charts

### RLS

- Users SELECT/INSERT/UPDATE own `daily_activity` rows only

See [`supabase/migrations/004_daily_activity.sql`](../../supabase/migrations/004_daily_activity.sql).

---

## Avatars storage (Migration `005_avatars_storage.sql`)

- Bucket: **`avatars`** (public read)
- Path: `{user_id}/avatar.{ext}`
- Policies: users INSERT/UPDATE/DELETE own folder; public SELECT

See [`supabase/migrations/005_avatars_storage.sql`](../../supabase/migrations/005_avatars_storage.sql).

---

## Chat fixes & presence (Migration `006_chat_fix_presence_video.sql`)

- Fixes `get_chat_rooms_for_user()` column aliases (rooms list RPC)
- Adds `profiles.last_seen_at` for online / last seen in chat
- Adds `video` to `message_type` enum

See [`supabase/migrations/006_chat_fix_presence_video.sql`](../../supabase/migrations/006_chat_fix_presence_video.sql).

---

## Trainee progress gallery (Migration `007_trainee_progress_photos.sql`)

### trainee_progress_entries

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK → profiles | owner |
| recorded_at | DATE | progress date |
| weight_kg | NUMERIC | optional |
| note | TEXT | optional |
| created_at / updated_at | TIMESTAMPTZ | |

### trainee_progress_photos

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| entry_id | UUID FK → entries CASCADE | |
| user_id | UUID FK → profiles | RLS |
| storage_path | TEXT | `{user_id}/{entry_id}/{photo_id}.ext` |
| sort_order | INT | gallery order |

- Bucket: **`progress-photos`** (private, signed URLs)
- RLS: trainee CRUD own rows only

See [`supabase/migrations/007_trainee_progress_photos.sql`](../../supabase/migrations/007_trainee_progress_photos.sql).

---

## Trainer assignment (Migration `012_trainer_assignment.sql`)

- **`profiles.trainer_id`**: each trainee may link to one trainer
- **RPCs:** `assign_trainer`, `get_my_trainer`, `get_my_trainees`, `list_available_trainers`
- **Chat:** `get_or_create_direct_room` requires assignment match
- See [`supabase/migrations/012_trainer_assignment.sql`](../../supabase/migrations/012_trainer_assignment.sql).

---

## Subscriptions (Migration `020_subscriptions.sql`)

### subscription_plans

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| trainer_id | UUID FK → profiles | owner |
| title | VARCHAR | |
| description | TEXT | nullable |
| price_amount | NUMERIC | SAR |
| currency | VARCHAR | default `SAR` |
| duration_days | INT | e.g. 30, 90, custom |
| features | JSONB | array of feature strings |
| is_active / is_featured | BOOLEAN | |
| sort_order | INT | display order |

### trainee_subscriptions

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| trainee_id / trainer_id | UUID FK | |
| plan_id | UUID FK | nullable snapshot |
| plan_title / plan_price / duration_days | | snapshot at subscribe |
| status | subscription_status | `active`, `expired`, `cancelled`, `pending` |
| payment_status | subscription_payment_status | `waived`, `pending_moyasar`, `paid` |
| starts_at / ends_at | TIMESTAMPTZ | trainer can edit |
| moyasar_payment_id / moyasar_checkout_id | TEXT | Moyasar payment reference |

- One **active** subscription per `(trainee_id, trainer_id)` (partial unique index).
- **RPCs:** `list_trainer_subscription_plans`, `upsert_subscription_plan`, `deactivate_subscription_plan`, `subscribe_to_plan` (free plans only), `initiate_plan_payment`, `activate_paid_subscription` (service role), `get_my_active_subscription`, `trainer_list_subscribers`, `trainer_update_subscription_period`, `trainer_assign_subscription`, `trainer_cancel_subscription`, `trainer_subscription_revenue`, `has_active_subscription`.
- **Edge Functions:** `verify-moyasar-payment`, `moyasar-webhook`.
- See [`supabase/migrations/020_subscriptions.sql`](../../supabase/migrations/020_subscriptions.sql) and [`023_trainer_and_moyasar.sql`](../../supabase/migrations/023_trainer_and_moyasar.sql).

