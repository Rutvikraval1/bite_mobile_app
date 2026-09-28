-- ═══════════════════════════════════════════════════════════════
-- public.profiles — per-user profile, extends auth.users
-- Final effective state (see ../migrations/ for history).
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  username text not null default '',
  bio text not null default '',
  avatar_emoji text not null default '🧑‍🍳',
  dob date,
  xp integer not null default 0,
  bite_coins integer not null default 0,
  streak_count integer not null default 0,
  longest_streak integer not null default 0,
  streak_multiplier numeric not null default 1.0,
  streak_freezes integer not null default 0,
  daily_chest_claimed boolean not null default false,
  is_premium boolean not null default false,
  user_tier text not null default 'free',
  cuisines text[] not null default '{}',
  dietary text[] not null default '{}',
  badges text[] not null default '{}',
  age_verified boolean not null default false,
  location_granted boolean not null default false,
  cooking_skill text,
  cooking_goal text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by the owner" on public.profiles;
drop policy if exists "Profiles are updateable by the owner" on public.profiles;
drop policy if exists "Profiles are insertable by the owner" on public.profiles;
drop policy if exists "select_own_profile" on public.profiles;
drop policy if exists "insert_own_profile" on public.profiles;
drop policy if exists "update_own_profile" on public.profiles;
drop policy if exists "delete_own_profile" on public.profiles;
drop policy if exists "anon_select_profiles" on public.profiles;
drop policy if exists "anon_insert_profiles" on public.profiles;
drop policy if exists "anon_update_profiles" on public.profiles;
drop policy if exists "anon_delete_profiles" on public.profiles;

-- No-auth app: anon key is used exclusively, so policies are open.
-- Tighten to `auth.uid() = id` once real sign-in is enforced.
create policy "anon_select_profiles" on public.profiles for select
  to anon, authenticated using (true);
create policy "anon_insert_profiles" on public.profiles for insert
  to anon, authenticated with check (true);
create policy "anon_update_profiles" on public.profiles for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_profiles" on public.profiles for delete
  to anon, authenticated using (true);

-- Trigger: keep updated_at fresh on every UPDATE.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
