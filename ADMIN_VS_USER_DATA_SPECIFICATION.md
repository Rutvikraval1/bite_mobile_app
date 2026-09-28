# Bite — Admin vs. User Data Structure & Responsibility Specification

**App:** b🌶te (Flutter client + Supabase backend) — food/drink/place discovery, swipe deck, social, gamification, and AI "Genie" assistant
**Document purpose:** Define, for every data type in the product, who creates it, who manages it, who can see it, who can edit it, and whether it needs moderation — as a reference for both engineering and client sign-off.
**Status of source app:** Prototype. This document distinguishes clearly between:
- 🟢 **CURRENT** — what exists and is wired to a real database today
- 🟡 **MOCK** — visible in the UI but not connected to any backend (hardcoded/local only)
- 🔵 **RECOMMENDED** — not built yet; proposed for production and explicitly marked as a recommendation, not a confirmed requirement

---

## 0. Critical Finding — Read This First

The current backend has **no real authentication boundary and no admin/user separation at the database level**. This is the single most important fact for planning production data ownership:

- The app ships with **no login screen**. The Flutter client authenticates to Supabase using only the **anonymous (anon) public key**.
- All 7 existing tables have Row Level Security (RLS) **enabled but effectively open**: every policy is `USING (true)` / `WITH CHECK (true)` for `anon, authenticated` — meaning **any client can read, insert, update, or delete any row in any table**, including the "content" tables (`recipes`, `drinks`, `places`) that are conceptually admin-owned.
- This is **documented as deliberate** in the codebase's own migration history and README (`supabase/tables/README.md`, migration `20260812054840_fix_rls_for_no_auth_app.sql`): *"This is a deliberate single-tenant, shared-data setup... not an oversight... When real per-user auth is added, tighten these policies back to `auth.uid() = user_id` / `auth.uid() = id` ownership checks."*
- The **original intended design** (captured in an earlier migration, `20260812054314_bite_connect_all_pages.sql`) was exactly the admin/user split this document formalizes: *"Content tables: SELECT for authenticated (shared content), INSERT/UPDATE/DELETE blocked (admin-managed content). User tables: full CRUD scoped to `auth.uid()`."* That intent was reverted for prototype convenience only.

**Everything in Sections 1–9 below reflects this reality**: it describes both (a) what the *intended* admin/user responsibility split is — which the client should confirm — and (b) what must change technically (real auth + tightened RLS) before that split is actually enforced. Section 11 gives the concrete Supabase RLS pattern to implement this correctly.

---

## 1. What Actually Exists Today vs. What Is Mock/Placeholder

Only **7 database tables exist**, all in Supabase Postgres. Everything else visible in the app's UI (social feed, comments, likes, chat/DMs, notifications, competitions, Elo voting, community-impact/donations, creator content publishing, Genie chat history, tipping, subscriptions) is **hardcoded or local-only data with zero server persistence** — confirmed both by explicit in-code doc-comments (e.g. *"No `posts` table exists yet, so publishing is local-only"*, *"No `competitions` table exists"*, *"No voting table exists yet"*, *"No backend table exists for donations yet"*) and by the fact that 17 of the 24 table-name constants declared in `lib/core/constants/table_names.dart` are never referenced anywhere in the app.

| Domain | Status | Notes |
|---|---|---|
| User profiles | 🟢 CURRENT | Real table, real reads/writes |
| Recipes (Food) catalog | 🟢 CURRENT | Real table; only populated via seed SQL today, no in-app authoring writes to it |
| Drinks catalog | 🟢 CURRENT | Same as above |
| Places catalog | 🟢 CURRENT | Same as above |
| Saved items (favorites) | 🟢 CURRENT | Real table, per-user |
| Meal plan calendar | 🟢 CURRENT | Real table, per-user |
| Swipe/engagement log | 🟢 CURRENT | Real table, write-only (never read back in-app) |
| Premium subscription flag | 🟢 CURRENT | Real columns on `profiles` (`is_premium`, `user_tier`), written by the Premium screen |
| Social feed posts/activity | 🟡 MOCK | Hardcoded constants in `mock_social_data.dart` |
| Comments (on recipes/places/posts) | 🟡 MOCK | Ephemeral, in-memory per screen session; lost on navigation/restart |
| Likes/reactions | 🟡 MOCK | Local `Set` in widget state only |
| Chat / DMs / Live Kitchens | 🟡 MOCK | Canned message lists, no real messaging backend |
| Notifications | 🟡 MOCK | 10 hardcoded notification rows |
| Creator content publishing (recipes/drinks) | 🟡 MOCK | UI flow exists (3-step wizard, step 1 only) but publish action is a toast — nothing is written anywhere |
| Reviews (place reviews, "Bite reviews") | 🟡 MOCK | Static per-screen constant lists, not tied to a real place ID |
| Competitions / Cook-Offs | 🟡 MOCK | Enter/accept/challenge actions are toast-only |
| Elo voting ("Top Dish" battles) | 🟡 MOCK | Scores computed client-side, reset when screen closes |
| Community Impact / charity donations | 🟡 MOCK | Illustrative numbers only; charity selection during Premium purchase is not persisted |
| XP/badge awards from social actions (rating, tipping, voting) | 🟡 MOCK | UI shows "+N pts" but no traced write-back to `profiles.xp` |
| Genie AI chat / meal planner / ingredient scan | 🟡 MOCK | Keyword-matched canned replies; fake "scan" result is always the same dish; no LLM or vision backend |
| Delivery/reservation integrations (DoorDash, Uber Eats, Grubhub, OpenTable, Resy) | 🟡 MOCK | Static display rows on the Place Detail screen, no real API integration |
| Account deletion RPC (`delete_own_account`) | ⚠️ Referenced but not found defined in any read SQL migration — likely missing or exists only in a live project not checked into this repo |

