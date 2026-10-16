/*
  # Competitions, Elo voting, cook-offs and community impact → Supabase

  Replaces the last local mock data (MockProfileData / CompetitionData /
  EloVotingData) behind the Competition, Elo Voting and Community Impact
  screens.

  1. charities, profiles.charity_id, donations
       charities is admin-managed catalog content (seeded below).
       donations has one row per real donation. Nothing in the app inserts
       donations: payments aren't wired yet, so totals stay at $0 until the
       payment backend records them (service role only).
  2. competition_tiers, competitions, competition_entries, elo_votes
       Tiers and competitions are admin-managed (seeded below). An entry is a
       dish from the user's cook_history and carries its Elo score
       (starts at 1200). Votes go through cast_elo_vote(), which updates both
       scores atomically, caps a voter at 50 votes per day and awards 5 XP
       per vote.
  3. cook_offs, cook_off_votes
       Head-to-head challenges between two users. Status is derived from
       time: open → cooking (until cook_deadline) → voting (until
       voting_ends_at) → done.
  4. RPCs: competition_board, enter_competition, elo_board, cast_elo_vote,
       cook_off_board, start_cook_off, accept_cook_off, vote_cook_off,
       community_impact.

  Idempotent — safe to re-run.
*/

-- ───────────────────────── 1. charities ──────────────────────────────

create table if not exists public.charities (
  id integer primary key,
  emoji text not null,
  name text not null,
  description text not null default '',
  -- "meals served": what one unit of impact is called …
  impact_label text not null default '',
  -- … and what one unit costs, in cents (e.g. 50 = $0.50 per meal).
  cents_per_unit integer not null default 100 check (cents_per_unit > 0),
  sort integer not null default 0,
  active boolean not null default true
);

alter table public.charities enable row level security;
drop policy if exists "charities_select_all" on public.charities;
create policy "charities_select_all" on public.charities for select
  to anon, authenticated using (true);

insert into public.charities (id, emoji, name, description, impact_label, cents_per_unit, sort) values
  (1, '🐝', 'Save the Bees',          'Protecting pollinators worldwide', 'hives protected',       5000, 1),
  (2, '🎖', 'Feed Homeless Veterans', 'Meals for those who served',       'meals served',            50, 2),
  (3, '🍽', 'Feed the Hungry',        'Fighting global food insecurity',  'meals provided',          25, 3),
  (4, '💧', 'Clean Water for All',    'Safe drinking water access',       'people with clean water',  1, 4),
  (5, '🐕', 'Rescue Animals',         'Shelter & adoption support',       'animals sheltered',      500, 5),
  (6, '🌱', 'Plant Trees',            'Reforestation & climate action',   'trees planted',           20, 6)
on conflict (id) do update set
  emoji = excluded.emoji, name = excluded.name, description = excluded.description,
  impact_label = excluded.impact_label, cents_per_unit = excluded.cents_per_unit,
  sort = excluded.sort;

-- The user's chosen cause (null = none chosen / "No donation").
alter table public.profiles
  add column if not exists charity_id integer references public.charities (id) on delete set null;

create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  charity_id integer not null references public.charities (id),
  amount_cents integer not null check (amount_cents > 0),
  source text not null default 'premium',
  created_at timestamptz not null default now()
);
create index if not exists idx_donations_user on public.donations (user_id, created_at desc);
create index if not exists idx_donations_charity on public.donations (charity_id);

alter table public.donations enable row level security;
-- Users read their own donations; writes are service-role only.
drop policy if exists "donations_select_own" on public.donations;
create policy "donations_select_own" on public.donations for select
  to authenticated using (user_id = auth.uid());

-- ───────────────────── 2. competitions + Elo ─────────────────────────

create table if not exists public.competition_tiers (
  id text primary key,
  label text not null,
  icon text not null,
  description text not null default '',
  info text not null default '',
  requirement text,
  color text not null default '#4CAF50',
  -- Free entry needs at least this many cooks (profiles.cooked_count);
  -- otherwise the competition's entry_coins are charged.
  min_cooks integer not null default 0,
  sort integer not null default 0
);

alter table public.competition_tiers enable row level security;
drop policy if exists "competition_tiers_select_all" on public.competition_tiers;
create policy "competition_tiers_select_all" on public.competition_tiers for select
  to anon, authenticated using (true);

