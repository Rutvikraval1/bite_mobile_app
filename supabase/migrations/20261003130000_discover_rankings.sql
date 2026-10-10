/*
  # Discover rankings — Social "For You" + "🔥 Trending"

  Both tabs used to sort by recipes.saved_count / hearts_count, seeded
  text values that never change. These functions rank from real activity
  instead:

  1. trending_recipes() — engagement in the last N days across all users:
     saves, cooks, feed likes/comments on posts about the recipe, deck
     super-favs. The seeded hearts only break ties, so real activity
     always wins.
  2. for_you_recipes() — per signed-in user: profile cuisines + dietary,
     cuisines they saved/cooked/swiped right on (minus ones they keep
     passing), recent popularity. Recipes they already saved, cooked or
     passed sink to the bottom.

  security definer so aggregate counts can include other users' rows;
  only ids and counts are returned. Idempotent.
*/

-- "6.3K" → 6300, "890" → 890, junk → 0.
create or replace function public.count_value(p text)
returns numeric
language sql
immutable
as $$
  select case
    when coalesce(trim(p), '') !~ '^[0-9]+(\.[0-9]+)?[kKmM]?$' then 0
    when upper(trim(p)) like '%K' then rtrim(upper(trim(p)), 'K')::numeric * 1000
    when upper(trim(p)) like '%M' then rtrim(upper(trim(p)), 'M')::numeric * 1000000
    else trim(p)::numeric
  end
$$;

-- ───────────────────────────── trending ────────────────────────────

create or replace function public.trending_recipes(p_days integer default 7, p_limit integer default 10)
returns table (recipe_id integer, hearts_week integer, hearts_total bigint, score numeric)
language sql
stable
security definer set search_path = public
as $$
  with since as (
    select now() - make_interval(days => greatest(coalesce(p_days, 7), 1)) as at
  ),
  saves as (
    select s.item_id as rid, count(*) as n
    from saved_items s, since
    where s.item_type in ('recipe', 'food') and s.created_at >= since.at
    group by 1
  ),
  cooks as (
    select h.recipe_id as rid, count(*) as n
    from cook_history h, since
    where h.recipe_id is not null and h.cooked_at >= since.at
    group by 1
  ),
  likes as (
    select p.recipe_id as rid, count(*) as n
    from post_likes l
    join feed_posts p on p.id = l.post_id, since
    where p.recipe_id is not null and l.created_at >= since.at
    group by 1
  ),
  comments as (
    select p.recipe_id as rid, count(*) as n
    from post_comments c
    join feed_posts p on p.id = c.post_id, since
    where p.recipe_id is not null and c.user_id is not null and c.created_at >= since.at
    group by 1
  ),
  favs as (
    select w.item_id as rid,
           count(*) filter (where w.action = 'super_fav') as super_favs,
           count(*) filter (where w.action = 'save') as right_swipes
    from swipes w, since
    where w.item_type = 'recipe' and w.created_at >= since.at
    group by 1
  ),
  all_saves as (
    select s.item_id as rid, count(*) as n
    from saved_items s
    where s.item_type in ('recipe', 'food')
    group by 1
  )
  select
    r.id,
    (coalesce(s.n, 0) + coalesce(l.n, 0) + coalesce(f.super_favs, 0))::integer,
    (public.count_value(r.hearts_count) + coalesce(a.n, 0))::bigint,
    coalesce(s.n, 0) * 3
      + coalesce(c.n, 0) * 4
      + coalesce(l.n, 0) * 2
      + coalesce(cm.n, 0) * 2
      + coalesce(f.super_favs, 0) * 3
      + coalesce(f.right_swipes, 0)
      -- Tie-break only: seeded hearts never outweigh one real action.
      + public.count_value(r.hearts_count) / 1000000.0
  from recipes r
  left join saves s on s.rid = r.id
  left join cooks c on c.rid = r.id
  left join likes l on l.rid = r.id
  left join comments cm on cm.rid = r.id
  left join favs f on f.rid = r.id
  left join all_saves a on a.rid = r.id
  where r.status = 'published'
  order by 4 desc, r.id
  limit greatest(coalesce(p_limit, 10), 1)
$$;

revoke all on function public.trending_recipes(integer, integer) from public, anon;
grant execute on function public.trending_recipes(integer, integer) to authenticated;

-- ───────────────────────────── for you ─────────────────────────────

create or replace function public.for_you_recipes(p_limit integer default 10)
returns table (recipe_id integer, score numeric, seen boolean)
language sql
stable
security definer set search_path = public
as $$
  with me as (
    select auth.uid() as uid
  ),
  prof as (
    select
      coalesce((select array_agg(lower(c)) from unnest(p.cuisines) c), '{}') as cuisines,
      coalesce((select array_agg(regexp_replace(lower(d), '[^a-z]', '', 'g')) from unnest(p.dietary) d), '{}') as diet
    from profiles p, me
    where p.id = me.uid
  ),
  liked_cuisines as (
    select lower(x.cuisine) as c, count(*) as n
    from (
      select s.cuisine from saved_items s, me
      where s.user_id = me.uid and s.item_type in ('recipe', 'food') and s.cuisine is not null
      union all
      select w.cuisine from swipes w, me
      where w.user_id = me.uid and w.item_type = 'recipe' and w.action in ('save', 'super_fav') and w.cuisine is not null
      union all
      select r.cuisine from cook_history h join recipes r on r.id = h.recipe_id, me
      where h.user_id = me.uid
    ) x
    group by 1
  ),
  passed_cuisines as (
    select lower(w.cuisine) as c, count(*) as n
    from swipes w, me
    where w.user_id = me.uid and w.item_type = 'recipe' and w.action = 'pass' and w.cuisine is not null
    group by 1
  ),
  seen as (
    select s.item_id as rid from saved_items s, me
    where s.user_id = me.uid and s.item_type in ('recipe', 'food')
    union
    select h.recipe_id from cook_history h, me
    where h.user_id = me.uid and h.recipe_id is not null
    union
    select w.item_id from swipes w, me
    where w.user_id = me.uid and w.item_type = 'recipe' and w.action = 'pass'
  ),
  popular as (
    select s.item_id as rid, count(*) as n
    from saved_items s
    where s.item_type in ('recipe', 'food') and s.created_at >= now() - interval '30 days'
    group by 1
  ),
  scored as (
    select
      r.id,
      (case when lower(r.cuisine) = any (coalesce((select cuisines from prof), '{}')) then 5 else 0 end)
        + least(coalesce(lc.n, 0), 5) * 2
        - least(coalesce(pc.n, 0), 5)
        + 3 * (
            select count(*) from unnest(r.tags) t
            where regexp_replace(lower(t), '[^a-z]', '', 'g') = any (coalesce((select diet from prof), '{}'))
          )
        + ln(1 + coalesce(pop.n, 0))
        + public.count_value(r.saved_count) / 1000000.0 as score,
      r.id in (select rid from seen) as seen
    from recipes r
    left join liked_cuisines lc on lc.c = lower(r.cuisine)
    left join passed_cuisines pc on pc.c = lower(r.cuisine)
    left join popular pop on pop.rid = r.id
    where r.status = 'published'
      and r.author_id is distinct from (select uid from me)
  )
  select id, score, seen
  from scored
  order by seen, score desc, id
  limit greatest(coalesce(p_limit, 10), 1)
$$;

revoke all on function public.for_you_recipes(integer) from public, anon;
grant execute on function public.for_you_recipes(integer) to authenticated;
