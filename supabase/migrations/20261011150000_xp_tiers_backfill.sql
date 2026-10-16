/*
  # Backfill xp_tiers taglines + kitchen rewards

  20261011130000_xp_tiers.sql was applied before its tagline / reward
  columns existed. Re-running it added the columns, but its insert is
  "on conflict do nothing", so existing rows kept a blank tagline and no
  reward. This fills only the blanks, so values edited in the dashboard
  are kept.

  Idempotent — safe to re-run.
*/

update public.xp_tiers t
set tagline = d.tagline
from (values
  (1, 'Just getting started — welcome!'),
  (2, 'Building your kitchen basics'),
  (3, 'You''re mastering the basics!'),
  (4, 'Leveling up your knife skills'),
  (5, 'Cooking like a pro'),
  (6, 'Culinary mastery, unlocked'),
  (7, 'You are a b🌶te Legend')
) as d(level, tagline)
where t.level = d.level and coalesce(trim(t.tagline), '') = '';

update public.xp_tiers t
set reward_emoji = d.emoji, reward_name = d.name
from (values
  (2, '🥄', 'Wooden Spoon'),
  (3, '🍳', 'Cast-Iron Pan'),
  (4, '🔪', 'Chef''s Knife'),
  (5, '🍲', 'Dutch Oven'),
  (6, '🥘', 'Copper Set'),
  (7, '🔥', 'Wood-Fired Oven')
) as d(level, emoji, name)
where t.level = d.level and coalesce(trim(t.reward_name), '') = '';