insert into public.competition_tiers (id, label, icon, description, info, requirement, color, min_cooks, sort) values
  ('casual', '🍳 Casual', '🍳', 'Everyone welcome',
   'Open to all users. No entry fee, no requirements. Cook, plate, post — let the community vote!',
   null, '#4CAF50', 0, 1),
  ('ranked', '🔥 Ranked', '🔥', '10+ cooks',
   'For active cooks. Requires 10+ cooked recipes or coin entry. Higher stakes, bigger prizes, tougher competition.',
   '🍳 10+ recipes cooked to unlock free entry', '#FFB347', 10, 2),
  ('elite', '👑 Elite', '👑', '50+ cooks',
   'The ultimate cooking stage. For serious cooks with 50+ recipes cooked. Cash prizes up to $10K.',
   '🏆 50+ recipes cooked OR coin entry', '#FF6B6B', 50, 3)
on conflict (id) do update set
  label = excluded.label, icon = excluded.icon, description = excluded.description,
  info = excluded.info, requirement = excluded.requirement, color = excluded.color,
  min_cooks = excluded.min_cooks, sort = excluded.sort;

create table if not exists public.competitions (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  tier_id text not null references public.competition_tiers (id),
  title text not null,
  emoji text not null default '🏆',
  sponsor text,
  theme text not null default '',
  -- [{"place": "🥇 1st", "prize": "500 b🌶te Coins"}, …]
  prizes jsonb not null default '[]'::jsonb,
  -- Coins charged when the user doesn't meet the tier's min_cooks.
  entry_coins integer not null default 0 check (entry_coins >= 0),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_competitions_tier on public.competitions (tier_id, ends_at);

alter table public.competitions enable row level security;
drop policy if exists "competitions_select_all" on public.competitions;
create policy "competitions_select_all" on public.competitions for select
  to anon, authenticated using (true);

-- Seeded once (by slug); admins edit or add rows afterwards.
insert into public.competitions (slug, tier_id, title, emoji, sponsor, theme, prizes, entry_coins, ends_at) values
  ('weekend-taco-challenge', 'casual', 'Weekend Taco Challenge', '🌮', '🌿 Whole Foods Market',
   'Create the most creative taco recipe using at least 5 ingredients.',
   '[{"place":"🥇 1st","prize":"500 b🌶te Coins + Casual Champ Badge"},{"place":"🥈 2nd","prize":"250 b🌶te Coins"},{"place":"🥉 3rd","prize":"100 b🌶te Coins"}]',
   0, now() + interval '7 days'),
  ('best-breakfast-bowl', 'casual', 'Best Breakfast Bowl', '🥣', null,
   'Show us your most photogenic breakfast bowl.',
   '[{"place":"🥇 1st","prize":"300 b🌶te Coins"}]',
   0, now() + interval '10 days'),
  ('chef-showdown', 'ranked', 'b🌶te Chef Showdown', '👨‍🍳', '🔪 Williams Sonoma',
   'Cook any dish from scratch, plating matters. Top 10 advance to live stream finale.',
   '[{"place":"🥇 1st","prize":"$2,500 Kitchen Set + Ranked Badge"},{"place":"🥈 2nd","prize":"$1,000 Gift Card + 2K Coins"},{"place":"🥉 3rd","prize":"$500 Gift Card + 1K Coins"},{"place":"4-10","prize":"500 b🌶te Coins each"}]',
   100, now() + interval '14 days'),
  ('world-cook-championship', 'elite', 'World Cook Championship', '🏆', '🌶 b🌶te Official',
   'Annual elite competition. Theme revealed at launch. Past winners have appeared on Food Network.',
   '[{"place":"🥇 1st","prize":"$10,000 + b🌶te Ambassador + 1yr Premium"},{"place":"🥈 2nd","prize":"$5,000 + 10K Coins"},{"place":"🥉 3rd","prize":"$2,500 + 5K Coins"},{"place":"4-10","prize":"$500 + 2K Coins each"}]',
   2000, now() + interval '28 days')
on conflict (slug) do nothing;

create table if not exists public.competition_entries (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  cook_history_id uuid references public.cook_history (id) on delete set null,
  title text not null,
  emoji text not null default '🍽',
  image_url text,
  elo integer not null default 1200,
  votes integer not null default 0,
  coins_paid integer not null default 0,
  created_at timestamptz not null default now(),
  unique (competition_id, user_id)
);
create index if not exists idx_competition_entries_comp
  on public.competition_entries (competition_id, elo desc);

alter table public.competition_entries enable row level security;
-- Entries are public within the app; writes go through enter_competition().
drop policy if exists "competition_entries_select_auth" on public.competition_entries;
create policy "competition_entries_select_auth" on public.competition_entries for select
  to authenticated using (true);

create table if not exists public.elo_votes (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions (id) on delete cascade,
  voter_id uuid not null references auth.users (id) on delete cascade,
  winner_entry_id uuid not null references public.competition_entries (id) on delete cascade,
  loser_entry_id uuid not null references public.competition_entries (id) on delete cascade,
  delta integer not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_elo_votes_voter on public.elo_votes (voter_id, created_at desc);

alter table public.elo_votes enable row level security;
drop policy if exists "elo_votes_select_own" on public.elo_votes;
create policy "elo_votes_select_own" on public.elo_votes for select
  to authenticated using (voter_id = auth.uid());

-- ─────────────────────────── 3. cook-offs ────────────────────────────

create table if not exists public.cook_offs (
  id uuid primary key default gen_random_uuid(),
  -- The user who posted the challenge (their dish is the one to beat).
  defender_id uuid not null references auth.users (id) on delete cascade,
  -- Whoever accepted it; null while open.
  challenger_id uuid references auth.users (id) on delete cascade,
  recipe_id integer references public.recipes (id) on delete set null,
  recipe_title text not null,
  emoji text not null default '🍽',
  difficulty text not null default 'Medium' check (difficulty in ('Easy', 'Medium', 'Hard')),
  note text not null default '',
  -- How long a challenger gets to cook once accepted.
  cook_hours integer not null default 48 check (cook_hours between 1 and 168),
  open_until timestamptz not null default now() + interval '3 days',
  accepted_at timestamptz,
  cook_deadline timestamptz,
  voting_ends_at timestamptz,
  created_at timestamptz not null default now(),
  check (challenger_id is null or challenger_id <> defender_id)
);
create index if not exists idx_cook_offs_open on public.cook_offs (open_until) where challenger_id is null;

alter table public.cook_offs enable row level security;
drop policy if exists "cook_offs_select_auth" on public.cook_offs;
create policy "cook_offs_select_auth" on public.cook_offs for select
  to authenticated using (true);

create table if not exists public.cook_off_votes (
  cook_off_id uuid not null references public.cook_offs (id) on delete cascade,
  voter_id uuid not null references auth.users (id) on delete cascade,
  side text not null check (side in ('challenger', 'defender')),
  created_at timestamptz not null default now(),
  primary key (cook_off_id, voter_id)
);

alter table public.cook_off_votes enable row level security;
drop policy if exists "cook_off_votes_select_own" on public.cook_off_votes;
create policy "cook_off_votes_select_own" on public.cook_off_votes for select
  to authenticated using (voter_id = auth.uid());

-- ───────────────────────────── helpers ───────────────────────────────

create or replace function public._require_uid()
returns uuid
language plpgsql
stable
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  return auth.uid();
end;
$$;

-- Public card for a user: handle, name, avatar.
create or replace function public._user_card(p_user uuid)
returns jsonb
language sql
stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'id', p.id,
    'handle', coalesce(public.handle_of(p.username), '@' || coalesce(nullif(p.display_name, ''), 'cook')),
    'name', coalesce(nullif(p.display_name, ''), nullif(p.username, ''), 'Cook'),
    'avatar_emoji', coalesce(nullif(p.avatar_emoji, ''), '🧑‍🍳'),
    'avatar_url', p.avatar_url)
  from public.profiles p where p.id = p_user
$$;

-- ─────────────────────── 4a. competitions RPCs ───────────────────────

-- Tiers with their live competitions, entrant counts, a few entrant
-- avatars, and whether the caller has entered.
create or replace function public.competition_board()
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_cooked integer;
begin
  select coalesce(cooked_count, 0) into v_cooked from public.profiles where id = v_uid;

  return jsonb_build_object(
    'cooked_count', coalesce(v_cooked, 0),
    'tiers', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'label', t.label, 'icon', t.icon, 'description', t.description,
        'info', t.info, 'requirement', t.requirement, 'color', t.color,
        'min_cooks', t.min_cooks,
        'competitions', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', c.id, 'title', c.title, 'emoji', c.emoji, 'sponsor', c.sponsor,
            'theme', c.theme, 'prizes', c.prizes, 'entry_coins', c.entry_coins,
            'starts_at', c.starts_at, 'ends_at', c.ends_at,
            'entrants', (select count(*) from public.competition_entries e where e.competition_id = c.id),
            'entered', exists (select 1 from public.competition_entries e
                               where e.competition_id = c.id and e.user_id = v_uid),
            'avatars', coalesce((
              select jsonb_agg(a.avatar_url) from (
                select p.avatar_url from public.competition_entries e
                join public.profiles p on p.id = e.user_id
                where e.competition_id = c.id and p.avatar_url is not null
                order by e.created_at desc limit 3) a), '[]'::jsonb)
          ) order by c.ends_at)
          from public.competitions c
          where c.tier_id = t.id and c.ends_at > now() and c.starts_at <= now()
        ), '[]'::jsonb)
      ) order by t.sort)
      from public.competition_tiers t
    ), '[]'::jsonb)
  );
