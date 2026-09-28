# tables/

Clean, single-purpose reference of the **final effective schema** — what the
database actually looks like today, after every incremental migration in
`../migrations/` has been applied and superseded earlier statements.

This is not a new source of truth. `../migrations/` (run in order by the
Supabase CLI) remains authoritative for deploys. These files exist so the
whole schema for one table — columns, indexes, RLS policies, triggers — can
be read or re-run from a single place instead of tracing it across six
migration files.

Every statement is idempotent (`create table if not exists`,
`drop policy if exists` + `create policy`, `create index if not exists`), so
each file is safe to run standalone against a fresh database, in the order
of the filename prefixes:

| File | Table |
|---|---|
| `01_profiles.sql` | `public.profiles` |
| `02_recipes.sql` | `public.recipes` |
| `03_drinks.sql` | `public.drinks` |
| `04_places.sql` | `public.places` |
| `05_saved_items.sql` | `public.saved_items` |
| `06_meal_plans.sql` | `public.meal_plans` |
| `07_swipes.sql` | `public.swipes` |
| `08_functions_triggers.sql` | `handle_new_user`, `set_updated_at` + their triggers |

## Notes on the current (no-auth) security model

This app has no sign-in screen — the Flutter client uses the Supabase
**anon** key exclusively. Every table's RLS policies grant full
`select/insert/update/delete` to `anon, authenticated` with `using (true)`.
This is a deliberate single-tenant, shared-data setup (see
`../migrations/20260812054840_fix_rls_for_no_auth_app.sql`), not an
oversight. `user_id` columns on `saved_items`, `meal_plans`, and `swipes`
are nullable with no default — anon sessions store `NULL`.

When real per-user auth is added, tighten these policies back to
`auth.uid() = user_id` / `auth.uid() = id` ownership checks.
