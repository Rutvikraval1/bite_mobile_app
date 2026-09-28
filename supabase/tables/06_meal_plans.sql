-- ═══════════════════════════════════════════════════════════════
-- public.meal_plans — meal planner calendar entries
-- Final effective state (see ../migrations/ for history).
--
-- user_id is nullable with no default: this is a no-auth app using
-- the anon key, so anonymous sessions store NULL (single-tenant,
-- shared data). Re-add `not null default auth.uid()` once real
-- per-user auth is enforced.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  plan_date date not null,
  meal_slot text not null,
  title text not null,
  emoji text not null default '🍽',
  color text not null default '#F5A623',
  created_at timestamptz not null default now()
);

create index if not exists idx_meal_plans_user_date on public.meal_plans (user_id, plan_date);

alter table public.meal_plans enable row level security;

drop policy if exists "Meal plans are viewable by the owner" on public.meal_plans;
drop policy if exists "Meal plans are insertable by the owner" on public.meal_plans;
drop policy if exists "Meal plans are deletable by the owner" on public.meal_plans;
drop policy if exists "select_own_meals" on public.meal_plans;
drop policy if exists "insert_own_meals" on public.meal_plans;
drop policy if exists "update_own_meals" on public.meal_plans;
drop policy if exists "delete_own_meals" on public.meal_plans;
drop policy if exists "anon_select_meals" on public.meal_plans;
drop policy if exists "anon_insert_meals" on public.meal_plans;
drop policy if exists "anon_update_meals" on public.meal_plans;
drop policy if exists "anon_delete_meals" on public.meal_plans;

-- No-auth app: anon key is used exclusively, so policies are open.
create policy "anon_select_meals" on public.meal_plans for select
  to anon, authenticated using (true);
create policy "anon_insert_meals" on public.meal_plans for insert
  to anon, authenticated with check (true);
create policy "anon_update_meals" on public.meal_plans for update
  to anon, authenticated using (true) with check (true);
create policy "anon_delete_meals" on public.meal_plans for delete
  to anon, authenticated using (true);
