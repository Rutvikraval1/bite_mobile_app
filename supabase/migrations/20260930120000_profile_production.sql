/*
  # Profile area → production

  1. profiles: avatar_url, cooked_count, notification prefs, unique username.
  2. recipes: user-created recipes (author_id, description, ingredients,
     steps, status) with an auto id sequence for new rows.
  3. New tables: cook_history, notifications, device_tokens.
  4. Storage buckets: avatars, recipe-images (public read, owner write).
  5. delete_own_account() RPC used by Edit Profile → Delete Account.
  6. Notification triggers (recipe saved / cooked → notify the author).
  7. RLS: replaces the open "no-auth app" policies with per-user ownership.
     Sign-in is now required for every write.

  Idempotent — safe to re-run.
*/

-- ───────────────────────── 1. profiles ─────────────────────────
alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists cooked_count integer not null default 0,
  add column if not exists push_enabled boolean not null default true,
  add column if not exists meal_reminders_enabled boolean not null default true;

-- Case-insensitive unique usernames (empty = not chosen yet, allowed).
create unique index if not exists profiles_username_unique
  on public.profiles (lower(username))
  where username <> '';

-- ───────────────────────── 2. recipes ──────────────────────────
alter table public.recipes
  add column if not exists author_id uuid references public.profiles (id) on delete cascade,
  add column if not exists description text not null default '',
  add column if not exists ingredients text[] not null default '{}',
  add column if not exists steps text[] not null default '{}',
  add column if not exists status text not null default 'published',
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'recipes_status_check'
  ) then
    alter table public.recipes
      add constraint recipes_status_check check (status in ('draft', 'published'));
  end if;
end $$;

-- Catalog rows use hand-picked ids; user recipes start at 100000.
create sequence if not exists public.recipes_id_seq start with 100000;
select setval(
  'public.recipes_id_seq',
  greatest(100000, (select coalesce(max(id), 0) + 1 from public.recipes)),
  false
);
alter table public.recipes alter column id set default nextval('public.recipes_id_seq');
alter sequence public.recipes_id_seq owned by public.recipes.id;

create index if not exists idx_recipes_author on public.recipes (author_id);

drop trigger if exists recipes_set_updated_at on public.recipes;
create trigger recipes_set_updated_at
  before update on public.recipes
  for each row execute function public.set_updated_at();

-- ─────────────────────── 3a. cook_history ──────────────────────
create table if not exists public.cook_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  recipe_id integer references public.recipes (id) on delete set null,
  title text not null,
  emoji text not null default '🍽',
  image_url text,
  rating integer check (rating between 1 and 5),
  cooked_at timestamptz not null default now()
);
create index if not exists idx_cook_history_user on public.cook_history (user_id, cooked_at desc);

-- Keep profiles.cooked_count in sync.
create or replace function public.bump_cooked_count()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set cooked_count = cooked_count + 1 where id = new.user_id;
  elsif tg_op = 'DELETE' then
    update public.profiles set cooked_count = greatest(cooked_count - 1, 0) where id = old.user_id;
  end if;
  return null;
end;
$$;

drop trigger if exists cook_history_count on public.cook_history;
create trigger cook_history_count
  after insert or delete on public.cook_history
  for each row execute function public.bump_cooked_count();

-- ─────────────────────── 3b. notifications ─────────────────────
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  type text not null default 'system',
  title text not null,
  body text not null default '',
  emoji text not null default '🔔',
  action_dest text,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications (user_id, created_at desc);

-- ─────────────────────── 3c. device_tokens ─────────────────────
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  token text not null unique,
  platform text not null default 'unknown',
  updated_at timestamptz not null default now()
);
create index if not exists idx_device_tokens_user on public.device_tokens (user_id);

-- ───────────────────────── 4. storage ──────────────────────────
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true), ('recipe-images', 'recipe-images', true)
on conflict (id) do update set public = excluded.public;

-- Objects are stored as "<user id>/<file>"; only the owner may write.
drop policy if exists "bite_images_public_read" on storage.objects;
create policy "bite_images_public_read" on storage.objects for select
  using (bucket_id in ('avatars', 'recipe-images'));

