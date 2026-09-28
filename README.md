# b🌶te — Food Discovery App

> **swipe. taste. share.**

b🌶te is a dark-mode food discovery app built with Flutter and backed by Supabase. Users swipe through a deck of recipes, drinks and places, save the ones they like, plan meals, cook step by step, and earn XP and badges along the way. It also includes a social feed, chat, and an AI-style "Genie" assistant for meal ideas.

This repository is the **Flutter port of the interactive web prototype**. Version: `0.1.0+1` (prototype).

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Status: Real vs. Mock Data](#project-status-real-vs-mock-data)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Backend (Supabase)](#backend-supabase)
- [Security Notes](#security-notes)
- [Further Documentation](#further-documentation)

---

## Features

| Area | What it does |
|---|---|
| **Onboarding** | Splash, welcome gate, sign-in (email, Google, Apple), profile setup, cuisine / dietary / skill-level preferences, gamification tutorial, and an age gate for drinks content. |
| **Swipe Deck (Home)** | Tinder-style card deck of recipes, drinks and places. Includes XP progress bar, streaks, daily reward chest and a quick meal-planner sheet. |
| **Content Details** | Recipe detail and place detail screens with comments. |
| **Cook Mode** | Step-by-step guided cooking, followed by a post-cook summary screen. |
| **Genie Assistant** | Chat, filters, meal builder, weekly planner, meal pairings and ingredient "scan". |
| **Social** | Social feed, chat list and threads, creator profiles, notifications, share sheet, comments and quick-rate sheets. |
| **Profile** | Profile, edit profile, saved items, settings, premium upgrade, community impact, competitions, Elo "Top Dish" voting and creator content creation. |
| **Gamification** | XP tiers (Curious → b🌶te Legend), badges (First Bite, Week Warrior, Streak Legend and more), cooking levels, tipping and meal reminders. |

### XP Tiers

| Level | Tier | XP range |
|---|---|---|
| 1 | 👀 Curious | 0 – 9 |
| 2 | 🥄 Beginner | 10 – 29 |
| 3 | 🍳 Home Cook | 30 – 74 |
| 4 | 🧑‍🍳 Sous Chef | 75 – 149 |
| 5 | 👨‍🍳 Chef | 150 – 299 |
| 6 | ⭐ Master Chef | 300 – 599 |
| 7 | 🔥 b🌶te Legend | 600+ |

Defined in [lib/core/constants/tier_definitions.dart](lib/core/constants/tier_definitions.dart). Badges are defined in [lib/core/constants/badge_catalog.dart](lib/core/constants/badge_catalog.dart).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK `^3.11.0`) |
| Backend | [Supabase](https://supabase.com) (Postgres, Auth, RLS) via `supabase_flutter` |
| State management | `flutter_bloc` (Cubits) + `equatable` |
| Config | `flutter_dotenv` + `--dart-define-from-file` |
| Storage | `flutter_secure_storage` |
| UI | Material 3 dark theme, `google_fonts`, `cached_network_image` |
| Utilities | `url_launcher`, `intl`, `get_it` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |
| Linting | `flutter_lints` |

Supported platforms: **Android, iOS, Web, macOS, Windows, Linux**. The UI is designed for a phone-sized frame (max width 430 px); on wide screens it is shown in a centered, rounded frame.

---

## Project Status: Real vs. Mock Data

This is a **prototype**. Some features are connected to Supabase; others are UI-only with hardcoded data.

**Connected to Supabase (real data):**
- User profiles (including premium flag and tier)
- Recipes, drinks and places catalogs
- Saved items
- Meal plans
- Swipe log

**UI only (mock / local data, not saved to a server):**
- Social feed, comments, likes, chat and notifications
- Reviews, competitions and Elo voting
- Community impact / donations and tipping
- Creator content publishing
- Genie chat, planner and scan (canned responses — no real AI backend)
- Delivery / reservation links (DoorDash, Uber Eats, OpenTable, etc.)

For the full breakdown, see [ADMIN_VS_USER_DATA_SPECIFICATION.md](ADMIN_VS_USER_DATA_SPECIFICATION.md).

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart `3.11` or newer (check with `flutter --version`)
- A Supabase project (URL and anon key)
- Platform tooling for your target:
  - **Android:** Android Studio + Android SDK
  - **iOS / macOS:** Xcode + CocoaPods
  - **Web:** Chrome
- Optional: [Supabase CLI](https://supabase.com/docs/guides/cli) to manage the database

### Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd bite_mobile_app

# 2. Install dependencies
flutter pub get

# 3. Create your .env file (see below)

# 4. Run the app
flutter run --dart-define-from-file=.env
```

---

## Environment Variables

Create a file named `.env` in the project root:

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

| Variable | Required | Description |
|---|---|---|
| `SUPABASE_URL` | Yes | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Your Supabase public (anon) key |
| `DEMO_KEY` | No | Key for the demo unlock gate. Defaults to `bite.me2026` |

**Important:**
- The `.env` file **must exist** before building. It is listed as an asset in `pubspec.yaml`, so the build fails without it.
- `.env` is in `.gitignore`. **Never commit it.**
- Only use the **anon** key. Never put the Supabase `service_role` key in the app.

### How config is loaded

[lib/core/config/app_env.dart](lib/core/config/app_env.dart) reads values from two places:

1. **Build time:** `--dart-define-from-file=.env` (this wins if present)
2. **Runtime:** the `.env` file bundled as an asset (fallback, so the app still works if your IDE doesn't pass the flag)

If the values are missing, the app shows a **"Supabase isn't configured"** screen with a Retry button.

---

## Running the App

```bash
# Default device
flutter run --dart-define-from-file=.env

# A specific platform
flutter run -d chrome  --dart-define-from-file=.env
flutter run -d ios     --dart-define-from-file=.env
flutter run -d android --dart-define-from-file=.env
flutter run -d macos   --dart-define-from-file=.env
```

**VS Code:** a launch configuration named **`bite`** is included in [.vscode/launch.json](.vscode/launch.json). It already passes `--dart-define-from-file=.env`. Press `F5` to run.

### Release builds

```bash
flutter build apk       --dart-define-from-file=.env   # Android APK
flutter build appbundle --dart-define-from-file=.env   # Android App Bundle
flutter build ios       --dart-define-from-file=.env   # iOS
flutter build web       --dart-define-from-file=.env   # Web
```

---

## Running Tests

```bash
flutter test                  # run all tests
flutter test test/core        # run one folder
flutter analyze               # static analysis / lint
```

Current tests cover env config, app startup, failures, screen routing (`AppScreen`, `FlowCubit`) and the swipe deck screen. See the [test/](test/) folder.

---

## Project Structure

```
bite_mobile_app/
├── lib/
│   ├── main.dart                 # Entry point: loads .env, validates config, runs app
│   ├── app.dart                  # Root widget, Supabase init, BlocProviders, screen router
│   ├── core/
│   │   ├── config/               # AppConfig, AppEnv (env variables)
│   │   ├── constants/            # Table names, XP tiers, badge catalog
│   │   ├── errors/               # AppException, Failure
│   │   ├── extensions/           # BuildContext and String helpers
│   │   ├── network/              # Supabase client provider, DataResult
│   │   ├── router/               # AppScreen enum, FlowCubit (navigation)
│   │   ├── services/             # Badges, haptics, premium gate, toasts, XP float
│   │   ├── state/                # Global app state (AppStateCubit)
│   │   ├── theme/                # Dark theme and colors
│   │   ├── utils/                # Formatters, validators, debouncer, scaling
│   │   └── widgets/              # Shared widgets: nav bar, glass, overlays, animations
│   └── features/
│       ├── auth/                 # Sign-in, sign-up, onboarding, profile setup
│       ├── content/              # Recipes, drinks, places, saved items, meal plans
│       ├── cooking/              # Cook mode and post-cook
│       ├── gamification/         # Cooking level, tips, meal reminders
│       ├── genie/                # Genie assistant (chat, planner, scan, meal builder)
│       ├── home/                 # Swipe deck, streaks, daily chest, XP bar
│       ├── profile/              # Profile, settings, premium, competitions, voting
│       └── social/               # Feed, chat, creators, notifications, sharing
├── supabase/                     # Database migrations, schema reference, seed data
├── test/                         # Unit and widget tests
├── android/ ios/ web/            # Platform projects
├── macos/ windows/ linux/
├── ADMIN_VS_USER_DATA_SPECIFICATION.md
└── pubspec.yaml
```

Each feature follows a layered layout where needed:

```
features/<feature>/
├── data/           # Repository implementations, mappers, seed/mock data
├── domain/         # Entities and repository interfaces
└── presentation/   # Cubits, screens, widgets
```

---

## Architecture

### Startup flow

1. [main.dart](lib/main.dart) loads `.env` and validates config.
2. [app.dart](lib/app.dart) initializes Supabase and shows a boot screen (🌶).
   - On failure → config error screen with **Retry**.
   - On success → `BiteShell` is mounted.
3. `BiteShell` provides the global Cubits:
   - **`AuthCubit`** — session, sign-in/sign-out, profile
   - **`ContentCubit`** — recipes, drinks, places, saved items, meal plans
   - **`AppStateCubit`** — XP, streaks, preferences, premium state
   - **`FlowCubit`** — which screen is showing

### Navigation

The app does **not** use `Navigator` routes. Navigation is state-driven:

- Every screen is a value in the `AppScreen` enum ([lib/core/router/app_screen.dart](lib/core/router/app_screen.dart)).
- `FlowCubit` holds the current screen and history, and plays a short fade transition between screens.
- `_screenFor()` in [app.dart](lib/app.dart) maps each `AppScreen` to its widget.

This mirrors the original web prototype's `setScreen("name")` routing.

### Auth-driven routing

- After sign-in: no profile yet → **Profile Setup**; profile exists → **Swipe Deck**.
- After sign-out: app state resets to guest → **Auth** screen.

### Global overlays

Toasts, floating "+XP" animations and the screen transition fade are drawn on top of every screen.

---

## Backend (Supabase)

All backend files are in [supabase/](supabase/). See [supabase/README.md](supabase/README.md).

| Folder / file | Purpose |
|---|---|
| `migrations/` | Ordered migrations applied by the Supabase CLI. **This is the source of truth.** |
| `seed.sql` | Seed script used by `supabase db reset` |
| `tables/` | Clean per-table reference of the final schema (columns, indexes, RLS, triggers) |
| `seed_data/` | Seed content split into one file per table (recipes, drinks, places) |

### Database tables

| Table | Description |
|---|---|
| `profiles` | One row per user (name, preferences, XP, premium flag, tier) |
| `recipes` | Recipe catalog |
| `drinks` | Drinks catalog |
| `places` | Restaurants / places catalog |
| `saved_items` | Items a user saved |
| `meal_plans` | User's meal plan calendar |
| `swipes` | Swipe history log |

Table names used by the app are defined in [lib/core/constants/table_names.dart](lib/core/constants/table_names.dart). That file also lists names for future tables (feed posts, messages, competitions, etc.) that **do not exist yet**.

### Setting up the database

```bash
# Link to your Supabase project
supabase link --project-ref <your-project-ref>

# Apply migrations
supabase db push

# Reset a local database and apply seed data
supabase db reset
```

---

## Security Notes

⚠️ **This is a prototype. Do not ship it to production as-is.**

- All tables have Row Level Security **enabled but fully open** (`using (true)`) for `anon` and `authenticated`. Any client can read and write any row. This was done on purpose for the prototype (see migration `20260812054840_fix_rls_for_no_auth_app.sql`).
- **Before production**, tighten RLS:
  - Content tables (`recipes`, `drinks`, `places`): read-only for users, write for admins only.
  - User tables (`profiles`, `saved_items`, `meal_plans`, `swipes`): restrict to the owner with `auth.uid() = user_id` (or `auth.uid() = id` for `profiles`).
- Only the public anon key is used in the app. RLS is the real security boundary.
- The `delete_own_account` RPC is called by the app but is not defined in the migrations in this repo.

Section 9 of [ADMIN_VS_USER_DATA_SPECIFICATION.md](ADMIN_VS_USER_DATA_SPECIFICATION.md) has the recommended RLS policies.

---

## Further Documentation

- [ADMIN_VS_USER_DATA_SPECIFICATION.md](ADMIN_VS_USER_DATA_SPECIFICATION.md) — who creates, owns, sees and edits each type of data; real vs. mock features; gap analysis for production
- [supabase/README.md](supabase/README.md) — backend folder overview
- [supabase/tables/README.md](supabase/tables/README.md) — schema reference and current security model
- [supabase/seed_data/README.md](supabase/seed_data/README.md) — seed data details
