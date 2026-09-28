-- ═══════════════════════════════════════════════════════════════
-- b🌶te — initial schema
-- RLS everywhere: content readable by authenticated users; all
-- user-owned tables scoped to auth.uid().
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────
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

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    coalesce(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep updated_at fresh.
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

alter table public.profiles enable row level security;

create policy "Profiles are viewable by the owner"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Profiles are updateable by the owner"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Profiles are insertable by the owner"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ─────────────────────────────────────────────
-- CONTENT — global catalog (recipes / drinks / places)
-- ─────────────────────────────────────────────
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

alter table public.recipes enable row level security;
alter table public.drinks enable row level security;
alter table public.places enable row level security;

create policy "Recipes are readable by authenticated users"
  on public.recipes for select
  using (auth.role() = 'authenticated');

create policy "Drinks are readable by authenticated users"
  on public.drinks for select
  using (auth.role() = 'authenticated');

create policy "Places are readable by authenticated users"
  on public.places for select
  using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────
-- SAVED ITEMS — per-user
-- ─────────────────────────────────────────────
create table if not exists public.saved_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  item_type text not null check (item_type in ('recipe', 'drink', 'place')),
  item_id integer not null,
  title text not null,
  emoji text not null default '🍽',
  image_url text,
  cuisine text,
  created_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

alter table public.saved_items enable row level security;

create policy "Saved items are viewable by the owner"
  on public.saved_items for select
  using (auth.uid() = user_id);

create policy "Saved items are insertable by the owner"
  on public.saved_items for insert
  with check (auth.uid() = user_id);

create policy "Saved items are deletable by the owner"
  on public.saved_items for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- MEAL PLANS — per-user
-- ─────────────────────────────────────────────
create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_date date not null,
  meal_slot text not null,
  title text not null,
  emoji text not null default '🍽',
  color text not null default '#F5A623',
  created_at timestamptz not null default now()
);

alter table public.meal_plans enable row level security;

create policy "Meal plans are viewable by the owner"
  on public.meal_plans for select
  using (auth.uid() = user_id);

create policy "Meal plans are insertable by the owner"
  on public.meal_plans for insert
  with check (auth.uid() = user_id);

create policy "Meal plans are deletable by the owner"
  on public.meal_plans for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- SWIPES — per-user analytics
-- ─────────────────────────────────────────────
create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  item_type text not null,
  item_id integer not null,
  action text not null default 'pass',
  cuisine text,
  created_at timestamptz not null default now()
);

alter table public.swipes enable row level security;

create policy "Swipes are insertable by the owner"
  on public.swipes for insert
  with check (auth.uid() = user_id);

create policy "Swipes are viewable by the owner"
  on public.swipes for select
  using (auth.uid() = user_id);
