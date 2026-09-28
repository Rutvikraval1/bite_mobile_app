-- ═══════════════════════════════════════════════════════════════
-- public.swipes — swipe interaction log (engagement / cuisine
-- discovery / milestone analytics)
-- Final effective state (see ../migrations/ for history).
--
-- user_id is nullable with no default: this is a no-auth app using
-- the anon key, so anonymous sessions store NULL (single-tenant,
-- shared data). Re-add `not null default auth.uid()` once real
-- per-user auth is enforced.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  item_type text not null,
  item_id integer not null,
  action text not null default 'pass',
  cuisine text,
  created_at timestamptz not null default now()
);

create index if not exists idx_swipes_user on public.swipes (user_id);

alter table public.swipes enable row level security;

drop policy if exists "Swipes are insertable by the owner" on public.swipes;
drop policy if exists "Swipes are viewable by the owner" on public.swipes;
drop policy if exists "select_own_swipes" on public.swipes;
drop policy if exists "insert_own_swipes" on public.swipes;
drop policy if exists "anon_select_swipes" on public.swipes;
drop policy if exists "anon_insert_swipes" on public.swipes;
drop policy if exists "anon_update_swipes" on public.swipes;
drop policy if exists "anon_delete_swipes" on public.swipes;

-- No-auth app: anon key is used exclusively, so policies are open.
create policy "anon_select_swipes" on public.swipes for select
  to anon, authenticated using (true);
create policy "anon_insert_swipes" on public.swipes for insert
  to anon, authenticated with check (true);
create policy "anon_update_swipes" on public.swipes for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_swipes" on public.swipes for delete
  to anon, authenticated using (true);
