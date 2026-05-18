-- Seed recurring tasks into family_tasks
-- Weekdays: Sun=0, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
-- Months: Jan=1 .. Dec=12
-- Week-of-month is rotated across rows so the workload spreads across
-- the 1st, 2nd, 3rd, and 4th weeks instead of piling on week 1.
-- start_date = 2026-05-18 for non-daily.

INSERT INTO family_tasks
  (title, active, recurrence_interval, recurrence_day_of_week, recurrence_day_of_week_2,
   recurrence_week_of_month, recurrence_month, recurrence_month_2, recurrence_day_of_month,
   recurrence_start_date, sort_order)
VALUES
  -- ─── DAILY ─────────────────────────────────────────────
  ('Dishes',                  true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 10),
  ('Counters & Table',        true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 20),
  ('Sweep Kitchen Floor',     true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 30),
  ('Cat Boxes & Sweep',       true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 40),
  ('Take out Kitchen Trash',  true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 50),
  ('Straighten',              true, 'daily', 1, 4, 1, 1, 7, 1, NULL, 60),

  -- ─── TWICE WEEKLY ──────────────────────────────────────
  ('Menu & Grocery List',     true, 'twice_weekly', 3, 0, 1, 1, 7, 1, '2026-05-18', 110),
  ('Laundry',                 true, 'twice_weekly', 3, 0, 1, 1, 7, 1, '2026-05-18', 120),
  ('Grocery Pickup',          true, 'twice_weekly', 4, 0, 1, 1, 7, 1, '2026-05-18', 130),
  ('Meal Prep',               true, 'twice_weekly', 4, 0, 1, 1, 7, 1, '2026-05-18', 140),

  -- ─── WEEKLY ────────────────────────────────────────────
  ('Take Trash to Road',      true, 'weekly', 0, 4, 1, 1, 7, 1, '2026-05-18', 210),
  ('Clean C-pap Hose',        true, 'weekly', 0, 4, 1, 1, 7, 1, '2026-05-18', 220),
  ('Cats',                    true, 'weekly', 3, 4, 1, 1, 7, 1, '2026-05-18', 230),
  ('Bathrooms',               true, 'weekly', 4, 4, 1, 1, 7, 1, '2026-05-18', 240),
  ('Vacuum',                  true, 'weekly', 4, 4, 1, 1, 7, 1, '2026-05-18', 250),
  ('Dust',                    true, 'weekly', 4, 4, 1, 1, 7, 1, '2026-05-18', 260),
  ('Cat Bowls',               true, 'weekly', 0, 4, 1, 1, 7, 1, '2026-05-18', 270),
  ('Clean Out Fridge',        true, 'weekly', 0, 4, 1, 1, 7, 1, '2026-05-18', 280),
  ('Mow the Lawn',            true, 'weekly', 0, 4, 1, 1, 7, 1, '2026-05-18', 290),

  -- ─── MONTHLY (rotated across weeks 1–4) ────────────────
  -- Sundays: Sheets(1), Stove(2), Cat Blankets(3), Blankets(4)
  -- Thursdays: Disinfect(1), Showers(2), Mop(3), Microwave(4)
  ('Sheets',                  true, 'monthly', 0, 4, 1, 1, 7, 1, '2026-05-18', 310),
  ('Stove',                   true, 'monthly', 0, 4, 2, 1, 7, 1, '2026-05-18', 320),
  ('Cat Blankets',            true, 'monthly', 0, 4, 3, 1, 7, 1, '2026-05-18', 330),
  ('Blankets',                true, 'monthly', 0, 4, 4, 1, 7, 1, '2026-05-18', 340),
  ('Disinfect',               true, 'monthly', 4, 4, 1, 1, 7, 1, '2026-05-18', 350),
  ('Showers',                 true, 'monthly', 4, 4, 2, 1, 7, 1, '2026-05-18', 360),
  ('Mop',                     true, 'monthly', 4, 4, 3, 1, 7, 1, '2026-05-18', 370),
  ('Microwave',               true, 'monthly', 4, 4, 4, 1, 7, 1, '2026-05-18', 380),

  -- ─── TWICE A YEAR (rotated across weeks 1–4) ───────────
  -- Sundays rotate 1,2,3,4,1,2,3; Thursdays rotate 1,2,3,4,1,2,3; Mondays 1,3
  ('Mattresses',              true, 'twice_a_year', 0, 4, 1, 1, 7, 1, '2026-05-18', 410),
  ('Dishwasher',              true, 'twice_a_year', 0, 4, 2, 2, 8, 1, '2026-05-18', 420),
  ('Cabinets',                true, 'twice_a_year', 0, 4, 3, 2, 8, 1, '2026-05-18', 430),
  ('Cars',                    true, 'twice_a_year', 0, 4, 4, 5, 10, 1, '2026-05-18', 440),
  ('Fans / ACs',              true, 'twice_a_year', 0, 4, 1, 5, 11, 1, '2026-05-18', 450),
  ('Vanities',                true, 'twice_a_year', 4, 4, 1, 2, 8, 1, '2026-05-18', 460),

  -- ─── 4 × YEAR (split into 2 twice_a_year rows each) ────
  ('Garbage Disposal',        true, 'twice_a_year', 0, 4, 2, 1, 7, 1, '2026-05-18', 510),
  ('Garbage Disposal',        true, 'twice_a_year', 0, 4, 3, 4, 10, 1, '2026-05-18', 511),
  ('Screens',                 true, 'twice_a_year', 4, 4, 2, 2, 8, 1, '2026-05-18', 520),
  ('Screens',                 true, 'twice_a_year', 4, 4, 3, 5, 11, 1, '2026-05-18', 521),
  ('Windows',                 true, 'twice_a_year', 4, 4, 4, 3, 9, 1, '2026-05-18', 530),
  ('Windows',                 true, 'twice_a_year', 4, 4, 1, 6, 12, 1, '2026-05-18', 531),
  ('Mirrors',                 true, 'twice_a_year', 4, 4, 2, 3, 9, 1, '2026-05-18', 540),
  ('Mirrors',                 true, 'twice_a_year', 4, 4, 3, 6, 12, 1, '2026-05-18', 541),
  ('Dump Cat Boxes',          true, 'twice_a_year', 1, 4, 1, 2, 8, 1, '2026-05-18', 550),
  ('Dump Cat Boxes',          true, 'twice_a_year', 1, 4, 3, 5, 11, 1, '2026-05-18', 551),

  -- ─── YEARLY (rotated across weeks 1–4 by month) ────────
  ('Bedrooms & Closets',          true, 'yearly', 0, 4, 1, 1,  7, 1, '2026-05-18', 610),
  ('Kitchen & Oven',              true, 'yearly', 0, 4, 2, 2,  8, 1, '2026-05-18', 620),
  ('Washer & Dryer',              true, 'yearly', 0, 4, 3, 3,  9, 1, '2026-05-18', 630),
  ('Livingroom & Rugs & Walls',   true, 'yearly', 0, 4, 4, 4, 10, 1, '2026-05-18', 640),
  ('Lobbies (Summer)',            true, 'yearly', 0, 4, 1, 5, 11, 1, '2026-05-18', 650),
  ('Outside & Outdoor Trash Cans',true, 'yearly', 0, 4, 2, 6, 12, 1, '2026-05-18', 660),
  ('Basement & Sump Pump',        true, 'yearly', 0, 4, 3, 7,  1, 1, '2026-05-18', 670),
  ('Bathrooms',                   true, 'yearly', 0, 4, 4, 8,  2, 1, '2026-05-18', 680),
  ('Garage & Loft',               true, 'yearly', 0, 4, 1, 9,  3, 1, '2026-05-18', 690),
  ('Office',                      true, 'yearly', 0, 4, 2, 10, 4, 1, '2026-05-18', 700),
  ('Lobbies (Winter)',            true, 'yearly', 0, 4, 3, 11, 5, 1, '2026-05-18', 710),
  ('Hallway & Stairs',            true, 'yearly', 0, 4, 4, 12, 6, 1, '2026-05-18', 720);