This table is the backbone of the gap analysis in Section 10.

---

## 2. Current Database Schema (Ground Truth)

### 2.1 `profiles` — one row per user, extends `auth.users`

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK, FK → auth.users) | |
| display_name | text | |
| username | text | |
| bio | text | |
| avatar_emoji | text | default 🧑‍🍳 |
| dob | date | nullable |
| xp | integer | |
| bite_coins | integer | |
| streak_count | integer | |
| longest_streak | integer | |
| streak_multiplier | numeric | |
| streak_freezes | integer | |
| daily_chest_claimed | boolean | |
| is_premium | boolean | |
| user_tier | text | default 'free' |
| cuisines | text[] | preference tags |
| dietary | text[] | preference tags |
| badges | text[] | earned badge IDs |
| age_verified | boolean | |
| location_granted | boolean | |
| cooking_skill | text | nullable |
| cooking_goal | text | nullable |
| created_at / updated_at | timestamptz | auto-managed by trigger |

**Owner:** the user. **Visible to:** currently anyone (open RLS); should be self + Admin only. **Created by:** `handle_new_user()` trigger on signup (`SECURITY DEFINER`, auto-inserts a minimal row).

### 2.2 `recipes` (Food catalog)

id, title, creator, time_min, difficulty, serves, heat_level, saved_count, hearts_count, comments_count, emoji, image_url, cuisine, gradient, tags[], created_at.

**Notable gap:** no `ingredients` or `steps` columns exist anywhere in the schema. Cook Mode currently shows a single fixed hardcoded template regardless of which recipe is opened — this is a functional gap, not just a mock-data gap (see Section 10).

### 2.3 `drinks` — same shape as `recipes`, minus `cuisine` default behavior, default emoji 🍹.

### 2.4 `places` (Restaurants/venues)

id, title, creator, price_level, cuisine, saved_count, hearts_count, comments_count, emoji, image_url, gradient, address, phone, rating, review_count, hours, status, distance, photos[], tags[], **menu_highlights** (jsonb array of `{name, price}`), created_at.

### 2.5 `saved_items` (Favorites)

id, user_id (FK, nullable), item_type (`recipe`|`drink`|`place`), item_id, title, emoji, image_url, cuisine, created_at. Unique on `(user_id, item_type, item_id)`.

### 2.6 `meal_plans` (Calendar)

id, user_id (FK, nullable), plan_date, meal_slot (breakfast/lunch/dinner/snack), title, emoji, color, created_at.

### 2.7 `swipes` (Engagement log)

id, user_id (FK, nullable), item_type, item_id, action (`save`|`pass`), cuisine, created_at. Write-only today — no feature reads it back (candidate for admin analytics, see Section 9).

### 2.8 Functions & Triggers

- `handle_new_user()` — auto-creates a `profiles` row on signup.
- `set_updated_at()` — refreshes `profiles.updated_at` on every update.

---

## 3. Domain-by-Domain Responsibility Matrix

This is the core deliverable: for every data domain in the product, who does what.

### 3.1 Food / Drinks / Places (Catalog Content)

