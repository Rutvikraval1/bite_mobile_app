-- ═══════════════════════════════════════════════════════════════
-- public.places — restaurant/venue cards (swipe deck, Places tab)
-- Final effective state (see ../migrations/ for history).
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.places (
  id integer primary key,
  title text not null,
  creator text not null default '@bite',
  price_level text not null default '$',
  cuisine text not null default 'Various',
  saved_count text not null default '0',
  hearts_count text not null default '0',
  comments_count integer not null default 0,
  emoji text not null default '🏠',
  image_url text,
  gradient text not null default 'linear-gradient(135deg, #0A0A1A 0%, #1A0030 100%)',
  address text not null default '',
  phone text not null default '',
  rating numeric not null default 4.5,
  review_count integer not null default 0,
  hours text not null default '',
  status text not null default 'Open now',
  distance text not null default '',
  photos text[] not null default '{}',
  tags text[] not null default '{}',
  menu_highlights jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.places enable row level security;

drop policy if exists "Places are readable by authenticated users" on public.places;
drop policy if exists "auth_select_places" on public.places;
drop policy if exists "anon_select_places" on public.places;
drop policy if exists "anon_insert_places" on public.places;
drop policy if exists "anon_update_places" on public.places;
drop policy if exists "anon_delete_places" on public.places;

-- No-auth app: content is public/shared, anon key is used exclusively.
create policy "anon_select_places" on public.places for select
  to anon, authenticated using (true);
create policy "anon_insert_places" on public.places for insert
  to anon, authenticated with check (true);
create policy "anon_update_places" on public.places for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_places" on public.places for delete
  to anon, authenticated using (true);
