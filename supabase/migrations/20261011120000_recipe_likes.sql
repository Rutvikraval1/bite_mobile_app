/*
  # Recipe / drink likes → production

  Backs the ❤️ button on Recipe Detail, which used to change on screen only.

  1. recipe_likes — one row per (user, recipe or drink).
  2. RLS: every signed-in user can read; users like / unlike only as
     themselves, on items they can see.
  3. Trigger keeps recipes.hearts_count / drinks.hearts_count in step
     (stored as a plain number string; seeded "2.4K" values are parsed with
     public.count_value) and notifies a user-created recipe's author.

  Idempotent — safe to re-run.
*/

-- ───────────────────────── 1. recipe_likes ─────────────────────────

create table if not exists public.recipe_likes (
  item_type text not null check (item_type in ('recipe', 'drink')),
  item_id integer not null,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (item_type, item_id, user_id)
);
create index if not exists idx_recipe_likes_user
  on public.recipe_likes (user_id, created_at desc);

-- ───────────────────────────── 2. RLS ──────────────────────────────

alter table public.recipe_likes enable row level security;

drop policy if exists "recipe_likes_select" on public.recipe_likes;
create policy "recipe_likes_select" on public.recipe_likes for select
  to authenticated using (true);

drop policy if exists "recipe_likes_insert_own" on public.recipe_likes;
create policy "recipe_likes_insert_own" on public.recipe_likes for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      (item_type = 'recipe' and exists (select 1 from public.recipes r where r.id = item_id))
      or (item_type = 'drink' and exists (select 1 from public.drinks d where d.id = item_id))
    )
  );

drop policy if exists "recipe_likes_delete_own" on public.recipe_likes;
create policy "recipe_likes_delete_own" on public.recipe_likes for delete
  to authenticated using (user_id = auth.uid());

-- ─────────────────────── 3. counters + notify ──────────────────────

create or replace function public.bump_recipe_likes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_row public.recipe_likes;
  v_delta integer;
  v_author uuid;
  v_title text;
begin
  if tg_op = 'INSERT' then
    v_row := new;
    v_delta := 1;
  else
    v_row := old;
    v_delta := -1;
  end if;

  if v_row.item_type = 'recipe' then
    update public.recipes
    set hearts_count = greatest(public.count_value(hearts_count) + v_delta, 0)::bigint::text
    where id = v_row.item_id
    returning author_id, title into v_author, v_title;
  else
    update public.drinks
    set hearts_count = greatest(public.count_value(hearts_count) + v_delta, 0)::bigint::text
    where id = v_row.item_id;
  end if;

  if tg_op = 'INSERT' and v_author is not null and v_author <> new.user_id then
    insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
    values (
      v_author, 'recipe_like',
      public.actor_name(new.user_id) || ' liked your recipe',
      coalesce(v_title, ''), '❤️', 'recipeDetail',
      jsonb_build_object('recipe_id', new.item_id, 'title', v_title)
    );
  end if;
  return null;
end;
$$;

drop trigger if exists recipe_likes_count on public.recipe_likes;
create trigger recipe_likes_count
  after insert or delete on public.recipe_likes
  for each row execute function public.bump_recipe_likes();