| Aspect | Answer |
|---|---|
| Who creates it? | **Admin only** (intended design). Today: nobody in-app — populated via seed SQL scripts. |
| Can users submit food/drinks/places? | **No, not currently.** A "Create" flow exists in the UI (`CreatorCreateScreen`) but does not publish anywhere — it is a non-functional prototype screen. 🔵 **Recommended:** decide whether user-generated recipes/drinks should ship as v1 or v2 (see Q&A in Section 10). |
| Who manages restaurant/menu info? | **Admin.** Address, phone, hours, price level, `menu_highlights` are all admin-entered fields; no restaurant-owner or business-claim flow exists. |
| Who approves user-submitted content? | N/A today (no submission path exists). 🔵 If user-generated recipes are added: **Admin moderation queue required before publish** (see Section 6). |
| Visible to | Everyone (public catalog) |
| Editable by | Admin only (intended); currently open to any anon client (bug/gap, see Section 0) |
| Read-only for | Users |
| Public/private | Public |

### 3.2 Categories, Tags, Cuisines

| Aspect | Answer |
|---|---|
| Who manages the taxonomy? | **Admin.** Cuisine and tag values are currently free-text strings/arrays on each content row — there is **no separate `categories` or `tags` lookup table**. 🔵 **Recommended:** extract into normalized `categories`/`tags` tables (Section 11) so Admin can manage the canonical list, rename/merge tags, and prevent duplicate/typo'd values (e.g. "Italian" vs "italian"). |
| Who assigns tags to content? | Admin, when creating/editing a recipe/drink/place. |
| Visible to | Everyone (used as filters in Genie filter screen, deck tabs) |
| Editable by | Admin only |

### 3.3 Featured/Trending Content

| Aspect | Answer |
|---|---|
| Current state | No `featured` or `trending` flag exists on any content table. The "Trending" tab in the social feed uses hardcoded mock cards. |
| 🔵 Recommended | Add a `featured` boolean + `featured_rank` integer (or a separate `featured_content` join table) that only Admin can set, to power a real "Editor's Picks"/"Trending" surface without relying on mock data. |

### 3.4 Reviews & Ratings

| Aspect | Answer |
|---|---|
| Current state | No `reviews` table exists. Place-detail "reviews" and "Bite reviews" panels are static, hardcoded per-screen text — not tied to the actual place, not submitted by real users. `review_count`/`rating` on `places` are static seed values, never incremented by real user actions. |
| Who should create a review? | **User** (🔵 recommended design) — one review per user per place/recipe. |
| Who owns a review? | The user who wrote it (can edit/delete their own). |
| Who moderates reviews? | **Admin** — must be able to remove reviews that violate content policy (spam, harassment, fake). |
| Visible to | Everyone (public), except reviews flagged/removed by Admin |
| Editable by | Review author (their own text/rating); Admin can delete but should not silently edit a user's words |
| Aggregate rating (`places.rating`, `review_count`) | 🔵 Recommended: compute via a database trigger/function from real review rows instead of a static seed number, so it can't be manually inflated by a non-admin write |

### 3.5 Comments (on recipes, places, and social posts)

| Aspect | Answer |
|---|---|
| Current state | No `post_comments` table exists. Comments are appended to an in-memory list per screen and vanish on navigation — nothing persists. |
| Who creates comments? | **User.** |
| Who owns a comment? | The commenting user (can delete their own). |
| Who moderates? | **Admin** — must be able to delete any comment (abuse/spam) and, 🔵 recommended, soft-ban repeat offenders. |
| Visible to | Public by default; hidden if flagged/removed |

### 3.6 Photos

