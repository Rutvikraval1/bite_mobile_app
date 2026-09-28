-- ═══════════════════════════════════════════════════════════════
-- public.saved_items — recipes/drinks/places a user has saved
-- Final effective state (see ../migrations/ for history).
--
-- user_id is nullable with no default: this is a no-auth app using
-- the anon key, so anonymous sessions store NULL (single-tenant,
-- shared data). Re-add `not null default auth.uid()` once real
-- per-user auth is enforced.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.saved_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  item_type text not null check (item_type in ('recipe', 'drink', 'place')),
  item_id integer not null,
  title text not null,
  emoji text not null default '🍽',
  image_url text,
  cuisine text,
  created_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

create index if not exists idx_saved_items_user on public.saved_items (user_id);

alter table public.saved_items enable row level security;

drop policy if exists "Saved items are viewable by the owner" on public.saved_items;
drop policy if exists "Saved items are insertable by the owner" on public.saved_items;
drop policy if exists "Saved items are deletable by the owner" on public.saved_items;
drop policy if exists "select_own_saved" on public.saved_items;
drop policy if exists "insert_own_saved" on public.saved_items;
drop policy if exists "update_own_saved" on public.saved_items;
drop policy if exists "delete_own_saved" on public.saved_items;
drop policy if exists "anon_select_saved" on public.saved_items;
drop policy if exists "anon_insert_saved" on public.saved_items;
drop policy if exists "anon_update_saved" on public.saved_items;
drop policy if exists "anon_delete_saved" on public.saved_items;

-- No-auth app: anon key is used exclusively, so policies are open.
create policy "anon_select_saved" on public.saved_items for select
  to anon, authenticated using (true);
create policy "anon_insert_saved" on public.saved_items for insert
  to anon, authenticated with check (true);
create policy "anon_update_saved" on public.saved_items for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_saved" on public.saved_items for delete
  to anon, authenticated using (true);
