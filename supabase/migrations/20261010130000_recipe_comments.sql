/*
  # Recipe / drink comments → production

  Backs the comment panel on Recipe Detail. Feed posts already have
  post_comments, but a recipe can have many feed posts (or none), so
  recipe comments get their own table keyed by (item_type, item_id).

  1. recipe_comments — one row per comment on a recipe or drink.
  2. RLS: every signed-in user can read; users insert / delete only their
     own rows, posted under their own creator handle, on items they can see.
  3. Trigger keeps recipes.comments_count / drinks.comments_count correct
     and notifies a user-created recipe's author.

  Idempotent — safe to re-run.
*/

-- ───────────────────────── 1. recipe_comments ─────────────────────────

create table if not exists public.recipe_comments (
  id uuid primary key default gen_random_uuid(),
  item_type text not null check (item_type in ('recipe', 'drink')),
  item_id integer not null,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_handle text not null references public.creators (handle) on update cascade on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists idx_recipe_comments_item
  on public.recipe_comments (item_type, item_id, created_at desc);

-- ───────────────────────────── 2. RLS ─────────────────────────────────

alter table public.recipe_comments enable row level security;

drop policy if exists "recipe_comments_select" on public.recipe_comments;
create policy "recipe_comments_select" on public.recipe_comments for select
  to authenticated using (true);

-- The exists() checks run under the caller's RLS, so you can only comment
-- on recipes you can see (published, or your own draft).
drop policy if exists "recipe_comments_insert_own" on public.recipe_comments;
create policy "recipe_comments_insert_own" on public.recipe_comments for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and author_handle = public.my_handle()
    and (
      (item_type = 'recipe' and exists (select 1 from public.recipes r where r.id = item_id))
      or (item_type = 'drink' and exists (select 1 from public.drinks d where d.id = item_id))
    )
  );

drop policy if exists "recipe_comments_delete_own" on public.recipe_comments;
create policy "recipe_comments_delete_own" on public.recipe_comments for delete
  to authenticated using (user_id = auth.uid());

-- ─────────────────────── 3. counters + notify ─────────────────────────

create or replace function public.bump_recipe_comments()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_author uuid;
  v_title text;
begin
  if tg_op = 'INSERT' then
    if new.item_type = 'recipe' then
      update public.recipes set comments_count = comments_count + 1
      where id = new.item_id
      returning author_id, title into v_author, v_title;
    else
      update public.drinks set comments_count = comments_count + 1 where id = new.item_id;
    end if;

    if v_author is not null and v_author <> new.user_id then
      insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
      values (
        v_author, 'recipe_comment',
        public.actor_name(new.user_id) || ' commented on your recipe',
        left(new.body, 140), '💬', 'recipeDetail',
        jsonb_build_object('recipe_id', new.item_id, 'comment_id', new.id, 'title', v_title)
      );
    end if;
  elsif tg_op = 'DELETE' then
    if old.item_type = 'recipe' then
      update public.recipes set comments_count = greatest(comments_count - 1, 0) where id = old.item_id;
    else
      update public.drinks set comments_count = greatest(comments_count - 1, 0) where id = old.item_id;
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists recipe_comments_count on public.recipe_comments;
create trigger recipe_comments_count
  after insert or delete on public.recipe_comments
  for each row execute function public.bump_recipe_comments();

-- Catalog rows were seeded with placeholder counts and no comment rows;
-- reconcile so every count matches the comments that actually exist.
update public.recipes r set comments_count = coalesce((
  select count(*) from public.recipe_comments c
  where c.item_type = 'recipe' and c.item_id = r.id
), 0);
update public.drinks d set comments_count = coalesce((
  select count(*) from public.recipe_comments c
  where c.item_type = 'drink' and c.item_id = d.id
), 0);
