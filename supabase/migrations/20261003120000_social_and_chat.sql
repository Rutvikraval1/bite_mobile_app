/*
  # Social + Chat → production

  Backs every Social tab screen (feed, likes, comments, creators, events,
  creator profile) and the Chat tab (DMs, requests, communities, live
  kitchens) with real tables.

  1. creators        — public creator identity, keyed by "@handle" (the same
                       key `follows` already uses). Every profile with a
                       username gets one automatically; seeded catalog
                       creators have no profile_id.
  2. feed_posts      — the Activity feed. post_likes / post_comments /
                       comment_likes hang off it; counters are trigger-kept.
  3. events          — local events + event_rsvps (capacity enforced).
  4. muted_creators  — per-user mute/block list (by handle); reports.
  5. conversations   — dm | group | community | kitchen, with
                       conversation_members and messages.
  6. Triggers that notify (→ push via the send-push webhook) on follow,
     like, comment and new message.
  7. start_dm() RPC — opens (or reuses) a DM with a creator.

  Idempotent — safe to re-run.
*/

-- ───────────────────────────── helpers ─────────────────────────────

-- "Chef_Priya" → "@chef_priya" (matches the follows.creator_handle check).
create or replace function public.handle_of(p_username text)
returns text
language sql
immutable
as $$
  select case
    when coalesce(regexp_replace(lower(p_username), '[^a-z0-9_.]', '', 'g'), '') = '' then null
    else '@' || regexp_replace(lower(p_username), '[^a-z0-9_.]', '', 'g')
  end
$$;

-- Display name used in notification titles.
create or replace function public.actor_name(p_user uuid)
returns text
language sql
stable
security definer set search_path = public
as $$
  select coalesce(nullif(display_name, ''), nullif(username, ''), 'Someone')
  from public.profiles where id = p_user
$$;

-- ───────────────────────────── 1. creators ─────────────────────────

create table if not exists public.creators (
  handle text primary key check (handle ~ '^@[a-z0-9_.]+$'),
  profile_id uuid unique references public.profiles (id) on delete set null,
  display_name text not null default '',
  avatar_emoji text not null default '🧑‍🍳',
  avatar_url text,
  bio text not null default '',
  -- "Korean Cuisine Creator · Seoul → NYC"
  tagline text not null default '',
  -- Creators-tab pill, e.g. "🏆 Top Creator".
  badge text not null default '',
  -- "Cooks You Might Like" pill, e.g. "Loves spicy · Near you".
  reason text not null default '',
  specialties text[] not null default '{}',
  -- Profile chips: [{ "emoji": "🏆", "label": "2x Winner", "color": "#FFD700" }]
  highlights jsonb not null default '[]',
  -- Profile "Recent tips": [{ "user": "@x", "amount": "$5", "dish": "…", "emoji": "🌶", "at": "…" }]
  recent_tips jsonb not null default '[]',
  -- XP for seeded creators (real creators use profiles.xp).
  base_xp integer not null default 0,
  -- Seeded starting counts; real activity is added on top.
  base_followers integer not null default 0,
  base_following integer not null default 0,
  base_recipes integer not null default 0,
  followers_count integer not null default 0,
  following_count integer not null default 0,
  recipes_count integer not null default 0,
  featured_recipe_id integer references public.recipes (id) on delete set null,
  is_featured boolean not null default false,
  is_suggested boolean not null default false,
  sort_order integer not null default 100,
  created_at timestamptz not null default now()
);

alter table public.creators enable row level security;
drop policy if exists "creators_select" on public.creators;
create policy "creators_select" on public.creators for select
  to authenticated using (true);
-- Writes happen only through the triggers below (security definer).

create or replace function public.my_handle()
returns text
language sql
stable
security definer set search_path = public
as $$
  select handle from public.creators where profile_id = auth.uid()
$$;

-- Keep a creators row in sync with each profile that has a username.
create or replace function public.sync_creator_from_profile()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_handle text := public.handle_of(new.username);
  v_old text;
