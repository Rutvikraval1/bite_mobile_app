-- ═══════════════════════════════════════════════════════════════
-- public.recipes — food recipe cards (swipe deck, Food tab)
-- Final effective state (see ../migrations/ for history).
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.recipes (
  id integer primary key,
  title text not null,
  creator text not null default '@bite',
  time_min text not null default '',
  difficulty text not null default 'Easy',
  serves integer not null default 2,
  heat_level integer not null default 0,
  saved_count text not null default '0',
  hearts_count text not null default '0',
  comments_count integer not null default 0,
  emoji text not null default '🍽',
  image_url text,
  cuisine text not null default 'Various',
  gradient text not null default 'linear-gradient(135deg, #0A0A0F 0%, #12121A 100%)',
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.recipes enable row level security;

drop policy if exists "Recipes are readable by authenticated users" on public.recipes;
drop policy if exists "auth_select_recipes" on public.recipes;
drop policy if exists "anon_select_recipes" on public.recipes;
drop policy if exists "anon_insert_recipes" on public.recipes;
drop policy if exists "anon_update_recipes" on public.recipes;
drop policy if exists "anon_delete_recipes" on public.recipes;

-- No-auth app: content is public/shared, anon key is used exclusively.
create policy "anon_select_recipes" on public.recipes for select
  to anon, authenticated using (true);
create policy "anon_insert_recipes" on public.recipes for insert
  to anon, authenticated with check (true);
create policy "anon_update_recipes" on public.recipes for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_recipes" on public.recipes for delete
  to anon, authenticated using (true);
