/*
  # Social + Chat seed content

  The content the app used to hardcode in `mock_social_data.dart`, now as
  rows: creators, Activity feed posts + comments, local events, community
  rooms and live kitchens. Real user activity is added on top.

  Event dates are relative to when this runs, so events start out upcoming.

  Idempotent — fixed ids + `on conflict do nothing`.
*/

-- ───────────────────────────── creators ────────────────────────────

insert into public.creators
  (handle, display_name, avatar_emoji, avatar_url, tagline, bio, badge, reason, specialties, highlights, recent_tips,
   base_xp, base_followers, base_following, base_recipes, featured_recipe_id, is_featured, is_suggested, sort_order)
values
  ('@chefpriya', 'Priya Kim', '🍗', 'https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80',
   'Korean Cuisine Creator · Seoul → NYC',
   'Bringing the heat from Seoul to your kitchen 🌶🔥 Traditional meets modern. 2x b🌶te Challenge winner.',
   '🏆 Top Creator', '',
   '{"🇰🇷 Korean","🌶 Spicy","🍗 Fried Chicken","🥘 Stews","🥟 Dumplings","🔥 Grilling"}',
   '[{"emoji":"🏆","label":"2x Winner","color":"#FFD700"},{"emoji":"🔥","label":"Top Creator","color":"#FF6B6B"},{"emoji":"📸","label":"500+ Cooks","color":"#4ECDC4"},{"emoji":"⭐","label":"4.9 Rating","color":"#FFB347"}]',
   '[{"user":"@foodielisa","amount":"$5","dish":"Gochujang Chicken","emoji":"🌶","hours_ago":2},{"user":"@marco.eats","amount":"$3","dish":"Kimchi Jjigae","emoji":"🍲","hours_ago":24},{"user":"@noodlequeen","amount":"$10","dish":"Tteokbokki","emoji":"🌶","hours_ago":72}]',
   50, 24000, 1800, 36, (select id from public.recipes where id = 1), true, false, 1),
  ('@marco.eats', 'Marco Eats', '🍄', 'https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80',
   'Italian Comfort Food', '', '🔥 Trending Cook', '', '{"🇮🇹 Italian","🍝 Pasta","🍄 Risotto"}', '[]', '[]',
   200, 36000, 640, 72, (select id from public.recipes where id = 2), true, false, 2),
  ('@bangkokbites', 'Bangkokbites', '🥘', 'https://images.pexels.com/photos/16120625?auto=compress&cs=tinysrgb&w=80',
   'Thai Street Food', '', '⭐ Rising Star', '', '{"🇹🇭 Thai","🍜 Noodles","🌶 Spicy"}', '[]', '[]',
   50, 76000, 410, 110, (select id from public.recipes where id = 7), true, false, 3),
  ('@sarah_bakes', 'Sarah Bakes', '🦞', 'https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80',
   'Baker & Comfort Classics', '', '💎 Community Fave', '', '{"🧁 Baking","🧀 Comfort","🦞 Seafood"}', '[]', '[]',
   15, 60000, 920, 147, (select id from public.recipes where id = 6), true, false, 4),
  ('@tastythai', 'Tasty Thai', '🥭', null, '', '', '', '', '{}', '[]', '[]', 15, 3100, 120, 0, (select id from public.recipes where id = 3), false, false, 100),
  ('@sushilover', 'Sushi Lover', '🍣', 'https://images.pexels.com/photos/30795870?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 400, 2200, 300, 0, null, false, false, 100),
  ('@abuelitas_kitchen', 'Abuelita''s Kitchen', '🌮', 'https://images.pexels.com/photos/30269649?auto=compress&cs=tinysrgb&w=80',
   'Mexican Home Cooking', '', '', '', '{"🇲🇽 Mexican","🌮 Tacos"}', '[]', '[]', 200, 18000, 200, 40, (select id from public.recipes where id = 5), false, false, 100),
  ('@barista_ko', 'Barista Ko', '🍳', 'https://images.pexels.com/photos/19248892?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 5, 900, 150, 0, null, false, false, 100),
  ('@healthnut_amy', 'Healthnut Amy', '🍛', 'https://images.pexels.com/photos/9271168?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 5, 4300, 210, 0, null, false, false, 100),
  ('@grillmaster', 'Grillmaster', '🥡', 'https://images.pexels.com/photos/14950779?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 100, 7800, 180, 0, null, false, false, 100),
  ('@foodielisa', 'Foodie Lisa', '🫒', 'https://images.pexels.com/photos/38366748?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 50, 5100, 330, 0, null, false, false, 100),
  ('@pastaking', 'Pasta King', '🥐', 'https://images.pexels.com/photos/33970123?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 200, 6400, 260, 0, null, false, false, 100),
  ('@seoulfoods', 'Seoul Foods', '🍜', 'https://images.pexels.com/photos/19244211?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 50, 3900, 140, 0, null, false, false, 100),
  ('@noodlequeen', 'Noodle Queen', '🍜', 'https://images.pexels.com/photos/1820559?auto=compress&cs=tinysrgb&w=80',
   '', '', '', '', '{}', '[]', '[]', 40, 2600, 90, 0, null, false, false, 100),
  ('@spice.mama', 'Spice Mama', '👩‍🍳', null, '', '', '', 'Loves spicy · Near you', '{"🌶 Spicy"}', '[]', '[]',
   40, 2100, 150, 34, null, false, true, 10),
  ('@keto.king', 'Keto King', '🥑', null, '', '', '', 'Same diet · Keto', '{"🥑 Keto"}', '[]', '[]',
   100, 5800, 230, 67, null, false, true, 11),
  ('@seoul.eats', 'Seoul Eats', '🍜', null, '', '', '', 'Korean cuisine fan', '{"🇰🇷 Korean"}', '[]', '[]',
   200, 12000, 300, 89, null, false, true, 12),
  ('@plantbased.pro', 'Plantbased Pro', '🥬', null, '', '', '', 'Vegan community', '{"🌱 Vegan"}', '[]', '[]',
   200, 8300, 410, 112, null, false, true, 13),
  ('@spiceroute', 'Spice Route', '🌶', null, '', '', '', '', '{}', '[]', '[]', 40, 800, 60, 0, null, false, false, 100),
  ('@wok_master', 'Wok Master', '🥡', null, '', '', '', '', '{}', '[]', '[]', 100, 1500, 80, 0, null, false, false, 100),
  ('@home_cook_42', 'Home Cook 42', '🍳', null, '', '', '', '', '{}', '[]', '[]', 5, 40, 20, 0, null, false, false, 100),
  ('@sushilab', 'Sushi Lab', '🍣', null, '', '', '', '', '{}', '[]', '[]', 40, 1200, 70, 0, null, false, false, 100),
  ('@brunch_baby', 'Brunch Baby', '🥞', null, '', '', '', '', '{}', '[]', '[]', 15, 300, 45, 0, null, false, false, 100),
  ('@late_night_eats', 'Late Night Eats', '🌙', null, '', '', '', '', '{}', '[]', '[]', 15, 650, 50, 0, null, false, false, 100)
on conflict (handle) do nothing;

-- Every other catalog recipe author becomes a (seeded) creator too.
insert into public.creators (handle, display_name)
select distinct lower(r.creator), initcap(replace(replace(substr(lower(r.creator), 2), '_', ' '), '.', ' '))
from public.recipes r
where lower(r.creator) ~ '^@[a-z0-9_.]+$'
on conflict (handle) do nothing;

update public.creators c
set recipes_count = (
  select count(*) from public.recipes r
  where lower(r.creator) = c.handle and r.status = 'published'
);

-- ───────────────────────────── feed posts ──────────────────────────

insert into public.feed_posts
  (id, user_id, author_handle, type, action, target, rating, caption, has_photo, photo_url, recipe_id, likes_count, comments_count, created_at)
values
  ('f0000000-0000-4000-8000-000000000001', null, '@chefpriya', 'cooked', 'cooked', 'Gochujang Glazed Fried Chicken', '🔴',
   'This one''s a keeper 🔥', true, (select image_url from public.recipes where id = 1), (select id from public.recipes where id = 1), 61, 0, now() - interval '12 minutes'),
  ('f0000000-0000-4000-8000-000000000002', null, '@marco.eats', 'rated', 'rated', 'Truffle Mushroom Risotto', '🌶',
   null, false, null, (select id from public.recipes where id = 2), 76, 0, now() - interval '25 minutes'),
  ('f0000000-0000-4000-8000-000000000003', null, '@tastythai', 'cooked', 'cooked', 'Mango Sticky Rice Bowl', '🟠',
   'Weeknight win ⚡', true, (select image_url from public.recipes where id = 3), (select id from public.recipes where id = 3), 212, 0, now() - interval '1 hour'),
  ('f0000000-0000-4000-8000-000000000004', null, '@sushilover', 'achievement', 'leveled up to', 'Chef 🧑‍🍳', null,
   null, false, null, null, 44, 0, now() - interval '90 minutes'),
  ('f0000000-0000-4000-8000-000000000005', null, '@abuelitas_kitchen', 'cooked', 'cooked', 'Birria Street Tacos', '🔴',
   'Extra garlic is the move 🧄', true, (select image_url from public.recipes where id = 5), (select id from public.recipes where id = 5), 324, 0, now() - interval '2 hours'),
  ('f0000000-0000-4000-8000-000000000006', null, '@sarah_bakes', 'tipped', 'tipped', '$5 tip', null,
   'Amazing recipe!', false, null, null, 18, 0, now() - interval '3 hours'),
  ('f0000000-0000-4000-8000-000000000007', null, '@bangkokbites', 'created', 'published', 'Pad See Ew', null,
   'New recipe alert! 🍽️', true, (select image_url from public.recipes where id = 7), (select id from public.recipes where id = 7), 152, 0, now() - interval '4 hours'),
  ('f0000000-0000-4000-8000-000000000008', null, '@barista_ko', 'cooked', 'mixed', 'Shakshuka', '🟠',
   'So smooth', true, (select image_url from public.recipes where id = 8), (select id from public.recipes where id = 8), 39, 0, now() - interval '5 hours'),
  ('f0000000-0000-4000-8000-000000000009', null, '@healthnut_amy', 'text', 'shared a thought', '', null,
   'PSA: let your steak rest as long as you cooked it. Changed my whole game 🥩', false, null, null, 88, 0, now() - interval '330 minutes'),
  ('f0000000-0000-4000-8000-000000000010', null, '@grillmaster', 'cooked', 'cooked', 'Kung Pao Chicken', '🟠',
   'Slow cooked for hours 🤤', true, (select image_url from public.recipes where id = 16), (select id from public.recipes where id = 16), 71, 0, now() - interval '7 hours'),
  ('f0000000-0000-4000-8000-000000000011', null, '@foodielisa', 'cooked', 'cooked', 'Grilled Lamb Souvlaki', '🔴',
   'Simple perfection 🧀', true, (select image_url from public.recipes where id = 17), (select id from public.recipes where id = 17), 55, 0, now() - interval '9 hours'),
  ('f0000000-0000-4000-8000-000000000012', null, '@pastaking', 'text', 'asked', '', null,
   'What''s everyone cooking this week? Need inspo 💭', false, null, null, 63, 0, now() - interval '10 hours'),
  ('f0000000-0000-4000-8000-000000000013', null, '@seoulfoods', 'rated', 'rated', 'Pho Bo', '🟠',
   null, false, null, (select id from public.recipes where id = 19), 29, 0, now() - interval '12 hours')
on conflict (id) do nothing;

-- ───────────────────────────── comments ────────────────────────────
-- comments_count on each post is maintained by the post_comments trigger.

insert into public.post_comments (id, post_id, user_id, author_handle, body, likes_count, created_at)
values
  ('c0000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', null, '@noodlequeen', 'This looks incredible! 🔥', 12, now() - interval '2 minutes'),
  ('c0000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000001', null, '@marco.eats', 'Need the recipe ASAP!', 5, now() - interval '8 minutes'),
  ('c0000000-0000-4000-8000-000000000003', 'f0000000-0000-4000-8000-000000000001', null, '@sarah_bakes', 'The plating is gorgeous 😍', 8, now() - interval '10 minutes'),
  ('c0000000-0000-4000-8000-000000000004', 'f0000000-0000-4000-8000-000000000005', null, '@bangkokbites', 'Reminds me of my grandma''s version', 3, now() - interval '1 hour'),
  ('c0000000-0000-4000-8000-000000000005', 'f0000000-0000-4000-8000-000000000005', null, '@foodielisa', 'Added to my must-try list!', 2, now() - interval '90 minutes'),
  ('c0000000-0000-4000-8000-000000000006', 'f0000000-0000-4000-8000-000000000003', null, '@chefpriya', 'Try adding a pinch of MSG, game changer 🤌', 24, now() - interval '40 minutes'),
  ('c0000000-0000-4000-8000-000000000007', 'f0000000-0000-4000-8000-000000000005', null, '@spiceroute', 'Made this last night, my family DEVOURED it', 18, now() - interval '100 minutes'),
  ('c0000000-0000-4000-8000-000000000008', 'f0000000-0000-4000-8000-000000000007', null, '@tastythai', 'Substituted with what I had in the fridge, still 🔥', 7, now() - interval '3 hours'),
  ('c0000000-0000-4000-8000-000000000009', 'f0000000-0000-4000-8000-000000000010', null, '@wok_master', 'Pro tip: rest the protein 5 min before saucing', 31, now() - interval '6 hours'),
  ('c0000000-0000-4000-8000-000000000010', 'f0000000-0000-4000-8000-000000000008', null, '@home_cook_42', 'First time cooking this cuisine, easier than I thought!', 4, now() - interval '4 hours'),
  ('c0000000-0000-4000-8000-000000000011', 'f0000000-0000-4000-8000-000000000007', null, '@sushilab', 'Could you do a video version of this?', 9, now() - interval '200 minutes'),
  ('c0000000-0000-4000-8000-000000000012', 'f0000000-0000-4000-8000-000000000005', null, '@abuelitas_kitchen', '10/10 would marry whoever made this', 47, now() - interval '110 minutes'),
  ('c0000000-0000-4000-8000-000000000013', 'f0000000-0000-4000-8000-000000000012', null, '@brunch_baby', 'saving this for the weekend ❤️', 6, now() - interval '9 hours'),
  ('c0000000-0000-4000-8000-000000000014', 'f0000000-0000-4000-8000-000000000009', null, '@late_night_eats', 'perfect 2am craving fix tbh', 11, now() - interval '5 hours')
on conflict (id) do nothing;

-- ───────────────────────────── events ──────────────────────────────

insert into public.events
  (id, title, venue, description, emoji, category, starts_at, ends_at, distance, price, color, capacity,
   base_attending, interested_count, sample_avatars, is_featured)
values
  ('e0000000-0000-4000-8000-000000000001', 'Downtown Farmers Market & Food Fest', 'Downtown Plaza',
   '50+ local vendors, live cooking demos, tastings from top b🌶te creators, and a kids cooking workshop.',
   '🎪', 'markets',
   date_trunc('day', now()) + ((6 - extract(dow from now())::int + 7) % 7) * interval '1 day' + interval '11 hours',
   date_trunc('day', now()) + ((6 - extract(dow from now())::int + 7) % 7) * interval '1 day' + interval '15 hours',
   '2.4 mi', 'Free', '#FF6B6B', null, 234, 89,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/16120625?auto=compress&cs=tinysrgb&w=80"}',
   true),
  ('e0000000-0000-4000-8000-000000000002', 'Thai Street Food Pop-Up', 'The Kitchen Collective', '', '🥘', 'tastings',
   date_trunc('day', now()) + interval '2 days 18 hours', null, '1.8 mi', '$25/person', '#FF6B6B', 79, 67, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false),
  ('e0000000-0000-4000-8000-000000000003', 'Wine & Cheese Pairing Night', 'Cellar Door Wine Bar', '', '🍷', 'wine',
   date_trunc('day', now()) + interval '4 days 19 hours 30 minutes', null, '3.2 mi', '$45/person', '#9B59B6', 50, 42, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false),
  ('e0000000-0000-4000-8000-000000000004', 'Beginner Sushi Rolling Class', 'Omakase by Sato', '', '🍣', 'classes',
   date_trunc('day', now()) + interval '5 days 14 hours', null, '0.8 mi', '$60/person', '#5DADE2', 24, 18, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false),
  ('e0000000-0000-4000-8000-000000000005', 'BBQ & Brew Festival', 'Riverside Park', '', '🍖', 'competitions',
   date_trunc('day', now()) + interval '8 days 12 hours', null, '4.1 mi', 'Free entry', '#FFB347', null, 412, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false),
  ('e0000000-0000-4000-8000-000000000006', 'Sourdough Bread Workshop', 'Flour Power Bakery', '', '🍞', 'classes',
   date_trunc('day', now()) + interval '10 days 10 hours', null, '2.5 mi', '$35/person', '#8B4513', 28, 24, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false),
  ('e0000000-0000-4000-8000-000000000007', 'Farm-to-Table Dinner', 'Green Acres Farm', '', '🌿', 'farm',
   date_trunc('day', now()) + interval '12 days 18 hours 30 minutes', null, '8.3 mi', '$85/person', '#4CAF50', 36, 36, 0,
   '{"https://images.pexels.com/photos/34238049?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/19420186?auto=compress&cs=tinysrgb&w=80","https://images.pexels.com/photos/1820575?auto=compress&cs=tinysrgb&w=80"}',
   false)
on conflict (id) do nothing;

-- ───────────────────── community rooms + kitchens ──────────────────

insert into public.conversations
  (id, kind, name, emoji, description, tier, unlock_level, color, is_live, base_members, sort_order, created_by)
values
  ('a0000000-0000-4000-8000-000000000001', 'kitchen', '@chefpriya''s Kitchen', '👩‍🍳', '', null, null, '#FF6B6B', true, 2400, 1, null),
  ('a0000000-0000-4000-8000-000000000002', 'kitchen', '@marcusfoods Ramen Lab', '🍜', '', null, null, '#FFB347', false, 890, 2, null),
  ('a0000000-0000-4000-8000-000000000003', 'kitchen', '@sarah_bakes Bakery', '🧁', '', null, null, '#E91E63', true, 1100, 3, null),

  ('a0000000-0000-4000-8000-000000000101', 'community', 'What''s Good Near Me', '📍', 'Restaurant recs, hidden spots, where to eat tonight', 'foodies', null, '#FF6B6B', false, 34500, 1, null),
  ('a0000000-0000-4000-8000-000000000102', 'community', 'Date Night Eats', '💕', 'Restaurant picks for couples — impress every time', 'foodies', null, '#FF6B6B', false, 18200, 2, null),
  ('a0000000-0000-4000-8000-000000000103', 'community', 'Street Food Hunters', '🌍', 'Tacos, dumplings, kebabs — if it''s on a cart, it''s here', 'foodies', null, '#FF6B6B', false, 45200, 3, null),
  ('a0000000-0000-4000-8000-000000000104', 'community', 'Meal Prep Crew', '📦', 'Batch cook Sunday, eat all week', 'foodies', 'Beginner', '#FF6B6B', false, 15700, 4, null),
  ('a0000000-0000-4000-8000-000000000105', 'community', 'Late Night Bites', '🌙', '3am cravings hit different', 'foodies', null, '#FF6B6B', false, 31800, 5, null),

  ('a0000000-0000-4000-8000-000000000201', 'community', 'Recipe Workshop', '🧪', 'Test recipes, get feedback before publishing', 'creators', 'Beginner', '#4ECDC4', false, 5400, 1, null),
  ('a0000000-0000-4000-8000-000000000202', 'community', 'Food Photography', '📸', 'Lighting, angles, styling — make it look insane', 'creators', null, '#4ECDC4', false, 11200, 2, null),
  ('a0000000-0000-4000-8000-000000000203', 'community', 'Creator Economy', '💰', 'Tips, earnings, brand deals & growth strategies', 'creators', 'Sous Chef', '#4ECDC4', false, 2100, 3, null),
  ('a0000000-0000-4000-8000-000000000204', 'community', 'Fermentation Lab', '🫙', 'Kimchi, sourdough, kombucha & beyond', 'creators', 'Home Cook', '#4ECDC4', false, 9300, 4, null),
  ('a0000000-0000-4000-8000-000000000205', 'community', 'World Fusion', '🌍', 'Mash up cuisines — Korean-Mexican? Thai-Italian? Yes.', 'creators', null, '#4ECDC4', false, 7800, 5, null),

  ('a0000000-0000-4000-8000-000000000301', 'community', 'Rate Everything', '📊', 'Honest takes only', 'critics', 'Beginner', '#FFB347', false, 6200, 1, null),
  ('a0000000-0000-4000-8000-000000000302', 'community', 'Restaurant Roasts', '🍽', 'Honest reviews, no sugar coating, no influencer bias', 'critics', 'Home Cook', '#FFB347', false, 3800, 2, null),
  ('a0000000-0000-4000-8000-000000000303', 'community', 'Spice Scale Debate', '🔥', 'Is that really a 3-pepper? Prove it.', 'critics', 'Beginner', '#FFB347', false, 4100, 3, null),
  ('a0000000-0000-4000-8000-000000000304', 'community', 'Hidden Gems', '💎', 'Underrated spots and slept-on recipes', 'critics', null, '#FFB347', false, 9700, 4, null),
  ('a0000000-0000-4000-8000-000000000305', 'community', 'The Pepper Panel', '🫑', 'Elite raters — 50+ ratings required', 'critics', 'Sous Chef', '#FFB347', false, 1200, 5, null)
on conflict (id) do nothing;

-- A few starter messages so rooms aren't empty. The after_message
-- trigger fills each room's last_message_* preview.
insert into public.messages (id, conversation_id, sender_id, sender_name, body, created_at)
values
  ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', null, 'Priya Kim', 'Welcome in! Tonight we''re making gochujang wings 🌶', now() - interval '20 minutes'),
  ('b0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', null, 'Noodle Queen', 'Ready with my wings 🍗', now() - interval '5 minutes'),
  ('b0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000002', null, 'Marcus', 'Broth has been going for 12 hours 🍜', now() - interval '12 minutes'),
  ('b0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000003', null, 'Sarah Bakes', 'Cupcakes are in the oven! 🧁', now() - interval '3 minutes'),
  ('b0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000101', null, 'Foodie Lisa', 'Any good ramen spots open late downtown?', now() - interval '1 hour'),
  ('b0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000103', null, 'Abuelita''s Kitchen', 'Found a birria truck on 5th — insane consommé 🌮', now() - interval '2 hours'),
  ('b0000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000105', null, 'Late Night Eats', 'Midnight grilled cheese, who''s in? 🧀', now() - interval '30 minutes'),
  ('b0000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000202', null, 'Sushi Lab', 'Natural light > ring light. Fight me 📸', now() - interval '3 hours'),
  ('b0000000-0000-4000-8000-000000000009', 'a0000000-0000-4000-8000-000000000303', null, 'Spice Route', 'Buffalo wings are a 2-pepper at most 🔥', now() - interval '45 minutes'),
  ('b0000000-0000-4000-8000-000000000010', 'a0000000-0000-4000-8000-000000000304', null, 'Seoul Foods', 'The dumpling place behind the laundromat. Trust me 💎', now() - interval '4 hours')
on conflict (id) do nothing;
