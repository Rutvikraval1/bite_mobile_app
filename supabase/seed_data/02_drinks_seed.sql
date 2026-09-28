-- ═══════════════════════════════════════════════════════════════
-- Seed: public.drinks
-- Idempotent: safe to run repeatedly (upserts by id).
-- ═══════════════════════════════════════════════════════════════

insert into public.drinks
  (id, title, creator, time_min, difficulty, serves, heat_level, saved_count, hearts_count, comments_count, emoji, image_url, cuisine, gradient, tags)
values
  (10, 'Espresso Martini',      '@mixologist_joe', '5 min',  'Easy',   1, 0, '1.1K', '890',  42,  '🍸', 'https://images.pexels.com/photos/20053276/pexels-photo-20053276.jpeg?auto=compress&cs=tinysrgb&w=600', null,     'linear-gradient(160deg, #0a0a1a 0%, #1a1040 30%, #2d1a5e 60%, #4a2080 100%)', '{#cocktail,#espresso,#datenight,#classic,#afterdinner}'),
  (11, 'Smoked Old Fashioned',   '@barcraft_mike',  '5 min',  'Medium', 1, 0, '2.4K', '1.6K', 78,  '🥃', 'https://images.pexels.com/photos/10728156/pexels-photo-10728156.jpeg?auto=compress&cs=tinysrgb&w=600', null,     'linear-gradient(135deg, #1a0500 0%, #4a2000 40%, #8B4513 100%)',             '{#cocktail,#whiskey,#smoked,#classic,#fancy,#datenight}'),
  (12, 'Spicy Margarita',        '@cantina_queen',  '5 min',  'Easy',   1, 1, '3.5K', '2.8K', 112, '🍹', 'https://images.pexels.com/photos/4958905/pexels-photo-4958905.jpeg?auto=compress&cs=tinysrgb&w=600',  null,     'linear-gradient(135deg, #003300 0%, #006600 40%, #228B22 100%)',             '{#cocktail,#tequila,#spicy,#summer,#party,#viral}'),
  (13, 'Lavender Gin Fizz',      '@botanist_bar',   '5 min',  'Easy',   1, 0, '1.8K', '1.4K', 56,  '💜', 'https://images.pexels.com/photos/19412515/pexels-photo-19412515.jpeg?auto=compress&cs=tinysrgb&w=600', null,     'linear-gradient(135deg, #1a0033 0%, #4a0080 40%, #7B2FBE 100%)',             '{#cocktail,#gin,#floral,#spring,#brunch,#aesthetic}'),
  (14, 'Thai Iced Tea',          '@bangkokbites',   '10 min', 'Easy',   2, 0, '2.1K', '1.7K', 63,  '🧋', 'https://images.pexels.com/photos/33241823/pexels-photo-33241823.jpeg?auto=compress&cs=tinysrgb&w=600', 'Thai',     'linear-gradient(135deg, #4a1500 0%, #B8510D 40%, #E88D30 100%)',             '{#nonalcoholic,#thai,#iced,#sweet,#refreshing,#summer}'),
  (30, 'Mango Lassi',            '@bombay_kitchen', '5 min',  'Easy',   2, 0, '3.2K', '2.6K', 89,  '🥛', 'https://images.pexels.com/photos/17200460/pexels-photo-17200460.jpeg?auto=compress&cs=tinysrgb&w=600', 'Indian',   'linear-gradient(135deg, #B8860B 0%, #DAA520 40%, #FFD700 100%)',             '{#nonalcoholic,#indian,#smoothie,#sweet,#healthy,#quick}'),
  (31, 'Yuzu Sake Spritz',       '@tokyosips',       '5 min',  'Easy',   1, 0, '1.6K', '1.2K', 45,  '🍶', 'https://images.pexels.com/photos/18341856/pexels-photo-18341856.jpeg?auto=compress&cs=tinysrgb&w=600', 'Japanese', 'linear-gradient(135deg, #1a2a00 0%, #4a5a20 40%, #8B9A46 100%)',             '{#cocktail,#sake,#japanese,#citrus,#spring,#light}'),
  (32, 'Vietnamese Iced Coffee', '@saigon_soul',     '5 min',  'Easy',   1, 0, '4.7K', '3.9K', 178, '☕', 'https://images.pexels.com/photos/31990173/pexels-photo-31990173.jpeg?auto=compress&cs=tinysrgb&w=600', 'Vietnamese', 'linear-gradient(135deg, #1a0a00 0%, #3d1f00 40%, #6B4226 100%)',           '{#nonalcoholic,#vietnamese,#coffee,#iced,#sweet,#classic}'),
  (33, 'Aperol Spritz',          '@dolcevita_bar',   '3 min',  'Easy',   1, 0, '5.1K', '4.2K', 189, '🍊', 'https://images.pexels.com/photos/128242/pexels-photo-128242.jpeg?auto=compress&cs=tinysrgb&w=600',    null,     'linear-gradient(135deg, #4a1500 0%, #CC4400 40%, #FF6622 100%)',             '{#cocktail,#italian,#spritz,#summer,#brunch,#easy}'),
  (34, 'Mojito',                 '@havanasips',      '5 min',  'Easy',   1, 0, '4.3K', '3.5K', 156, '🌿', 'https://images.pexels.com/photos/7259054/pexels-photo-7259054.jpeg?auto=compress&cs=tinysrgb&w=600',  null,     'linear-gradient(135deg, #003322 0%, #006644 40%, #00AA66 100%)',             '{#cocktail,#rum,#mint,#summer,#refreshing,#classic}'),
  (35, 'Paloma',                 '@cantina_queen',   '5 min',  'Easy',   1, 0, '2.8K', '2.1K', 92,  '🌸', 'https://images.pexels.com/photos/15813473/pexels-photo-15813473.jpeg?auto=compress&cs=tinysrgb&w=600', null,     'linear-gradient(135deg, #4a1030 0%, #8B2060 40%, #CC3090 100%)',             '{#cocktail,#tequila,#grapefruit,#summer,#refreshing,#mexican}'),
  (36, 'Matcha Latte',           '@zencha',          '5 min',  'Easy',   1, 0, '6.2K', '5.1K', 234, '🍵', 'https://images.pexels.com/photos/911810/pexels-photo-911810.jpeg?auto=compress&cs=tinysrgb&w=600', 'Japanese', 'linear-gradient(135deg, #0a2a10 0%, #1a5a20 40%, #2d8a30 100%)',             '{#nonalcoholic,#matcha,#japanese,#healthy,#aesthetic,#trending}')
on conflict (id) do update set
  title = excluded.title, creator = excluded.creator, time_min = excluded.time_min,
  difficulty = excluded.difficulty, serves = excluded.serves, heat_level = excluded.heat_level,
  saved_count = excluded.saved_count, hearts_count = excluded.hearts_count, comments_count = excluded.comments_count,
  emoji = excluded.emoji, image_url = excluded.image_url, cuisine = excluded.cuisine,
  gradient = excluded.gradient, tags = excluded.tags;
