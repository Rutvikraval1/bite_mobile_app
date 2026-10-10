-- ⚠️ WARNING: Deletes ALL rows from every table in the public schema.
-- Table structure, RLS policies, functions and triggers are kept.
-- Not a migration — run manually in Supabase SQL Editor (or psql).

-- Option 1: Truncate every table in public schema (auto-detects new tables)
DO $$
DECLARE
  tbls text;
BEGIN
  SELECT string_agg(format('%I.%I', schemaname, tablename), ', ')
    INTO tbls
    FROM pg_tables
   WHERE schemaname = 'public';

  IF tbls IS NOT NULL THEN
    EXECUTE 'TRUNCATE TABLE ' || tbls || ' RESTART IDENTITY CASCADE';
  END IF;
END $$;

-- Option 2: Explicit list (use this instead if you only want these tables)
TRUNCATE TABLE
  public.comment_likes,
  public.conversation_members,
  public.conversations,
  public.cook_history,
  public.creators,
  public.device_tokens,
  public.drinks,
  public.event_rsvps,
  public.events,
  public.feed_posts,
  public.follows,
  public.meal_plans,
  public.messages,
  public.muted_creators,
  public.notifications,
  public.places,
  public.post_comments,
  public.post_likes,
  public.profiles,
  public.recipes,
  public.reports,
  public.saved_items,
  public.swipes
RESTART IDENTITY CASCADE;

-- Optional: also delete auth users (uncomment if needed)
-- DELETE FROM auth.users;