drop policy if exists "bite_images_owner_insert" on storage.objects;
create policy "bite_images_owner_insert" on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('avatars', 'recipe-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "bite_images_owner_update" on storage.objects;
create policy "bite_images_owner_update" on storage.objects for update
  to authenticated
  using (
    bucket_id in ('avatars', 'recipe-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "bite_images_owner_delete" on storage.objects;
create policy "bite_images_owner_delete" on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('avatars', 'recipe-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─────────────────────── 5. delete account ─────────────────────
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  -- profiles, saved_items, cook_history, notifications, … cascade.
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- ──────────────────── 6. notification triggers ─────────────────
create or replace function public.notify_recipe_author()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_author uuid;
  v_title text;
  v_actor text;
  v_recipe integer;
begin
  if tg_table_name = 'saved_items' then
    if new.item_type <> 'recipe' then return null; end if;
    v_recipe := new.item_id;
  else
    v_recipe := new.recipe_id;
  end if;

  select author_id, title into v_author, v_title
  from public.recipes where id = v_recipe;

  if v_author is null or v_author = new.user_id then
    return null;
  end if;

  select coalesce(nullif(display_name, ''), nullif(username, ''), 'Someone')
  into v_actor from public.profiles where id = new.user_id;

  insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
  values (
    v_author,
    case when tg_table_name = 'saved_items' then 'recipe_saved' else 'recipe_cooked' end,
    case when tg_table_name = 'saved_items'
      then coalesce(v_actor, 'Someone') || ' saved your recipe'
      else coalesce(v_actor, 'Someone') || ' cooked your recipe' end,
    v_title,
    case when tg_table_name = 'saved_items' then '🔖' else '🍳' end,
    'recipeDetail',
    jsonb_build_object('recipe_id', v_recipe)
  );
  return null;
end;
$$;

drop trigger if exists saved_items_notify on public.saved_items;
create trigger saved_items_notify
  after insert on public.saved_items
  for each row execute function public.notify_recipe_author();

drop trigger if exists cook_history_notify on public.cook_history;
create trigger cook_history_notify
  after insert on public.cook_history
  for each row execute function public.notify_recipe_author();

-- ─────────────────────────── 7. RLS ────────────────────────────
-- Drop every legacy open policy.
do $$
declare
  t text;
  op text;
begin
  foreach t in array array['profiles','recipes','drinks','places','saved_items','meal_plans','swipes'] loop
    foreach op in array array['select','insert','update','delete'] loop
      execute format('drop policy if exists %I on public.%I', 'anon_' || op || '_' ||
        case t
          when 'profiles' then 'profiles'
          when 'recipes' then 'recipes'
          when 'drinks' then 'drinks'
          when 'places' then 'places'
          when 'saved_items' then 'saved'
          when 'meal_plans' then 'meal_plans'
          when 'swipes' then 'swipes'
        end, t);
    end loop;
  end loop;
end $$;

-- Owner-scoped user data: user_id defaults to the caller.
alter table public.saved_items alter column user_id set default auth.uid();
alter table public.meal_plans alter column user_id set default auth.uid();
alter table public.swipes alter column user_id set default auth.uid();

-- profiles: anyone signed in can view (creator pages), owner can write.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select
  to authenticated using (true);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert
  to authenticated with check (id = auth.uid());
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update
  to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- recipes: published catalog is public; authors manage their own.
drop policy if exists "recipes_select" on public.recipes;
create policy "recipes_select" on public.recipes for select
  to anon, authenticated
  using (status = 'published' or author_id = auth.uid());
drop policy if exists "recipes_insert_own" on public.recipes;
create policy "recipes_insert_own" on public.recipes for insert
  to authenticated with check (author_id = auth.uid());
drop policy if exists "recipes_update_own" on public.recipes;
create policy "recipes_update_own" on public.recipes for update
  to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
drop policy if exists "recipes_delete_own" on public.recipes;
create policy "recipes_delete_own" on public.recipes for delete
  to authenticated using (author_id = auth.uid());

-- drinks / places: read-only catalog (managed from the dashboard).
drop policy if exists "drinks_select" on public.drinks;
create policy "drinks_select" on public.drinks for select
  to anon, authenticated using (true);
drop policy if exists "places_select" on public.places;
create policy "places_select" on public.places for select
  to anon, authenticated using (true);

-- Per-user tables: full CRUD on own rows only.
do $$
declare
  t text;
begin
  foreach t in array array['saved_items','meal_plans','swipes','cook_history','notifications','device_tokens'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_own', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (user_id = auth.uid()) with check (user_id = auth.uid())',
      t || '_own', t);
  end loop;
end $$;

-- Realtime for the in-app notification badge.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
exception when undefined_object then
  null; -- publication missing on self-hosted setups
end $$;