begin
  if v_handle is null or length(v_handle) < 3 then
    return new;
  end if;

  -- Handle already used by a different creator (e.g. a seeded one).
  if exists (
    select 1 from public.creators
    where handle = v_handle and profile_id is distinct from new.id
  ) then
    v_handle := v_handle || '_' || substr(replace(new.id::text, '-', ''), 1, 4);
  end if;

  select handle into v_old from public.creators where profile_id = new.id;

  if v_old is not null and v_old <> v_handle then
    -- Rename: FKs cascade; follows store the handle as plain text.
    update public.creators set handle = v_handle where profile_id = new.id;
    update public.follows set creator_handle = v_handle where creator_handle = v_old;
  end if;

  insert into public.creators (handle, profile_id, display_name, avatar_emoji, avatar_url, bio, specialties)
  values (
    v_handle,
    new.id,
    coalesce(nullif(new.display_name, ''), new.username),
    coalesce(nullif(new.avatar_emoji, ''), '🧑‍🍳'),
    new.avatar_url,
    coalesce(new.bio, ''),
    coalesce(new.cuisines, '{}')
  )
  on conflict (handle) do update set
    display_name = excluded.display_name,
    avatar_emoji = excluded.avatar_emoji,
    avatar_url = excluded.avatar_url,
    bio = excluded.bio,
    specialties = excluded.specialties
  where public.creators.profile_id = new.id;

  return new;
end;
$$;

drop trigger if exists profiles_sync_creator on public.profiles;
create trigger profiles_sync_creator
  after insert or update of username, display_name, avatar_emoji, avatar_url, bio, cuisines
  on public.profiles
  for each row execute function public.sync_creator_from_profile();

-- Follower / following counters + "started following you" notification.
create or replace function public.bump_follow_counts()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_target uuid;
begin
  if tg_op = 'INSERT' then
    update public.creators set followers_count = followers_count + 1 where handle = new.creator_handle;
    update public.creators set following_count = following_count + 1 where profile_id = new.user_id;

    select profile_id into v_target from public.creators where handle = new.creator_handle;
    if v_target is not null and v_target <> new.user_id then
      insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
      values (
        v_target, 'follow',
        public.actor_name(new.user_id) || ' started following you',
        '', '👋', 'creatorProfile',
        jsonb_build_object('handle', (select handle from public.creators where profile_id = new.user_id))
      );
    end if;
  elsif tg_op = 'DELETE' then
    update public.creators set followers_count = greatest(followers_count - 1, 0) where handle = old.creator_handle;
    update public.creators set following_count = greatest(following_count - 1, 0) where profile_id = old.user_id;
  end if;
  return null;
end;
$$;

drop trigger if exists follows_counts on public.follows;
create trigger follows_counts
  after insert or delete on public.follows
  for each row execute function public.bump_follow_counts();

-- Published-recipe counter per creator handle.
create or replace function public.bump_recipe_counts()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and old.status = 'published' then
    update public.creators set recipes_count = greatest(recipes_count - 1, 0) where handle = lower(old.creator);
  end if;
  if tg_op in ('INSERT', 'UPDATE') and new.status = 'published' then
    update public.creators set recipes_count = recipes_count + 1 where handle = lower(new.creator);
  end if;
  return null;
end;
$$;

drop trigger if exists recipes_creator_counts on public.recipes;
create trigger recipes_creator_counts
  after insert or delete or update of status, creator on public.recipes
  for each row execute function public.bump_recipe_counts();

-- ───────────────────────────── 2. feed ─────────────────────────────

create table if not exists public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  -- null for seeded posts.
  user_id uuid default auth.uid() references auth.users (id) on delete cascade,
  author_handle text not null references public.creators (handle) on update cascade on delete cascade,
  type text not null default 'text'
    check (type in ('cooked', 'rated', 'achievement', 'tipped', 'created', 'text')),
  action text not null default '',
  target text not null default '',
  -- Spice emoji shown after the target (🟢/🟠/🔴/🌶/🫑).
  rating text,
  caption text,
  photo_url text,
  has_photo boolean not null default false,
  recipe_id integer references public.recipes (id) on delete set null,
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_feed_posts_created on public.feed_posts (created_at desc);
create index if not exists idx_feed_posts_author on public.feed_posts (author_handle, created_at desc);

alter table public.feed_posts enable row level security;
drop policy if exists "feed_posts_select" on public.feed_posts;
create policy "feed_posts_select" on public.feed_posts for select
  to authenticated using (true);
drop policy if exists "feed_posts_insert_own" on public.feed_posts;
create policy "feed_posts_insert_own" on public.feed_posts for insert
  to authenticated
  with check (user_id = auth.uid() and author_handle = public.my_handle());
drop policy if exists "feed_posts_update_own" on public.feed_posts;
create policy "feed_posts_update_own" on public.feed_posts for update
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "feed_posts_delete_own" on public.feed_posts;
create policy "feed_posts_delete_own" on public.feed_posts for delete
  to authenticated using (user_id = auth.uid());

