/*
  # Follows

  Creators the user follows. Creators are identified by their public
  handle (e.g. "@chefpriya"), stored lowercase with a leading "@".
  Owner-only RLS, like the other per-user tables.
*/

create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  creator_handle text not null check (creator_handle ~ '^@[a-z0-9_.]+$'),
  created_at timestamptz not null default now(),
  unique (user_id, creator_handle)
);

create index if not exists idx_follows_user on public.follows (user_id);

alter table public.follows enable row level security;

drop policy if exists "follows_own" on public.follows;
create policy "follows_own" on public.follows for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
