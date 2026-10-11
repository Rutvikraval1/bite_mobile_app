/*
  # XP level ladder → database

  The level names, emojis, colours and XP thresholds used to be hardcoded
  in the app (and duplicated in places). They now live here so they can
  be changed without an app release. The app loads them at startup, caches
  them on the device, and falls back to its built-in copy if offline.

  A level runs from its min_xp up to the next level's min_xp.

  Idempotent — safe to re-run (existing rows are left as edited).
*/

create table if not exists public.xp_tiers (
  level integer primary key check (level >= 1),
  name text not null check (char_length(trim(name)) between 1 and 40),
  emoji text not null default '⭐',
  min_xp integer not null unique check (min_xp >= 0),
  color text not null default '#FF6B6B' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  updated_at timestamptz not null default now()
);

alter table public.xp_tiers enable row level security;

-- Read-only for the app (signed in or not); edit from the dashboard.
drop policy if exists "xp_tiers_select" on public.xp_tiers;
create policy "xp_tiers_select" on public.xp_tiers for select
  to anon, authenticated using (true);

insert into public.xp_tiers (level, name, emoji, min_xp, color) values
  (1, 'Curious',       '👀',   0,   '#64B5F6'),
  (2, 'Beginner',      '🥄',   10,  '#4CAF50'),
  (3, 'Home Cook',     '🍳',   30,  '#FF6B6B'),
  (4, 'Sous Chef',     '🧑‍🍳', 75,  '#9B59B6'),
  (5, 'Chef',          '👨‍🍳', 150, '#F5A623'),
  (6, 'Master Chef',   '⭐',   300, '#9C27B0'),
  (7, 'b🌶te Legend',  '🔥',   600, '#FFD700')
on conflict (level) do nothing;
