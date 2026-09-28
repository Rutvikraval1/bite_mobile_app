/*
# Fix RLS Policies for No-Auth App

## Problem
All 7 tables had RLS enabled with policies scoped to `TO authenticated` only.
This app has no sign-in screen, so the frontend uses the anon key exclusively.
With authenticated-only policies, every query returns zero rows — the app
would see an empty database despite 20 recipes, 12 drinks, and 6 places
being seeded.

## Changes
1. Content tables (recipes, drinks, places):
   - Replace authenticated-only SELECT with anon+authenticated SELECT (public read)
   - Add anon+authenticated INSERT/UPDATE/DELETE (content management)
2. User-data tables (saved_items, swipes, meal_plans, profiles):
   - Replace authenticated-only CRUD with anon+authenticated CRUD
   - Single-tenant: all data is shared (no user isolation without auth)
   - user_id columns remain but are nullable for anon sessions

## Security Notes
- This is a single-tenant app with no sign-in screen.
- USING (true) is acceptable because all data is intentionally shared/public.
- When auth is added later, these policies should be tightened to ownership checks.
*/

-- ── recipes ──
DROP POLICY IF EXISTS "auth_select_recipes" ON recipes;
CREATE POLICY "anon_select_recipes" ON recipes FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_recipes" ON recipes FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_recipes" ON recipes FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_recipes" ON recipes FOR DELETE
  TO anon, authenticated USING (true);

-- ── drinks ──
DROP POLICY IF EXISTS "auth_select_drinks" ON drinks;
CREATE POLICY "anon_select_drinks" ON drinks FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_drinks" ON drinks FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_drinks" ON drinks FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_drinks" ON drinks FOR DELETE
  TO anon, authenticated USING (true);

-- ── places ──
DROP POLICY IF EXISTS "auth_select_places" ON places;
CREATE POLICY "anon_select_places" ON places FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_places" ON places FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_places" ON places FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_places" ON places FOR DELETE
  TO anon, authenticated USING (true);

-- ── saved_items ──
DROP POLICY IF EXISTS "select_own_saved" ON saved_items;
DROP POLICY IF EXISTS "insert_own_saved" ON saved_items;
DROP POLICY IF EXISTS "update_own_saved" ON saved_items;
DROP POLICY IF EXISTS "delete_own_saved" ON saved_items;
CREATE POLICY "anon_select_saved" ON saved_items FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_saved" ON saved_items FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_saved" ON saved_items FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_saved" ON saved_items FOR DELETE
  TO anon, authenticated USING (true);

-- ── swipes ──
DROP POLICY IF EXISTS "select_own_swipes" ON swipes;
DROP POLICY IF EXISTS "insert_own_swipes" ON swipes;
CREATE POLICY "anon_select_swipes" ON swipes FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_swipes" ON swipes FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_swipes" ON swipes FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_swipes" ON swipes FOR DELETE
  TO anon, authenticated USING (true);

-- ── meal_plans ──
DROP POLICY IF EXISTS "select_own_meals" ON meal_plans;
DROP POLICY IF EXISTS "insert_own_meals" ON meal_plans;
DROP POLICY IF EXISTS "update_own_meals" ON meal_plans;
DROP POLICY IF EXISTS "delete_own_meals" ON meal_plans;
CREATE POLICY "anon_select_meals" ON meal_plans FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_meals" ON meal_plans FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_meals" ON meal_plans FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_meals" ON meal_plans FOR DELETE
  TO anon, authenticated USING (true);

-- ── profiles ──
DROP POLICY IF EXISTS "select_own_profile" ON profiles;
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "update_own_profile" ON profiles;
DROP POLICY IF EXISTS "delete_own_profile" ON profiles;
CREATE POLICY "anon_select_profiles" ON profiles FOR SELECT
  TO anon, authenticated USING (true);
CREATE POLICY "anon_insert_profiles" ON profiles FOR INSERT
  TO anon, authenticated WITH CHECK (true);
CREATE POLICY "anon_update_profiles" ON profiles FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "anon_delete_profiles" ON profiles FOR DELETE
  TO anon, authenticated USING (true);
