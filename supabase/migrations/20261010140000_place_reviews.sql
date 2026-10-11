/*
  # Place reviews

  1. place_reviews — one b🌶te review (1–5 stars + text) per user per place.
     user_id references profiles so PostgREST can embed the author
     (`author:profiles(display_name, username, avatar_emoji, avatar_url)`).
  2. place_review_stats — live average rating + review count per place.
  3. Place "creator" handles become (seeded) creators so the
     "Reviewed by" row on Place Detail opens a real creator profile.
  4. RLS: any signed-in user can read; users write only their own review.

  Idempotent — safe to re-run.
*/

-- ─────────────────────── 1. place_reviews ───────────────────────
create table if not exists public.place_reviews (
  id uuid primary key default gen_random_uuid(),
  place_id integer not null references public.places (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  body text not null default '' check (char_length(body) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (place_id, user_id)
);
create index if not exists idx_place_reviews_place
  on public.place_reviews (place_id, created_at desc);

drop trigger if exists place_reviews_set_updated_at on public.place_reviews;
create trigger place_reviews_set_updated_at
  before update on public.place_reviews
  for each row execute function public.set_updated_at();

alter table public.place_reviews enable row level security;

drop policy if exists "place_reviews_select" on public.place_reviews;
create policy "place_reviews_select" on public.place_reviews for select
  to authenticated using (true);
drop policy if exists "place_reviews_insert_own" on public.place_reviews;
create policy "place_reviews_insert_own" on public.place_reviews for insert
  to authenticated with check (user_id = auth.uid());
drop policy if exists "place_reviews_update_own" on public.place_reviews;
create policy "place_reviews_update_own" on public.place_reviews for update
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "place_reviews_delete_own" on public.place_reviews;
create policy "place_reviews_delete_own" on public.place_reviews for delete
  to authenticated using (user_id = auth.uid());

-- ───────────────────── 2. place_review_stats ────────────────────
-- security_invoker: the view obeys place_reviews RLS of the caller.
create or replace view public.place_review_stats
with (security_invoker = true) as
select
  place_id,
  round(avg(rating)::numeric, 1) as avg_rating,
  count(*)::integer as review_count
from public.place_reviews
group by place_id;

grant select on public.place_review_stats to authenticated;

-- ─────────────────── 3. place creators → creators ───────────────
insert into public.creators (handle, display_name)
select distinct lower(p.creator), initcap(replace(replace(substr(lower(p.creator), 2), '_', ' '), '.', ' '))
from public.places p
where lower(p.creator) ~ '^@[a-z0-9_.]+$'
on conflict (handle) do nothing;
