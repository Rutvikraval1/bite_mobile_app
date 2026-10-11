/*
  # Daily chest → server-side, once per day

  The daily chest used to roll its rewards on the device, add them twice
  (on open and on "Collect"), and set profiles.daily_chest_claimed = true
  forever, so it never came back after the first claim.

  1. daily_chest_claims — one row per user per local calendar day: what the
     chest gave (coins, XP, shard, streak bonus).
  2. daily_chest_status(p_utc_offset_min) — claimed today?, chest streak,
     when the next chest unlocks.
  3. claim_daily_chest(p_premium, p_utc_offset_min) — rolls the rewards on
     the server, adds them to profiles.xp / bite_coins atomically, records
     the claim, and returns the rewards plus the new totals. A second claim
     on the same day returns already_claimed instead.

  Chest streak: claiming on consecutive days adds +10% coins per day,
  capped at +60% (day 7+). Missing a day resets it.

  The day boundary is the user's local midnight: the app passes its UTC
  offset in minutes (clamped to ±14h).

  Idempotent — safe to re-run.
*/

-- ───────────────────────── 1. daily_chest_claims ─────────────────────

create table if not exists public.daily_chest_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  claim_date date not null,
  chest_type text not null check (chest_type in ('free', 'premium')),
  coins integer not null check (coins >= 0),
  xp integer not null check (xp >= 0),
  shard text,
  chest_streak integer not null default 1,
  created_at timestamptz not null default now(),
  unique (user_id, claim_date)
);
create index if not exists idx_daily_chest_claims_user
  on public.daily_chest_claims (user_id, claim_date desc);

alter table public.daily_chest_claims enable row level security;

-- Users read their own history; writes only go through claim_daily_chest().
drop policy if exists "daily_chest_claims_select_own" on public.daily_chest_claims;
create policy "daily_chest_claims_select_own" on public.daily_chest_claims for select
  to authenticated using (user_id = auth.uid());

-- ───────────────────────────── helpers ───────────────────────────────

create or replace function public._chest_today(p_utc_offset_min integer)
returns date
language sql
stable
as $$
  select (now() at time zone 'UTC'
          + make_interval(mins => greatest(least(coalesce(p_utc_offset_min, 0), 840), -840)))::date
$$;

-- Next local midnight, as an absolute timestamp.
create or replace function public._chest_next_at(p_utc_offset_min integer)
returns timestamptz
language sql
stable
as $$
  select ((public._chest_today(p_utc_offset_min) + 1)::timestamp
          - make_interval(mins => greatest(least(coalesce(p_utc_offset_min, 0), 840), -840)))
         at time zone 'UTC'
$$;

-- ───────────────────────────── 2. status ─────────────────────────────

create or replace function public.daily_chest_status(p_utc_offset_min integer default 0)
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := public._chest_today(p_utc_offset_min);
  v_last public.daily_chest_claims;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select * into v_last from public.daily_chest_claims
  where user_id = v_uid order by claim_date desc limit 1;

  return jsonb_build_object(
    'claimed_today', v_last.claim_date is not null and v_last.claim_date = v_today,
    -- Streak still alive if the last claim was today or yesterday.
    'chest_streak', case
      when v_last.claim_date is not null and v_last.claim_date >= v_today - 1
        then v_last.chest_streak
      else 0 end,
    'next_at', public._chest_next_at(p_utc_offset_min),
    'last', case when v_last.id is null then null else jsonb_build_object(
      'coins', v_last.coins, 'xp', v_last.xp, 'shard', v_last.shard,
      'type', v_last.chest_type, 'date', v_last.claim_date) end
  );
end;
$$;

-- ───────────────────────────── 3. claim ──────────────────────────────

create or replace function public.claim_daily_chest(
  p_premium boolean default false,
  p_utc_offset_min integer default 0
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := public._chest_today(p_utc_offset_min);
  v_is_premium boolean;
  v_last date;
  v_last_streak integer;
  v_streak integer;
  v_coins integer;
  v_xp integer;
  v_bonus integer;
  v_shard text;
  v_type text := case when p_premium then 'premium' else 'free' end;
  v_new_xp integer;
  v_new_coins integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select is_premium into v_is_premium from public.profiles where id = v_uid for update;
  if not found then
    raise exception 'profile_not_found';
  end if;
  if p_premium and not coalesce(v_is_premium, false) then
    raise exception 'premium_required' using errcode = '42501';
  end if;

  select claim_date, chest_streak into v_last, v_last_streak
  from public.daily_chest_claims
  where user_id = v_uid order by claim_date desc limit 1;

  if v_last = v_today then
    return jsonb_build_object(
      'already_claimed', true,
      'next_at', public._chest_next_at(p_utc_offset_min)
    );
  end if;

  v_streak := case when v_last = v_today - 1 then coalesce(v_last_streak, 0) + 1 else 1 end;

  if p_premium then
    v_coins := 25 + floor(random() * 76)::int;   -- 25–100
    v_xp    := 5 + floor(random() * 16)::int;    -- 5–20
    v_shard := (array['Rare Galaxy Swirl Shard ✨', 'Rare Ember Glow Shard 🔥',
                      'Rare Golden Whisk Shard 🥄'])[1 + floor(random() * 3)::int];
  else
    v_coins := 5 + floor(random() * 21)::int;    -- 5–25
    v_xp    := 1 + floor(random() * 5)::int;     -- 1–5
    v_shard := (array['Common Frame Shard', 'Common Spice Shard 🌶',
                      'Common Herb Shard 🌿'])[1 + floor(random() * 3)::int];
  end if;

  -- +10% coins per consecutive day, max +60%.
  v_bonus := floor(v_coins * least(v_streak - 1, 6) * 0.10)::int;
  v_coins := v_coins + v_bonus;

  insert into public.daily_chest_claims (user_id, claim_date, chest_type, coins, xp, shard, chest_streak)
  values (v_uid, v_today, v_type, v_coins, v_xp, v_shard, v_streak);

  update public.profiles
  set xp = xp + v_xp,
      bite_coins = bite_coins + v_coins,
      daily_chest_claimed = true
  where id = v_uid
  returning xp, bite_coins into v_new_xp, v_new_coins;

  return jsonb_build_object(
    'already_claimed', false,
    'type', v_type,
    'coins', v_coins,
    'streak_bonus', v_bonus,
    'xp', v_xp,
    'shard', v_shard,
    'chest_streak', v_streak,
    'new_xp', v_new_xp,
    'new_coins', v_new_coins,
    'next_at', public._chest_next_at(p_utc_offset_min)
  );
exception
  when unique_violation then
    -- Two taps raced; the other one won.
    return jsonb_build_object(
      'already_claimed', true,
      'next_at', public._chest_next_at(p_utc_offset_min)
    );
end;
$$;

revoke all on function public.daily_chest_status(integer) from public, anon;
grant execute on function public.daily_chest_status(integer) to authenticated;
revoke all on function public.claim_daily_chest(boolean, integer) from public, anon;
grant execute on function public.claim_daily_chest(boolean, integer) to authenticated;