-- Users can't seed their own counters.
create or replace function public.reset_post_counters()
returns trigger
language plpgsql
as $$
begin
  if new.user_id is not null then
    new.likes_count := 0;
    new.comments_count := 0;
  end if;
  return new;
end;
$$;

drop trigger if exists feed_posts_reset_counters on public.feed_posts;
create trigger feed_posts_reset_counters
  before insert on public.feed_posts
  for each row execute function public.reset_post_counters();

-- Publishing a recipe posts it to the feed.
create or replace function public.post_published_recipe()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_handle text;
begin
  if new.author_id is null or new.status <> 'published' then
    return null;
  end if;
  if tg_op = 'UPDATE' and old.status = 'published' then
    return null;
  end if;
  select handle into v_handle from public.creators where profile_id = new.author_id;
  if v_handle is null then
    return null;
  end if;
  if exists (select 1 from public.feed_posts where recipe_id = new.id and type = 'created') then
    return null;
  end if;
  insert into public.feed_posts (user_id, author_handle, type, action, target, caption, photo_url, has_photo, recipe_id)
  values (
    new.author_id, v_handle, 'created', 'published', new.title,
    'New recipe alert! 🍽️', new.image_url, new.image_url is not null, new.id
  );
  return null;
end;
$$;

drop trigger if exists recipes_post_to_feed on public.recipes;
create trigger recipes_post_to_feed
  after insert or update of status on public.recipes
  for each row execute function public.post_published_recipe();

