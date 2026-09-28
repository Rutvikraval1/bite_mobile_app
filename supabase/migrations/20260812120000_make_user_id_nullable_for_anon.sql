/*
# Make user_id nullable for anon sessions

## Why
The RLS fix migration (20260812054840_fix_rls_for_no_auth_app.sql) opened all
user-data tables to the anon key, but the columns were never actually made
nullable — they remain `NOT NULL DEFAULT auth.uid()`. For anonymous sessions
`auth.uid()` is NULL, so every swipe / save / meal-plan insert failed with a
NOT NULL violation and was silently swallowed.

## Changes
Drop NOT NULL on the owner columns of the three user-data tables written by the
frontend. `DEFAULT auth.uid()` stays, so authenticated users still get their own
id automatically; anon sessions now store NULL (single-tenant, shared data).

When real per-user auth is enforced later, ownership policies should be
re-tightened (see the RLS fix migration notes).
*/

ALTER TABLE public.saved_items ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.meal_plans ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.swipes ALTER COLUMN user_id DROP NOT NULL;
