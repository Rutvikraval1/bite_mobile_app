/*
# b🌶te — Full Database Schema for Dynamic Flow

## Overview
Connects all pages of the b🌶te food discovery app to Supabase.
Replaces hardcoded in-memory arrays (recipes, drinks, places) with database tables,
and persists per-user state (profile, saved items, meal plans, swipes).

## New Tables

### Content tables (shared, read by all authenticated users)
1. `recipes` — food recipe cards shown in the swipe deck (Food tab)
   - id, title, creator, time_min, difficulty, serves, heat_level, saved_count, hearts_count, comments_count, emoji, image_url, cuisine, gradient, tags (text[]), created_at

2. `drinks` — drink recipe cards shown in the swipe deck (Drinks tab)
   - id, title, creator, time_min, difficulty, serves, heat_level, saved_count, hearts_count, comments_count, emoji, image_url, cuisine, gradient, tags (text[]), created_at

3. `places` — restaurant/venue cards shown in the swipe deck (Places tab)
   - id, title, creator, price_level, cuisine, saved_count, hearts_count, comments_count, emoji, image_url, gradient, address, phone, rating, review_count, hours, status, distance, photos (text[]), tags (text[]), menu_highlights (jsonb), created_at

### User-specific tables (owner-scoped via RLS)
4. `profiles` — per-user profile data, extends auth.users
   - id (FK auth.users), display_name, username, bio, avatar_emoji, dob, xp, bite_coins, streak_count, longest_streak, streak_multiplier, streak_freezes, daily_chest_claimed, is_premium, user_tier, cuisines (text[]), dietary (text[]), badges (text[]), age_verified, location_granted, created_at, updated_at

5. `saved_items` — recipes/drinks/places a user has saved (swiped up)
   - id, user_id, item_type ('recipe'|'drink'|'place'), item_id, title, emoji, image_url, cuisine, created_at

6. `meal_plans` — meal planner calendar entries
   - id, user_id, plan_date, meal_slot ('breakfast'|'lunch'|'dinner'|'dessert'), title, emoji, color, created_at

7. `swipes` — swipe interaction log (for tracking engagement, cuisine discovery, milestones)
   - id, user_id, item_type, item_id, action ('save'|'pass'), cuisine, created_at

## Security
- Content tables (recipes, drinks, places): RLS enabled, SELECT for authenticated (shared content). INSERT/UPDATE/DELETE blocked (admin-managed content).
- User tables (profiles, saved_items, meal_plans, swipes): RLS enabled, full CRUD scoped to auth.uid() = user_id.
- All owner columns default to auth.uid() so inserts that omit user_id succeed.
*/

-- ═══ CONTENT TABLES ═══