end;
$$;

-- Enter a competition with a dish from the caller's cook_history.
-- Free when cooked_count >= tier.min_cooks, otherwise charges entry_coins.
create or replace function public.enter_competition(
  p_competition_id uuid,
  p_cook_history_id uuid
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_comp public.competitions;
  v_min_cooks integer;
  v_cooked integer;
  v_coins integer;
  v_cost integer := 0;
  v_dish public.cook_history;
begin
  select * into v_comp from public.competitions where id = p_competition_id;
  if not found then raise exception 'competition_not_found'; end if;
  if v_comp.ends_at <= now() or v_comp.starts_at > now() then
    raise exception 'competition_closed';
  end if;

  select * into v_dish from public.cook_history
  where id = p_cook_history_id and user_id = v_uid;
  if not found then raise exception 'dish_not_found'; end if;

  select min_cooks into v_min_cooks from public.competition_tiers where id = v_comp.tier_id;
  select coalesce(cooked_count, 0), bite_coins into v_cooked, v_coins
  from public.profiles where id = v_uid for update;

  if exists (select 1 from public.competition_entries
             where competition_id = p_competition_id and user_id = v_uid) then
    return jsonb_build_object('already_entered', true, 'new_coins', v_coins);
  end if;

  if v_cooked < coalesce(v_min_cooks, 0) then
    v_cost := v_comp.entry_coins;
    if v_cost = 0 then raise exception 'requirement_not_met'; end if;
    if v_coins < v_cost then raise exception 'not_enough_coins'; end if;
    update public.profiles set bite_coins = bite_coins - v_cost
    where id = v_uid returning bite_coins into v_coins;
  end if;

  insert into public.competition_entries
    (competition_id, user_id, cook_history_id, title, emoji, image_url, coins_paid)
  values (p_competition_id, v_uid, v_dish.id, v_dish.title, v_dish.emoji, v_dish.image_url, v_cost);

  return jsonb_build_object('already_entered', false, 'coins_paid', v_cost, 'new_coins', v_coins);
end;
$$;

-- Entries of one competition (leaderboard order) + caller's votes today.
create or replace function public.elo_board(p_competition_id uuid)
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
begin
  return jsonb_build_object(
    'votes_today', (select count(*) from public.elo_votes
                    where voter_id = v_uid and created_at >= date_trunc('day', now())),
    'daily_cap', 50,
    'entries', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id, 'title', e.title, 'emoji', e.emoji, 'image_url', e.image_url,
        'elo', e.elo, 'votes', e.votes, 'mine', e.user_id = v_uid,
        'creator', public._user_card(e.user_id)
      ) order by e.elo desc, e.created_at)
      from public.competition_entries e where e.competition_id = p_competition_id
    ), '[]'::jsonb)
  );
