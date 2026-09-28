# seed_data/

Seed content for `public.recipes`, `public.drinks`, and `public.places` —
the catalog shown in the swipe decks. Run after every file in `../tables/`
has been applied.

Each statement upserts by `id` (`on conflict (id) do update set ...`), so
these files are safe to re-run any time the content needs refreshing —
existing rows are updated in place rather than duplicated or skipped.

| File | Table | Rows |
|---|---|---|
| `01_recipes_seed.sql` | `public.recipes` | 20 |
| `02_drinks_seed.sql` | `public.drinks` | 12 |
| `03_places_seed.sql` | `public.places` | 6 |

This mirrors `../seed.sql` at the repo root (kept as-is for the Supabase
CLI's `supabase db reset` seeding step) — split per table here so a single
catalog can be reviewed or re-run on its own.