CREATE TABLE IF NOT EXISTS recipes (
  id int PRIMARY KEY,
  title text NOT NULL,
  creator text NOT NULL,
  time_min text NOT NULL,
  difficulty text NOT NULL DEFAULT 'Easy',
  serves int NOT NULL DEFAULT 2,
  heat_level int NOT NULL DEFAULT 0,
  saved_count text NOT NULL DEFAULT '0',
  hearts_count text NOT NULL DEFAULT '0',
  comments_count int NOT NULL DEFAULT 0,
  emoji text NOT NULL DEFAULT '🍽',
  image_url text,
  cuisine text NOT NULL DEFAULT 'Various',
  gradient text NOT NULL,
  tags text[] NOT NULL DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_recipes" ON recipes;
CREATE POLICY "auth_select_recipes" ON recipes FOR SELECT TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS drinks (
  id int PRIMARY KEY,
  title text NOT NULL,
  creator text NOT NULL,
  time_min text NOT NULL,
  difficulty text NOT NULL DEFAULT 'Easy',
  serves int NOT NULL DEFAULT 1,
  heat_level int NOT NULL DEFAULT 0,
  saved_count text NOT NULL DEFAULT '0',
  hearts_count text NOT NULL DEFAULT '0',
  comments_count int NOT NULL DEFAULT 0,
  emoji text NOT NULL DEFAULT '🍸',
  image_url text,
  cuisine text,
  gradient text NOT NULL,
  tags text[] NOT NULL DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE drinks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_drinks" ON drinks;
CREATE POLICY "auth_select_drinks" ON drinks FOR SELECT TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS places (
  id int PRIMARY KEY,
  title text NOT NULL,
  creator text NOT NULL,
  price_level text NOT NULL DEFAULT '$$',
  cuisine text NOT NULL DEFAULT 'Various',
  saved_count text NOT NULL DEFAULT '0',
  hearts_count text NOT NULL DEFAULT '0',
  comments_count int NOT NULL DEFAULT 0,
  emoji text NOT NULL DEFAULT '📍',
  image_url text,
  gradient text NOT NULL,
  address text NOT NULL DEFAULT '',
  phone text NOT NULL DEFAULT '',
  rating numeric NOT NULL DEFAULT 4.5,
  review_count int NOT NULL DEFAULT 0,
  hours text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'Open now',
  distance text NOT NULL DEFAULT '',
  photos text[] NOT NULL DEFAULT '{}',
  tags text[] NOT NULL DEFAULT '{}',
  menu_highlights jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_places" ON places;
CREATE POLICY "auth_select_places" ON places FOR SELECT TO authenticated USING (true);

-- ═══ USER-SPECIFIC TABLES ═══

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT '',
  username text NOT NULL DEFAULT '',
  bio text NOT NULL DEFAULT '',
  avatar_emoji text NOT NULL DEFAULT '🧑‍🍳',
  dob date,
  xp int NOT NULL DEFAULT 0,
  bite_coins int NOT NULL DEFAULT 0,
  streak_count int NOT NULL DEFAULT 0,
  longest_streak int NOT NULL DEFAULT 0,
  streak_multiplier numeric NOT NULL DEFAULT 1.0,
  streak_freezes int NOT NULL DEFAULT 0,
  daily_chest_claimed boolean NOT NULL DEFAULT false,
  is_premium boolean NOT NULL DEFAULT false,
  user_tier text NOT NULL DEFAULT 'free',
  cuisines text[] NOT NULL DEFAULT '{}',
  dietary text[] NOT NULL DEFAULT '{}',
  badges text[] NOT NULL DEFAULT '{}',
  age_verified boolean NOT NULL DEFAULT false,
  location_granted boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_profile" ON profiles;
CREATE POLICY "select_own_profile" ON profiles FOR SELECT TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
CREATE POLICY "insert_own_profile" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "update_own_profile" ON profiles;
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "delete_own_profile" ON profiles;
CREATE POLICY "delete_own_profile" ON profiles FOR DELETE TO authenticated USING (auth.uid() = id);

CREATE TABLE IF NOT EXISTS saved_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type text NOT NULL,
  item_id int NOT NULL,
  title text NOT NULL,
  emoji text NOT NULL DEFAULT '🍽',
  image_url text,
  cuisine text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE saved_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_saved" ON saved_items;
CREATE POLICY "select_own_saved" ON saved_items FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_saved" ON saved_items;
CREATE POLICY "insert_own_saved" ON saved_items FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_saved" ON saved_items;
CREATE POLICY "update_own_saved" ON saved_items FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_saved" ON saved_items;
CREATE POLICY "delete_own_saved" ON saved_items FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_saved_items_user ON saved_items(user_id);

CREATE TABLE IF NOT EXISTS meal_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_date date NOT NULL,
  meal_slot text NOT NULL,
  title text NOT NULL,
  emoji text NOT NULL DEFAULT '🍽',
  color text NOT NULL DEFAULT '#FF6B6B',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_meals" ON meal_plans;
CREATE POLICY "select_own_meals" ON meal_plans FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_meals" ON meal_plans;
CREATE POLICY "insert_own_meals" ON meal_plans FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_meals" ON meal_plans;
CREATE POLICY "update_own_meals" ON meal_plans FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_meals" ON meal_plans;
CREATE POLICY "delete_own_meals" ON meal_plans FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date ON meal_plans(user_id, plan_date);

CREATE TABLE IF NOT EXISTS swipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type text NOT NULL,
  item_id int NOT NULL,
  action text NOT NULL,
  cuisine text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_swipes" ON swipes;
CREATE POLICY "select_own_swipes" ON swipes FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_swipes" ON swipes;
CREATE POLICY "insert_own_swipes" ON swipes FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_swipes" ON swipes;
CREATE POLICY "delete_own_swipes" ON swipes FOR DELETE TO authenticated USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_swipes_user ON swipes(user_id);

-- ═══ AUTO-CREATE PROFILE ON SIGNUP ═══
-- When a new auth.users row is created, automatically create a profiles row
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', ''), COALESCE(NEW.raw_user_meta_data->>'username', ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();