end;
$$;

-- One head-to-head vote. K = 32. Max 50 per voter per UTC day; +5 XP each.
create or replace function public.cast_elo_vote(p_winner uuid, p_loser uuid)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_w public.competition_entries;
  v_l public.competition_entries;
  v_today integer;
  v_delta integer;
  v_xp integer;
begin
  if p_winner = p_loser then raise exception 'same_entry'; end if;

  -- Lock both rows in a fixed order so concurrent votes can't deadlock.
  perform 1 from public.competition_entries
  where id in (p_winner, p_loser) order by id for update;

  select * into v_w from public.competition_entries where id = p_winner;
  select * into v_l from public.competition_entries where id = p_loser;
  if v_w.id is null or v_l.id is null then raise exception 'entry_not_found'; end if;
  if v_w.competition_id <> v_l.competition_id then raise exception 'different_competitions'; end if;
  if v_w.user_id = v_uid or v_l.user_id = v_uid then raise exception 'own_entry'; end if;

  select count(*) into v_today from public.elo_votes
  where voter_id = v_uid and created_at >= date_trunc('day', now());
  if v_today >= 50 then
    return jsonb_build_object('capped', true, 'votes_today', v_today);
  end if;

  v_delta := round(32 * (1 - 1 / (1 + power(10, (v_l.elo - v_w.elo) / 400.0))));

  update public.competition_entries set elo = elo + v_delta, votes = votes + 1 where id = v_w.id;
  update public.competition_entries set elo = elo - v_delta, votes = votes + 1 where id = v_l.id;

  insert into public.elo_votes (competition_id, voter_id, winner_entry_id, loser_entry_id, delta)
  values (v_w.competition_id, v_uid, v_w.id, v_l.id, v_delta);

  update public.profiles set xp = xp + 5 where id = v_uid returning xp into v_xp;

  return jsonb_build_object(
    'capped', false,
    'delta', v_delta,
    'winner_elo', v_w.elo + v_delta,
    'loser_elo', v_l.elo - v_delta,
    'votes_today', v_today + 1,
    'xp', 5,
    'new_xp', v_xp
  );
