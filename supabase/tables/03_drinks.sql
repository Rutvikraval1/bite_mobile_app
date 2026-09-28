-- ═══════════════════════════════════════════════════════════════
-- public.drinks — drink recipe cards (swipe deck, Drinks tab)
-- Final effective state (see ../migrations/ for history).
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.drinks (
  id integer primary key,
  title text not null,
  creator text not null default '@bite',
  time_min text not null default '',
  difficulty text not null default 'Easy',
  serves integer not null default 1,
  heat_level integer not null default 0,
  saved_count text not null default '0',
  hearts_count text not null default '0',
  comments_count integer not null default 0,
  emoji text not null default '🍹',
  image_url text,
  cuisine text,
  gradient text not null default 'linear-gradient(135deg, #0A0010 0%, #1A0030 100%)',
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.drinks enable row level security;

drop policy if exists "Drinks are readable by authenticated users" on public.drinks;
drop policy if exists "auth_select_drinks" on public.drinks;
drop policy if exists "anon_select_drinks" on public.drinks;
drop policy if exists "anon_insert_drinks" on public.drinks;
drop policy if exists "anon_update_drinks" on public.drinks;
drop policy if exists "anon_delete_drinks" on public.drinks;

-- No-auth app: content is public/shared, anon key is used exclusively.
create policy "anon_select_drinks" on public.drinks for select
  to anon, authenticated using (true);
create policy "anon_insert_drinks" on public.drinks for insert
  to anon, authenticated with check (true);
create policy "anon_update_drinks" on public.drinks for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_drinks" on public.drinks for delete
  to anon, authenticated using (true);
