/*
  # Genie filters → profiles

  Persists the Genie smart-filter sheet per user. One JSON object per deck
  kind, e.g.

    {
      "food":   {"vibes": ["Healthy"], "cuisines": ["Korean"],
                 "dietary": ["Vegetarian"], "difficulty": [],
                 "max_minutes": 30, "max_heat": 2},
      "drinks": {"vibes": ["Party"], "dietary": ["Non-Alcoholic"], ...}
    }

  NULL means the user has never saved (or has reset) their filters.

  RLS: covered by the existing "profiles_update_own" policy
  (20260930120000_profile_production.sql) — users can only update their own
  row. Reads use "profiles_select".

  Idempotent — safe to re-run.
*/

alter table public.profiles
  add column if not exists genie_filters jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_genie_filters_object'
  ) then
    alter table public.profiles
      add constraint profiles_genie_filters_object
      check (genie_filters is null or jsonb_typeof(genie_filters) = 'object');
  end if;
end $$;