end;
$$;

-- ──────────────────────── 4b. cook-off RPCs ──────────────────────────

create or replace function public._cook_off_status(c public.cook_offs)
returns text
language sql
stable
as $$
  select case
    when c.challenger_id is null then case when c.open_until > now() then 'open' else 'expired' end
    when now() < c.cook_deadline then 'cooking'
    when now() < c.voting_ends_at then 'voting'
    else 'done' end
$$;

create or replace function public._cook_off_json(c public.cook_offs, p_uid uuid)
returns jsonb
language sql
stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'id', c.id,
    'recipe_title', c.recipe_title,
    'emoji', c.emoji,
    'difficulty', c.difficulty,
    'note', c.note,
    'cook_hours', c.cook_hours,
    'status', public._cook_off_status(c),
    'open_until', c.open_until,
    'cook_deadline', c.cook_deadline,
    'voting_ends_at', c.voting_ends_at,
    'defender', public._user_card(c.defender_id),
    'challenger', case when c.challenger_id is null then null else public._user_card(c.challenger_id) end,
    'votes_defender', (select count(*) from public.cook_off_votes v where v.cook_off_id = c.id and v.side = 'defender'),
    'votes_challenger', (select count(*) from public.cook_off_votes v where v.cook_off_id = c.id and v.side = 'challenger'),
    'my_vote', (select v.side from public.cook_off_votes v where v.cook_off_id = c.id and v.voter_id = p_uid),
    'mine', c.defender_id = p_uid or c.challenger_id = p_uid
  )
$$;

create or replace function public.cook_off_board()
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
begin
  return jsonb_build_object(
    'active', coalesce((
      select jsonb_agg(public._cook_off_json(c, v_uid) order by c.voting_ends_at)
      from public.cook_offs c
      where c.challenger_id is not null and c.voting_ends_at > now()), '[]'::jsonb),
    'open', coalesce((
      select jsonb_agg(public._cook_off_json(c, v_uid) order by c.open_until)
      from public.cook_offs c
      where c.challenger_id is null and c.open_until > now()), '[]'::jsonb),
    'mine', coalesce((
      select jsonb_agg(public._cook_off_json(c, v_uid) order by c.created_at desc)
      from (select * from public.cook_offs
            where defender_id = v_uid or challenger_id = v_uid
            order by created_at desc limit 30) c), '[]'::jsonb)
  );
end;
$$;

