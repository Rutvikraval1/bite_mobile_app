# supabase/

Backend for the b🌶te app (shared by `bite_flutter` and the web prototype
in `../src`).

- **`migrations/`** — timestamped, ordered migrations. This is what the
  Supabase CLI applies (`supabase db push` / `supabase migration up`) and
  is the authoritative history of how the schema got to its current state.
- **`seed.sql`** — root-level seed script used by `supabase db reset`.
- **`tables/`** — a clean, per-table reference of the schema's *final
  effective state* (all 7 tables' columns, indexes, RLS policies, and
  triggers), for reading or re-running one table at a time without tracing
  it across the migration history. See `tables/README.md`.
- **`seed_data/`** — the same seed content as `seed.sql`, split into one
  idempotent upsert file per table. See `seed_data/README.md`.

Verified against `bite_flutter`'s actual Supabase usage (`lib/core/constants/table_names.dart`
and the `content`/`auth` repositories) — every table and column the app
reads or writes is covered.