-- Likes.
create table if not exists public.post_likes (
  post_id uuid not null references public.feed_posts (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index if not exists idx_post_likes_user on public.post_likes (user_id);

alter table public.post_likes enable row level security;
drop policy if exists "post_likes_own" on public.post_likes;
create policy "post_likes_own" on public.post_likes for all
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.bump_post_likes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_owner uuid;
  v_target text;
begin
  if tg_op = 'INSERT' then
    update public.feed_posts set likes_count = likes_count + 1
    where id = new.post_id
    returning user_id, coalesce(nullif(target, ''), 'post') into v_owner, v_target;

    if v_owner is not null and v_owner <> new.user_id then
      insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
      values (
        v_owner, 'post_liked',
        public.actor_name(new.user_id) || ' liked your ' || v_target,
        '', '❤️', 'socialFeed',
        jsonb_build_object('post_id', new.post_id)
      );
    end if;
  elsif tg_op = 'DELETE' then
    update public.feed_posts set likes_count = greatest(likes_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;

drop trigger if exists post_likes_count on public.post_likes;
create trigger post_likes_count
  after insert or delete on public.post_likes
  for each row execute function public.bump_post_likes();

-- Comments.
create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.feed_posts (id) on delete cascade,
  -- null for seeded comments.
  user_id uuid default auth.uid() references auth.users (id) on delete cascade,
  author_handle text not null references public.creators (handle) on update cascade on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 500),
  likes_count integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_post_comments_post on public.post_comments (post_id, created_at desc);

alter table public.post_comments enable row level security;
drop policy if exists "post_comments_select" on public.post_comments;
create policy "post_comments_select" on public.post_comments for select
  to authenticated using (true);
drop policy if exists "post_comments_insert_own" on public.post_comments;
create policy "post_comments_insert_own" on public.post_comments for insert
  to authenticated
  with check (user_id = auth.uid() and author_handle = public.my_handle());
drop policy if exists "post_comments_delete_own" on public.post_comments;
create policy "post_comments_delete_own" on public.post_comments for delete
  to authenticated using (user_id = auth.uid());

create or replace function public.bump_post_comments()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_owner uuid;
  v_target text;
begin
  if tg_op = 'INSERT' then
    update public.feed_posts set comments_count = comments_count + 1
    where id = new.post_id
    returning user_id, coalesce(nullif(target, ''), 'post') into v_owner, v_target;

    if v_owner is not null and new.user_id is not null and v_owner <> new.user_id then
      insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
      values (
        v_owner, 'post_comment',
        public.actor_name(new.user_id) || ' commented on your ' || v_target,
        left(new.body, 140), '💬', 'socialFeed',
        jsonb_build_object('post_id', new.post_id, 'comment_id', new.id)
      );
    end if;
  elsif tg_op = 'DELETE' then
    update public.feed_posts set comments_count = greatest(comments_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;

create or replace function public.reset_comment_counters()
returns trigger
language plpgsql
as $$
begin
  if new.user_id is not null then
    new.likes_count := 0;
  end if;
  return new;
end;
$$;

drop trigger if exists post_comments_reset_counters on public.post_comments;
create trigger post_comments_reset_counters
  before insert on public.post_comments
  for each row execute function public.reset_comment_counters();

drop trigger if exists post_comments_count on public.post_comments;
create trigger post_comments_count
  after insert or delete on public.post_comments
  for each row execute function public.bump_post_comments();

create table if not exists public.comment_likes (
  comment_id uuid not null references public.post_comments (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

alter table public.comment_likes enable row level security;
drop policy if exists "comment_likes_own" on public.comment_likes;
create policy "comment_likes_own" on public.comment_likes for all
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.bump_comment_likes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.post_comments set likes_count = likes_count + 1 where id = new.comment_id;
  elsif tg_op = 'DELETE' then
    update public.post_comments set likes_count = greatest(likes_count - 1, 0) where id = old.comment_id;
  end if;
  return null;
end;
$$;

drop trigger if exists comment_likes_count on public.comment_likes;
create trigger comment_likes_count
  after insert or delete on public.comment_likes
  for each row execute function public.bump_comment_likes();

-- ───────────────────────────── 3. events ───────────────────────────

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  venue text not null default '',
  description text not null default '',
  emoji text not null default '🎪',
  -- tastings | classes | competitions | markets | wine | farm
  category text not null default 'tastings',
  starts_at timestamptz not null,
  ends_at timestamptz,
  distance text not null default '',
  price text not null default 'Free entry',
  color text not null default '#FF6B6B',
  -- null = open event (no limit).
  capacity integer,
  base_attending integer not null default 0,
  attending_count integer not null default 0,
  interested_count integer not null default 0,
  -- Avatar URLs shown before real attendees have photos.
  sample_avatars text[] not null default '{}',
  is_featured boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_events_starts on public.events (starts_at);

alter table public.events enable row level security;
drop policy if exists "events_select" on public.events;
create policy "events_select" on public.events for select
  to authenticated using (true);

create table if not exists public.event_rsvps (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

alter table public.event_rsvps enable row level security;
drop policy if exists "event_rsvps_select" on public.event_rsvps;
create policy "event_rsvps_select" on public.event_rsvps for select
  to authenticated using (true);
drop policy if exists "event_rsvps_insert_own" on public.event_rsvps;
create policy "event_rsvps_insert_own" on public.event_rsvps for insert
  to authenticated with check (user_id = auth.uid());
drop policy if exists "event_rsvps_delete_own" on public.event_rsvps;
create policy "event_rsvps_delete_own" on public.event_rsvps for delete
  to authenticated using (user_id = auth.uid());

create or replace function public.bump_event_rsvps()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_capacity integer;
  v_going integer;
begin
  if tg_op = 'INSERT' then
    select capacity, base_attending + attending_count into v_capacity, v_going
    from public.events where id = new.event_id for update;
    if v_capacity is not null and v_going >= v_capacity then
      raise exception 'event_sold_out' using errcode = 'P0001';
    end if;
    update public.events set attending_count = attending_count + 1 where id = new.event_id;
    return new;
  else
    update public.events set attending_count = greatest(attending_count - 1, 0) where id = old.event_id;
    return old;
  end if;
end;
$$;

drop trigger if exists event_rsvps_count on public.event_rsvps;
create trigger event_rsvps_count
  before insert or delete on public.event_rsvps
  for each row execute function public.bump_event_rsvps();

-- ───────────────────── 4. mute / block / report ────────────────────

create table if not exists public.muted_creators (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  creator_handle text not null check (creator_handle ~ '^@[a-z0-9_.]+$'),
  kind text not null default 'mute' check (kind in ('mute', 'block')),
  created_at timestamptz not null default now(),
  primary key (user_id, creator_handle)
);

alter table public.muted_creators enable row level security;
drop policy if exists "muted_creators_own" on public.muted_creators;
create policy "muted_creators_own" on public.muted_creators for all
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- creator | post | comment | conversation | message
  target_type text not null,
  target_id text not null,
  reason text not null default '',
  status text not null default 'open'
    check (status in ('open', 'reviewed', 'actioned', 'dismissed')),
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;
-- Users file reports and see their own; only admins (service role) review.
drop policy if exists "reports_insert_own" on public.reports;
create policy "reports_insert_own" on public.reports for insert
  to authenticated with check (reporter_id = auth.uid() and status = 'open');
drop policy if exists "reports_select_own" on public.reports;
create policy "reports_select_own" on public.reports for select
  to authenticated using (reporter_id = auth.uid());

-- ───────────────────────────── 5. chat ─────────────────────────────

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('dm', 'group', 'community', 'kitchen')),
  name text not null default '',
  emoji text not null default '💬',
  description text not null default '',
  -- Community tab: foodies | creators | critics.
  tier text,
  -- Level name needed to enter (e.g. "Sous Chef"); null = open.
  unlock_level text,
  color text not null default '#FF6B6B',
  is_live boolean not null default false,
  base_members integer not null default 0,
  members_count integer not null default 0,
  sort_order integer not null default 100,
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  last_message_at timestamptz,
  last_message_preview text not null default '',
  last_sender_id uuid,
  created_at timestamptz not null default now()
);
create index if not exists idx_conversations_kind on public.conversations (kind, sort_order);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  -- pending = message request the user hasn't accepted yet.
  status text not null default 'accepted' check (status in ('accepted', 'pending')),
  muted boolean not null default false,
  last_read_at timestamptz not null default now(),
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create index if not exists idx_conversation_members_user on public.conversation_members (user_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  -- null for seeded room messages.
  sender_id uuid default auth.uid() references public.profiles (id) on delete set null,
  sender_name text not null default '',
  body text not null default '',
  recipe_id integer references public.recipes (id) on delete set null,
  created_at timestamptz not null default now(),
  check (char_length(body) <= 2000),
  check (char_length(trim(body)) > 0 or recipe_id is not null)
);
create index if not exists idx_messages_conversation on public.messages (conversation_id, created_at);

create or replace function public.is_conversation_member(p_conversation uuid, p_status text default null)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = p_conversation
      and user_id = auth.uid()
      and (p_status is null or status = p_status)
  )
$$;

create or replace function public.is_public_room(p_conversation uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.conversations
    where id = p_conversation and kind in ('community', 'kitchen')
  )
$$;

alter table public.conversations enable row level security;
drop policy if exists "conversations_select" on public.conversations;
create policy "conversations_select" on public.conversations for select
  to authenticated
  using (kind in ('community', 'kitchen') or public.is_conversation_member(id));
-- DMs are created by start_dm(); rooms by admins.

alter table public.conversation_members enable row level security;
drop policy if exists "conversation_members_select" on public.conversation_members;
create policy "conversation_members_select" on public.conversation_members for select
  to authenticated
  using (user_id = auth.uid() or public.is_conversation_member(conversation_id));
drop policy if exists "conversation_members_join_room" on public.conversation_members;
create policy "conversation_members_join_room" on public.conversation_members for insert
  to authenticated
  with check (
    user_id = auth.uid() and status = 'accepted' and public.is_public_room(conversation_id)
  );
drop policy if exists "conversation_members_update_own" on public.conversation_members;
create policy "conversation_members_update_own" on public.conversation_members for update
  to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "conversation_members_delete_own" on public.conversation_members;
create policy "conversation_members_delete_own" on public.conversation_members for delete
  to authenticated using (user_id = auth.uid());

alter table public.messages enable row level security;
drop policy if exists "messages_select" on public.messages;
create policy "messages_select" on public.messages for select
  to authenticated
  using (public.is_public_room(conversation_id) or public.is_conversation_member(conversation_id));
drop policy if exists "messages_insert_member" on public.messages;
create policy "messages_insert_member" on public.messages for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_member(conversation_id, 'accepted')
  );
drop policy if exists "messages_delete_own" on public.messages;
create policy "messages_delete_own" on public.messages for delete
  to authenticated using (sender_id = auth.uid());

create or replace function public.bump_room_members()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.conversations set members_count = members_count + 1 where id = new.conversation_id;
  elsif tg_op = 'DELETE' then
    update public.conversations set members_count = greatest(members_count - 1, 0) where id = old.conversation_id;
  end if;
  return null;
end;
$$;

drop trigger if exists conversation_members_count on public.conversation_members;
create trigger conversation_members_count
  after insert or delete on public.conversation_members
  for each row execute function public.bump_room_members();

-- Blocked senders can't DM the person who blocked them.
create or replace function public.guard_message()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_my_handle text;
begin
  if new.sender_id is null then
    return new;
  end if;
  new.sender_name := public.actor_name(new.sender_id);
  select handle into v_my_handle from public.creators where profile_id = new.sender_id;
  if v_my_handle is not null and exists (
    select 1
    from public.conversation_members m
    join public.conversations c on c.id = m.conversation_id and c.kind = 'dm'
    join public.muted_creators b on b.user_id = m.user_id
      and b.creator_handle = v_my_handle and b.kind = 'block'
    where m.conversation_id = new.conversation_id and m.user_id <> new.sender_id
  ) then
    raise exception 'blocked' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists messages_guard on public.messages;
create trigger messages_guard
  before insert on public.messages
  for each row execute function public.guard_message();

-- Update the conversation preview and notify the other members.
create or replace function public.after_message()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_kind text;
  v_name text;
  v_preview text := case
    when char_length(trim(new.body)) > 0 then left(new.body, 140)
    else '🍽 Shared a recipe'
  end;
begin
  update public.conversations
  set last_message_at = new.created_at,
      last_message_preview = v_preview,
      last_sender_id = new.sender_id
  where id = new.conversation_id
  returning kind, name into v_kind, v_name;

  if new.sender_id is not null then
    update public.conversation_members set last_read_at = new.created_at
    where conversation_id = new.conversation_id and user_id = new.sender_id;
  end if;

  if new.sender_id is null or v_kind not in ('dm', 'group') then
    return null;
  end if;

  insert into public.notifications (user_id, type, title, body, emoji, action_dest, data)
  select
    m.user_id,
    case when m.status = 'pending' then 'message_request' else 'message' end,
    case
      when m.status = 'pending' then new.sender_name || ' wants to message you'
      when v_kind = 'group' then new.sender_name || ' in ' || v_name
      else new.sender_name
    end,
    v_preview, '💬', 'chatThread',
    jsonb_build_object('conversation_id', new.conversation_id)
  from public.conversation_members m
  where m.conversation_id = new.conversation_id
    and m.user_id <> new.sender_id
    and not m.muted;

  return null;
end;
$$;

drop trigger if exists messages_after_insert on public.messages;
create trigger messages_after_insert
  after insert on public.messages
  for each row execute function public.after_message();

-- Open (or reuse) a DM with a creator. Returns the conversation id.
-- The other person gets it as a request unless they follow the caller.
create or replace function public.start_dm(p_handle text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_other uuid;
  v_my_handle text;
  v_conv uuid;
  v_status text;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  select profile_id into v_other from public.creators where handle = lower(p_handle);
  if v_other is null then
    raise exception 'not_messageable' using errcode = 'P0001';
  end if;
  if v_other = v_me then
    raise exception 'cannot_message_self' using errcode = 'P0001';
  end if;

  select c.id into v_conv
  from public.conversations c
  join public.conversation_members a on a.conversation_id = c.id and a.user_id = v_me
  join public.conversation_members b on b.conversation_id = c.id and b.user_id = v_other
  where c.kind = 'dm'
  limit 1;
  if v_conv is not null then
    return v_conv;
  end if;

  select handle into v_my_handle from public.creators where profile_id = v_me;
  v_status := case
    when v_my_handle is not null and exists (
      select 1 from public.follows where user_id = v_other and creator_handle = v_my_handle
    ) then 'accepted'
    else 'pending'
  end;

  insert into public.conversations (kind, created_by) values ('dm', v_me) returning id into v_conv;
  insert into public.conversation_members (conversation_id, user_id, status)
  values (v_conv, v_me, 'accepted'), (v_conv, v_other, v_status);
  return v_conv;
end;
$$;
revoke all on function public.start_dm(text) from public, anon;
grant execute on function public.start_dm(text) to authenticated;

-- ───────────────────────────── realtime ────────────────────────────

do $$
declare
  t text;
begin
  foreach t in array array['messages', 'conversation_members'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
exception when undefined_object then
  null; -- publication missing on self-hosted setups
end $$;

-- ───────────────────────────── backfill ────────────────────────────

-- Creators for every existing profile with a username.
update public.profiles set username = username where username <> '';

-- Recipe counts for every creator.
update public.creators c
set recipes_count = (
  select count(*) from public.recipes r
  where lower(r.creator) = c.handle and r.status = 'published'
);

-- Follower / following counts from existing follows.
update public.creators c
set followers_count = (select count(*) from public.follows f where f.creator_handle = c.handle),
    following_count = coalesce(
      (select count(*) from public.follows f where f.user_id = c.profile_id), 0
    );