-- Post an open challenge from a dish in the caller's cook_history.
create or replace function public.start_cook_off(
  p_cook_history_id uuid,
  p_difficulty text default 'Medium',
  p_note text default '',
  p_cook_hours integer default 48
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_dish public.cook_history;
  v_id uuid;
begin
  select * into v_dish from public.cook_history where id = p_cook_history_id and user_id = v_uid;
  if not found then raise exception 'dish_not_found'; end if;

  insert into public.cook_offs (defender_id, recipe_id, recipe_title, emoji, difficulty, note, cook_hours)
  values (v_uid, v_dish.recipe_id, v_dish.title, v_dish.emoji,
          coalesce(nullif(p_difficulty, ''), 'Medium'), left(coalesce(p_note, ''), 140),
          greatest(least(coalesce(p_cook_hours, 48), 168), 1))
  returning id into v_id;
  return v_id;
end;
$$;

-- Accept an open challenge: cooking window starts now, then 48h of voting.
create or replace function public.accept_cook_off(p_cook_off_id uuid)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_c public.cook_offs;
begin
  select * into v_c from public.cook_offs where id = p_cook_off_id for update;
  if not found then raise exception 'cook_off_not_found'; end if;
  if v_c.defender_id = v_uid then raise exception 'own_cook_off'; end if;
  if v_c.challenger_id is not null then raise exception 'already_taken'; end if;
  if v_c.open_until <= now() then raise exception 'cook_off_expired'; end if;

  update public.cook_offs set
    challenger_id = v_uid,
    accepted_at = now(),
    cook_deadline = now() + make_interval(hours => v_c.cook_hours),
    voting_ends_at = now() + make_interval(hours => v_c.cook_hours + 48)
  where id = v_c.id
  returning * into v_c;

  return public._cook_off_json(v_c, v_uid);
end;
$$;

-- One vote per user per cook-off, only while voting and not on your own.
create or replace function public.vote_cook_off(p_cook_off_id uuid, p_side text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_c public.cook_offs;
begin
  if p_side not in ('challenger', 'defender') then raise exception 'invalid_side'; end if;
  select * into v_c from public.cook_offs where id = p_cook_off_id;
  if not found then raise exception 'cook_off_not_found'; end if;
  if public._cook_off_status(v_c) <> 'voting' then raise exception 'not_voting'; end if;
  if v_uid in (v_c.defender_id, v_c.challenger_id) then raise exception 'own_cook_off'; end if;

  insert into public.cook_off_votes (cook_off_id, voter_id, side)
  values (v_c.id, v_uid, p_side)
  on conflict (cook_off_id, voter_id) do nothing;

  return public._cook_off_json(v_c, v_uid);
end;
$$;

-- ─────────────────────── 4c. community impact ────────────────────────

create or replace function public.community_impact()
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_uid uuid := public._require_uid();
  v_charity_id integer;
  v_total bigint;
begin
  select charity_id into v_charity_id from public.profiles where id = v_uid;
  select coalesce(sum(amount_cents), 0) into v_total from public.donations;

  return jsonb_build_object(
    'my_charity', (
      select jsonb_build_object(
        'id', ch.id, 'emoji', ch.emoji, 'name', ch.name,
        'impact_label', ch.impact_label, 'cents_per_unit', ch.cents_per_unit,
        'donated_cents', coalesce((select sum(amount_cents) from public.donations
                                   where user_id = v_uid and charity_id = ch.id), 0),
        'month_cents', coalesce((select sum(amount_cents) from public.donations
                                 where user_id = v_uid and charity_id = ch.id
                                   and created_at >= date_trunc('month', now())), 0))
      from public.charities ch where ch.id = v_charity_id),
    'total_cents', v_total,
    'donors', (select count(distinct user_id) from public.donations),
    'charities', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', ch.id, 'emoji', ch.emoji, 'name', ch.name,
        'impact_label', ch.impact_label, 'cents_per_unit', ch.cents_per_unit,
        'total_cents', s.total
      ) order by s.total desc, ch.sort)
      from public.charities ch
      cross join lateral (
        select coalesce(sum(d.amount_cents), 0)::bigint as total
        from public.donations d where d.charity_id = ch.id) s
      where ch.active
    ), '[]'::jsonb)
  );
end;
$$;

-- ───────────────────────────── grants ────────────────────────────────

do $$
declare f text;
begin
  foreach f in array array[
    'public.competition_board()',
    'public.enter_competition(uuid, uuid)',
    'public.elo_board(uuid)',
    'public.cast_elo_vote(uuid, uuid)',
    'public.cook_off_board()',
    'public.start_cook_off(uuid, text, text, integer)',
    'public.accept_cook_off(uuid)',
    'public.vote_cook_off(uuid, text)',
    'public.community_impact()'
  ] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