| Aspect | Answer |
|---|---|
| Catalog photos (`recipes.image_url`, `places.photos[]`) | **Admin-managed.** Part of the content record. |
| User-submitted photos (e.g. attached to a review, a "cooked it" post, or the Quick Rate sheet's photo option) | **User-owned**, but 🔵 recommended: **all user-uploaded photos should be admin-moderatable** (removable, and ideally auto-scanned for policy violations before going public — see Section 6). |
| Current state | No `photos`/`user_uploads` table exists; the Quick Rate sheet's "add photo" toggle is a boolean UI stub with no actual upload/storage wired up. |

### 3.7 Locations

| Aspect | Answer |
|---|---|
| Place location (address, phone, hours, distance) | **Admin-entered**, stored as plain text fields today (no lat/long, no PostGIS). 🔵 Recommended: add `latitude`/`longitude` numeric columns for real distance/map features — "distance" is currently a static display string, not computed from the user's actual location, despite a `location_granted` boolean already existing on `profiles`. |
| User's own location | **User-owned**, private — only the `location_granted` permission flag is stored server-side today; no actual coordinates are persisted for the user. |

### 3.8 Offers / Events

| Aspect | Answer |
|---|---|
| Current state | No `offers` table. A `LocalEvent` list (venue, date, price, attendee count, "sold out" flag) exists only as hardcoded mock data in the social feature. |
| Who should create offers/events? | **Admin** (or, 🔵 recommended for a future phase, verified business/restaurant accounts, subject to Admin approval before going live). |
| Who can RSVP/attend? | **User** — 🔵 recommended: a real `event_attendees` join table is needed; currently "attending" counts are static mock numbers. |
| Visible to | Public |
| Editable by | Admin (and event creator, if business accounts are added later) |

### 3.9 Users & Profiles

| Aspect | Answer |
|---|---|
| Who creates a profile? | Auto-created by the `handle_new_user` trigger on signup; the user then completes it via onboarding/Edit Profile. |
| Fields the user owns and can edit | `display_name`, `username`, `bio`, `avatar_emoji`, `dietary`, `cuisines`, `cooking_skill`, `cooking_goal`, password. |
| Fields the user should **not** be able to directly edit | `xp`, `bite_coins`, `streak_count`, `longest_streak`, `streak_multiplier`, `streak_freezes`, `daily_chest_claimed`, `badges`, `is_premium`, `user_tier`, `age_verified` — these must be **system/server-controlled** (written by game-logic functions or payment webhooks), never by a raw client update. ⚠️ **Current gap:** `ProfileMapper.toMap()` unconditionally includes most of these fields in every profile update payload, and open RLS means a client *could* currently overwrite its own XP/premium flag directly. This must be locked down before production (Section 11). |
| Visible to Admin | Full profile, for support/moderation purposes. |
| Visible to other Users | Public-facing subset only — 🔵 recommended: `display_name`, `username`, `avatar_emoji`, `bio`, badges, tier (i.e., a "public profile" view), never `dob`/`age_verified`/internal fields. |
| Private fields | `dob`, `age_verified`, `location_granted`, `bite_coins`, real email (stored in `auth.users`, not `profiles`) |

### 3.10 Social Content (Feed Posts, "Cooked It" Activity, Creator Profiles, Follows)

| Aspect | Answer |
|---|---|
| Current state | 100% mock. No `feed_posts`, `post_reactions`, `follows`, or creator-profile tables exist. |
| Who creates a post? | **User** (🔵 recommended design — e.g., auto-generated "X cooked Y" activity, or a user-authored text/photo post). |
| Who owns it? | The posting user; can delete their own posts. |
| Who moderates? | **Admin** — must be able to remove any post/reported content. |
| Visibility | 🔵 Recommended: public by default, with a per-post or account-level visibility setting (public/followers-only/private) — none of this exists today. |

### 3.11 Favorites (Saved Items)

Already real (Section 2.5). **User-owned, private** (a user's saved list should only be visible to themselves — currently technically readable by any anon client due to open RLS). Not moderated (favoriting isn't public-facing content).

### 3.12 Orders / Bookings

| Aspect | Answer |
|---|---|
| Current state | **Does not exist at all.** The "reservation" (OpenTable/Resy) and "delivery" (DoorDash/Uber Eats/Grubhub) rows on the Place Detail screen are static display-only UI with no real integration, no order table, and no booking table. |
| 🔵 Recommended | If real ordering/reservations are in scope for production, this needs a full new subsystem: `bookings`/`orders` table, third-party API integration (or a manual admin-fulfilled flow), user-owned records readable by both the user and Admin (for support), and status fields (pending/confirmed/cancelled) that only Admin or the integration webhook can transition. |

### 3.13 Notifications

| Aspect | Answer |
|---|---|
| Current state | 10 hardcoded rows; not personalized, not real. |
| Who triggers a notification? | 🔵 Recommended: **system-generated** (e.g., a like on your post, a streak reminder, a friend joined) — never directly user- or admin-authored per row, except for **Admin broadcast/announcement notifications** (see 3.14). |
| Who owns/reads them? | The recipient user only. |
| Editable by | User can mark read/delete their own; cannot edit content. Admin cannot edit a user's notification but can manage the system templates that generate them. |

### 3.14 Admin Broadcasts / Announcements

🔵 **Recommended (does not exist today):** Admin should have a way to push app-wide announcements (e.g., "New feature," "Scheduled maintenance," policy updates). This implies a `broadcasts` table: Admin-created, visible to all users, read-only for users.

### 3.15 Reports (Content Moderation Reports)

🔵 **Recommended (does not exist today):** No "report this content" action exists anywhere in the current UI for reviews, comments, posts, or profiles. For any production social feature, this is required: `reports` table — **created by User** (reporter), **visible only to Admin**, with a status field (`open`/`reviewed`/`actioned`/`dismissed`) that only Admin can change. See Section 6 for the full moderation flow this should drive.

### 3.16 Gamification (XP, Streaks, Tiers, Badges)

| Aspect | Answer |
|---|---|
| Who defines the rules? | **Admin/Engineering**, as static config (`TierDefinitions`, `BadgeCatalog` — currently hardcoded Dart constants, not database rows). 🔵 Recommended for production: move these into an Admin-manageable `badge_definitions`/`tier_definitions` table so thresholds and badge art can be tuned without an app release. |
| Who holds the earned values? | **User**, stored on their own `profiles` row (`xp`, `badges`, `streak_count`, etc.) |
| Who writes these values? | **System only** — server-side functions/triggers in response to real actions (cooking, saving, rating), never the client directly (see 3.9 gap note). |
| Visible to | User (their own progress); Admin (all users', for support/anti-cheat); 🔵 recommended: other users can see badges/tier on a public profile, not raw XP. |

### 3.17 Premium / Subscriptions

| Aspect | Answer |
|---|---|
| Current state | Real fields (`is_premium`, `user_tier`) on `profiles`, written directly by the client after a purchase confirmation — **no payment processor or receipt validation is wired up today**; the "purchase" is simulated. |
| 🔵 Recommended for production | Subscription state must be **written only by a server-side webhook** from the real payment processor (Apple/Google/Stripe), never by a raw client update to `profiles.is_premium`. Add a `subscriptions` table logging processor, plan, status, renewal date — Admin-visible for support, user-visible (their own) as read-only status. |

### 3.18 Competitions / Cook-Offs / Elo Voting / Community Impact (Donations)

| Aspect | Answer |
|---|---|
| Current state | 100% mock/local, no persistence, explicitly documented as such in code comments. |
| Who should create a competition? | **Admin** (curated events), 🔵 recommended, possibly with a "user-started Cook-Off challenge" path that doesn't need moderation since it's just two consenting users. |
| Who submits an entry/vote? | **User.** |
| Who verifies results / anti-cheat? | **Admin** — the app's own UI copy already describes an anti-cheat policy ("AI-generated or filtered photos are auto-detected... 2nd offense: permanent ban") that has **no backing enforcement implemented**; this is a real gap if competitions ship (see Section 10). |
| Donation/charity data | **Admin manages the charity list**; **User selects a charity** during Premium purchase — 🔵 recommended: this selection must actually be persisted (add a `charity_id` FK on `profiles` or a `donations` table), which it currently is not. |

### 3.19 Genie AI Assistant (Chat, Meal Planner, Ingredient Scan)

| Aspect | Answer |
|---|---|
| Current state | Fully canned/keyword-matched responses; no real LLM or vision model; nothing persisted. |
| Data ownership if made real | 🔵 Recommended: Genie conversation history is **user-owned, private** (only that user and Admin-for-support should see it); Genie's underlying knowledge (recipe pairing rules, ingredient database) is **Admin/system-managed**, not user-editable. |

---

## 4. Database Entities — Consolidated List

### 4.1 Existing (🟢 CURRENT)

| Table | Owner | Key fields | Relationships |
|---|---|---|---|
| `profiles` | User (self) | id, display_name, username, xp, badges[], is_premium, user_tier, dietary[], cuisines[] | 1:1 with `auth.users` |
| `recipes` | Admin | id, title, creator, tags[], cuisine, image_url | Referenced by `saved_items.item_id` when `item_type='recipe'` (loose, no FK) |
| `drinks` | Admin | same shape as recipes | same loose reference pattern |
| `places` | Admin | id, title, address, menu_highlights (jsonb), rating | same loose reference pattern |
| `saved_items` | User | user_id (FK→auth.users), item_type, item_id | Many:1 to `profiles`; loosely to `recipes`/`drinks`/`places` |
| `meal_plans` | User | user_id (FK), plan_date, meal_slot, title | Many:1 to `profiles` |
| `swipes` | User (write), Admin (analytics read) | user_id (FK), item_type, item_id, action | Many:1 to `profiles`; write-only today |

⚠️ **Note on data integrity:** `saved_items.item_id`, `meal_plans`, and `swipes` reference recipes/drinks/places by a bare integer `item_id` + `item_type` string — there is **no actual foreign key** enforcing that the referenced row exists. 🔵 Recommended: this is acceptable for a prototype but should be tightened (or explicitly accepted as a soft-reference pattern) before production, since a deleted piece of content would leave orphaned saved items with no integrity check.

### 4.2 Recommended New Tables for Production

| Table | Owner | Purpose | Key fields (recommended) |
|---|---|---|---|
| `categories` | Admin | Normalized cuisine/category taxonomy | id, name, slug, icon |
| `tags` | Admin | Normalized tag taxonomy | id, name, slug |
| `reviews` | User (author) / Admin (moderation) | Real reviews tied to a specific place/recipe | id, user_id, item_type, item_id, rating, text, photo_url, status, created_at |
| `post_comments` | User / Admin (moderation) | Persisted comments | id, user_id, parent_type, parent_id, text, status, created_at |
| `post_reactions` | User | Likes/hearts | id, user_id, target_type, target_id, reaction_type |
| `feed_posts` | User / Admin (moderation) | Social feed activity | id, user_id, type, caption, photo_url, visibility, status, created_at |
| `follows` | User | Social graph | follower_id, followee_id |
| `conversations` / `messages` | User (participants) | Real chat/DMs | conversation_id, sender_id, text, created_at |
| `notifications` | System-generated, User-owned | Personalized alerts | id, user_id, type, payload, read_at |
| `broadcasts` | Admin | App-wide announcements | id, title, body, published_at |
| `reports` | User (author) / Admin (handler) | Moderation reports | id, reporter_id, target_type, target_id, reason, status |
| `badge_definitions`, `tier_definitions` | Admin | Config-as-data for gamification | id, name, threshold, reward |
| `subscriptions` | System (payment webhook) / Admin (support view) | Real billing state | id, user_id, processor, plan, status, renews_at |
| `competitions`, `competition_entries` | Admin (competitions) / User (entries) | Cook-off events | as scoped in 3.18 |
| `elo_entries`, `elo_votes` | Admin (entries) / User (votes) | Top-dish voting | as scoped in 3.18 |
| `events`, `event_attendees` | Admin (or verified business) / User (RSVP) | Local events | as scoped in 3.8 |
| `offers` | Admin / verified business | Promotions | id, place_id, title, terms, expires_at |
| `charities`, `donations` | Admin (charity list) / User (selection) | Community impact | id, user_id, charity_id, amount |
| `ingredients`, `recipe_steps` | Admin | Per-recipe cook data (currently missing entirely — Cook Mode uses one fixed template for all dishes) | recipe_id, step_no, text, timer_secs |
| `businesses` | 🔵 Optional future phase | Verified restaurant/owner accounts that can manage their own `places` row and offers, subject to Admin verification | id, owner_user_id, place_id, verified |

---

## 5. Admin vs. User Permission Matrix

| Data Type | Admin Create | Admin Edit | Admin Delete | Admin View | User Create | User Edit (own) | User Delete (own) | User View |
|---|---|---|---|---|---|---|---|---|
| Recipes/Drinks/Places catalog | ✅ | ✅ | ✅ | ✅ all | ❌ (🔵 optional future submission w/ approval) | ❌ | ❌ | ✅ public |
| Categories/Tags | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ (read, for filtering) |
| Featured/Trending flags | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Reviews | ✅ (moderate only) | ❌ (never edit user's words) | ✅ | ✅ all | ✅ | ✅ own | ✅ own | ✅ public (minus removed) |
| Comments | ❌ | ❌ | ✅ | ✅ all | ✅ | ✅ own | ✅ own | ✅ public (minus removed) |
| Photos (user-submitted) | ❌ | ❌ | ✅ | ✅ all | ✅ | ✅ own | ✅ own | ✅ public (minus removed) |
| Own profile core fields (name, bio, avatar, prefs) | ✅ (support override) | ✅ (support override) | ✅ (account deletion) | ✅ all | ✅ (onboarding) | ✅ own | ✅ own (delete account) | ✅ own; public subset for others |
| System-controlled profile fields (xp, badges, is_premium, streak) | ✅ (support override) | ✅ (support override) | — | ✅ all | ❌ | ❌ | ❌ | ✅ own; badges/tier public for others |
| Saved items / meal plans | ❌ | ❌ | ✅ (support) | ✅ (support) | ✅ | ✅ own | ✅ own | ✅ own only, private |
| Swipes log | ❌ | ❌ | ❌ | ✅ (analytics) | ✅ (implicit, via swiping) | ❌ | ❌ | ❌ private, system-only |
| Notifications | ✅ (broadcast only) | ❌ | ❌ | ✅ (support) | ❌ | ✅ own (mark read/delete) | ✅ own | ✅ own only |
| Reports | ❌ | ✅ (resolve/dismiss) | ❌ | ✅ all | ✅ (file a report) | ❌ | ❌ | ❌ Admin-only visibility |
| Competitions | ✅ | ✅ | ✅ | ✅ | ❌ (or peer-challenge only) | ✅ (entries/votes) | ✅ own entry | ✅ public |
| Subscriptions/billing | ❌ (system webhook writes) | ✅ (support override) | ❌ | ✅ all | ❌ (triggered via payment, not direct write) | ❌ | ✅ (cancel own) | ✅ own only |
| Charities list | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ (select for self) | ❌ | ✅ public list |

---

## 6. Content Approval / Moderation Flow (🔵 Recommended — none exists today)

No approval or moderation pipeline exists in the current codebase for any content type. For production, the recommended flow is:

1. **User submits** content (review, comment, post, photo, or — if enabled — a recipe/drink) → row is written with `status = 'pending'` (for content types that require pre-moderation) or `status = 'published'` immediately with post-hoc moderation (for high-volume, low-risk content like comments/likes).
   - 🔵 Recommendation: **pre-moderate** anything with a photo or that becomes catalog content (user-submitted recipes/drinks/places, if built); **post-moderate** (publish immediately, remove-on-report) low-risk items like comments and reactions, to keep the app feeling responsive.
2. **Automated checks** (recommended, not built): basic profanity/spam filtering before anything reaches `pending`.
3. **Admin review queue**: Admin sees all `pending` items, can `approve` (→ `published`), `reject` (→ `rejected`, with an optional reason shown to the user), or edit-and-approve only for structured admin-owned fields (never silently rewrite a user's own words).
4. **Reports**: any published content can be flagged by a user → creates a `reports` row → appears in a separate Admin queue → Admin can `dismiss` or `action` (which removes/hides the content and optionally warns/suspends the user).
5. **Appeals** (🔵 optional): a rejected/removed-content user can contest via support; out of scope unless requested.
6. **Audit trail** (🔵 recommended): every Admin moderation action should be logged (`moderated_by`, `moderated_at`, `action`) for accountability — not just a silent status flip.

---

## 7. Data Ownership Summary

| Owner | Data |
|---|---|
| **Admin** | Catalog content (recipes, drinks, places, menu highlights), categories/tags, featured/trending flags, badge & tier definitions, competitions, charities list, broadcasts, moderation decisions |
| **User (self)** | Their own profile core fields, saved items, meal plans, reviews/comments/posts they authored, their own reports filed, their own subscription record (read-only), their Genie chat history (if built) |
| **System (server-side only, no direct client write)** | XP, badges, streaks, `is_premium`/`user_tier`, subscription status, aggregate ratings computed from reviews, swipe analytics |
| **Shared/public** | Published catalog content, published reviews/comments/posts (minus removed), public profile subset, competitions, events, offers |

---

## 8. Public vs. Private Visibility Summary

| Public (visible to any user) | Private (owner + Admin only) |
|---|---|
| Recipes, drinks, places catalog | Full profile (dob, age_verified, location_granted, email) |
| Published reviews, comments, posts | Saved items / favorites list |
| Public profile subset (name, username, avatar, bio, badges, tier) | Meal plan calendar |
| Competitions, leaderboards (if public), events, offers | Swipes log |
| Charities list | Notifications |
| Admin broadcasts | Reports filed |
| | Subscription/billing details |
| | Genie chat history (if built) |
| | XP/coin balances (recommend: badges/tier public, raw XP number private — TBD with client, marked **Recommended** default) |

---

## 9. Recommended Supabase Structure (Production RLS Pattern)

The concrete fix for Section 0's critical finding:

```sql
-- CONTENT TABLES (recipes, drinks, places, categories, tags, competitions, charities, broadcasts, offers, events)
-- Public read, Admin-only write.
create policy "public_read" on public.recipes for select
  to authenticated, anon using (true);

create policy "admin_write" on public.recipes for insert, update, delete
  to authenticated using (
    exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- USER-OWNED TABLES (profiles, saved_items, meal_plans, swipes, reviews, comments, posts, reports, notifications)
-- Owner-scoped read/write.
create policy "owner_select" on public.saved_items for select
  to authenticated using (auth.uid() = user_id);

create policy "owner_write" on public.saved_items for insert, update, delete
  to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- SYSTEM-ONLY FIELDS (xp, badges, is_premium, streaks on profiles)
-- Block client-side writes to these columns entirely; only a SECURITY DEFINER
-- function (called by server-side game logic / payment webhook) may update them.
-- Recommended: split into a separate `profile_stats` table with NO client
-- write policy at all, updated only via RPC functions.
```

Key recommendations bundled here:

1. Add a real **`is_admin` boolean column** (or a separate `admin_users` table) so RLS policies can actually distinguish Admin from User — this does not exist today.
2. Split **system-controlled profile fields** (xp, badges, streaks, is_premium, user_tier) into a table/column set with **no direct client write policy at all** — mutate only through `SECURITY DEFINER` RPC functions, so a client can never self-grant XP or premium status.
3. Re-enable real **Supabase Auth** (email/OAuth) — the app currently has this wired up in `AuthRepositoryImpl` but no entry screen uses it; the "no-auth" mode was a deliberate prototype shortcut that must be reversed for production.
4. Add **foreign keys** where currently loose (`saved_items.item_id` etc.) or explicitly document the soft-reference pattern as accepted.
5. For any new content type, follow the same two-tier pattern used above: **admin-owned = public-read/admin-write**, **user-owned = owner-scoped**, **moderatable = owner-write + admin-delete**.

---

## 10. Gap Analysis — What's Missing for a Production-Ready App

This list distills every gap called out inline above, plus a few cross-cutting ones, in priority order:

1. **No real authentication.** Highest-priority gap — everything else in this document depends on it.
2. **Open RLS on every table**, including admin-owned content — currently anyone can vandalize the catalog.
3. **No admin role/flag exists anywhere** — there is literally no way today to distinguish an admin user from a regular user in the data model.
4. **No per-recipe ingredients/steps data** — Cook Mode shows one fixed template for every dish regardless of which recipe was opened. This is a functional gap, not just a mock-data one.
5. **No moderation pipeline** for any user-generated content (none currently persists, but this must be designed before any of Section 4.2's social tables go live).
6. **No reports/flagging mechanism.**
7. **Gamification write-back is unverified/unsafe**: XP-granting actions (rating, tipping, voting, competitions) mostly show cosmetic point text with no confirmed persistence, and where persistence exists (Premium purchase), it's via a direct client write to `profiles` rather than a trusted server path.
8. **No payment/subscription validation** — Premium "purchase" is simulated; production needs real App Store/Play Billing/Stripe webhook-driven writes.
9. **No normalized categories/tags table** — free-text strings risk duplicate/inconsistent taxonomy at scale.
10. **No lat/long for places** — "distance" is a static string, not computed from the user's real location despite a `location_granted` flag already existing.
11. **No account-deletion RPC found** (`delete_own_account` is called by the client but not defined in any migration in this repo) — verify it exists server-side or implement it before shipping the "Delete Account" flow.
12. **No business/restaurant-owner account type** — if restaurants should ever manage their own listing, this entire tier is unbuilt.
13. **No orders/bookings/reservations subsystem** — delivery and reservation UI is fully cosmetic today.
14. **No analytics consumption** of the `swipes` table — it's being written but never read; Admin has no dashboard to use this data for merchandising/recommendations.
15. **No audit log** for Admin actions (moderation, content edits, support overrides).

---

## 11. Open Questions for the Client (Marked Explicitly — Not Assumed)

These decisions materially change the schema and should be confirmed, not assumed, before implementation:

- **Q1:** Should regular users ever be able to submit new recipes/drinks/places (with Admin approval), or is the catalog Admin-only forever? *(The UI hints at user-generated content via the "Create" screen, but this may just be prototype scaffolding.)*
- **Q2:** Should raw XP numbers be public on other users' profiles, or only the derived tier/badges? *(Recommended default in this doc: badges/tier public, raw XP private — pending confirmation.)*
- **Q3:** Are restaurant/business-owner accounts in scope for this version, or a future phase?
- **Q4:** Is real ordering/reservation integration in scope, or is the current cosmetic UI intentionally a placeholder for a future partnership?
- **Q5:** What is the intended moderation SLA/team size — does Admin tooling need to support multiple moderators with role-based permissions, or a single owner-admin?
- **Q6:** Should user-submitted reviews/photos be pre-moderated (held until approved) or post-moderated (live immediately, removed on report)? *(Recommended default in this doc: post-moderate low-risk content, pre-moderate anything with photos or catalog-affecting submissions — pending confirmation.)*

---

*Document generated from a full review of the Flutter client (`lib/`) and Supabase backend (`supabase/`) as of the current repository state on the `blot_new_change` branch. All 🔵 "Recommended" items are proposals for the client's consideration, not confirmed requirements.*
