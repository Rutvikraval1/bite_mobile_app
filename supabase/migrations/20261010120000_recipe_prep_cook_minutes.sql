-- Store prep and cook time separately so the recipe editor can round-trip
-- them. `time_min` keeps the display total (e.g. "40 min").
alter table public.recipes
  add column if not exists prep_min integer check (prep_min >= 0),
  add column if not exists cook_min integer check (cook_min >= 0);
