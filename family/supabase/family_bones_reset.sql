-- =====================================================================
-- BONES RESET — wipe and reseed from the chore-schedule sheet.
-- Paste the whole file into Supabase SQL Editor and run once.
-- Safe to re-run: section 1 is idempotent; sections 2-6 wipe-and-seed.
-- =====================================================================
-- Day-of-week values: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Ensure family_rooms / family_room_tasks / completions exist.
--    No-op if you've already applied family_rooms_schema.sql.
-- ---------------------------------------------------------------------
create extension if not exists pgcrypto;

create table if not exists public.family_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  month integer not null default 1,
  sort_order integer,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'family_rooms_month_check'
      and conrelid = 'public.family_rooms'::regclass
  ) then
    alter table public.family_rooms
      add constraint family_rooms_month_check check (month between 1 and 12);
  end if;
end $$;

create table if not exists public.family_room_tasks (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.family_rooms(id) on delete cascade,
  title text not null,
  sort_order integer,
  created_at timestamptz not null default now()
);

create table if not exists public.family_room_task_completions (
  id uuid primary key default gen_random_uuid(),
  room_task_id uuid not null references public.family_room_tasks(id) on delete cascade,
  period_key text not null,
  completed_at timestamptz not null default now()
);

create unique index if not exists family_room_task_completions_task_period_idx
  on public.family_room_task_completions (room_task_id, period_key);
create index if not exists family_rooms_month_sort_idx
  on public.family_rooms (month, sort_order, created_at);
create index if not exists family_room_tasks_room_sort_idx
  on public.family_room_tasks (room_id, sort_order, created_at);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_rooms to anon, authenticated;
grant select, insert, update, delete on public.family_room_tasks to anon, authenticated;
grant select, insert, update, delete on public.family_room_task_completions to anon, authenticated;

alter table public.family_rooms enable row level security;
alter table public.family_room_tasks enable row level security;
alter table public.family_room_task_completions enable row level security;

drop policy if exists "family_rooms_public_all" on public.family_rooms;
create policy "family_rooms_public_all" on public.family_rooms
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "family_room_tasks_public_all" on public.family_room_tasks;
create policy "family_room_tasks_public_all" on public.family_room_tasks
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "family_room_task_completions_public_all" on public.family_room_task_completions;
create policy "family_room_task_completions_public_all" on public.family_room_task_completions
  for all to anon, authenticated using (true) with check (true);

-- ---------------------------------------------------------------------
-- 2. Wipe existing Bones data.
--    Completions cascade with their parent rows, but we delete them
--    explicitly so the order is obvious if any FKs change later.
-- ---------------------------------------------------------------------
delete from public.family_project_task_completions;
delete from public.family_project_tasks;
delete from public.family_room_task_completions;
delete from public.family_room_tasks;
delete from public.family_rooms;

-- ---------------------------------------------------------------------
-- 3. Daily chores (every day, in the order from the sheet)
-- ---------------------------------------------------------------------
insert into public.family_project_tasks
  (title, recurrence_interval, sort_order, recurrence_start_date)
values
  ('Dishes',              'daily', 10, '2026-01-01'),
  ('Counters / Table',    'daily', 20, '2026-01-01'),
  ('Sweep Kitchen Floor', 'daily', 30, '2026-01-01'),
  ('Cat Box 1 / Sweep',   'daily', 40, '2026-01-01'),
  ('Cat Box 2 / Sweep',   'daily', 50, '2026-01-01'),
  ('Take Trash Out',      'daily', 60, '2026-01-01');

-- ---------------------------------------------------------------------
-- 4. Weekly + twice-weekly tasks
-- ---------------------------------------------------------------------
-- Weekly (one day a week)
insert into public.family_project_tasks
  (title, recurrence_interval, recurrence_day_of_week, sort_order, recurrence_start_date)
values
  ('Take Trash to Road', 'weekly', 1, 100, '2026-01-01'),  -- Mon
  ('Bathrooms',          'weekly', 3, 110, '2026-01-01'),  -- Wed
  ('Cats',               'weekly', 3, 120, '2026-01-01'),  -- Wed (intentionally vague)
  ('Dust',               'weekly', 4, 130, '2026-01-01'),  -- Thu
  ('Vacuum',             'weekly', 4, 140, '2026-01-01'),  -- Thu
  ('Cat Bowls',          'weekly', 4, 150, '2026-01-01'),  -- Thu
  ('Clean out Fridge',   'weekly', 0, 160, '2026-01-01');  -- Sun

-- Twice-weekly (day_of_week + day_of_week_2)
-- Monthly Project List = dedicated time to work on this month's room checklist.
insert into public.family_project_tasks
  (title, recurrence_interval, recurrence_day_of_week, recurrence_day_of_week_2, sort_order, recurrence_start_date)
values
  ('Menu / Grocery List',  'twice_weekly', 3, 6, 170, '2026-01-01'),  -- Wed + Sat
  ('Grocery Pickup',       'twice_weekly', 4, 0, 180, '2026-01-01'),  -- Thu + Sun
  ('Monthly Project List', 'twice_weekly', 1, 6, 190, '2026-01-01'),  -- Mon + Sat
  ('Meal Prep',            'twice_weekly', 4, 0, 200, '2026-01-01'),  -- Thu + Sun
  ('Laundry',              'twice_weekly', 3, 0, 210, '2026-01-01');  -- Wed + Sun

-- ---------------------------------------------------------------------
-- 5. Monthly rotation (one nth-weekday-of-the-month each)
-- ---------------------------------------------------------------------
insert into public.family_project_tasks
  (title, recurrence_interval, recurrence_day_of_week, recurrence_week_of_month, sort_order, recurrence_start_date)
values
  ('Showers',               'monthly', 3, 1, 300, '2026-01-01'),  -- 1st Wed
  ('Disinfect',             'monthly', 4, 1, 310, '2026-01-01'),  -- 1st Thu
  ('Stove',                 'monthly', 4, 2, 320, '2026-01-01'),  -- 2nd Thu
  ('Cat Blankets',          'monthly', 0, 2, 330, '2026-01-01'),  -- 2nd Sun
  ('Mop',                   'monthly', 4, 3, 340, '2026-01-01'),  -- 3rd Thu
  ('Sheets',                'monthly', 0, 3, 350, '2026-01-01'),  -- 3rd Sun
  ('Microwave / Air fryer', 'monthly', 4, 4, 360, '2026-01-01'),  -- 4th Thu
  ('Blankets',              'monthly', 0, 4, 370, '2026-01-01');  -- 4th Sun

-- ---------------------------------------------------------------------
-- 6. Room of the Month + per-room checklists
--    Every room gets the 9 common deep-clean tasks; some months add
--    room-specific extras pulled straight from the sheet.
-- ---------------------------------------------------------------------
do $$
declare
  v_room_id uuid;
begin
  -- JAN: Bedrooms
  insert into public.family_rooms (name, month, sort_order)
    values ('Bedrooms', 1, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Vacuum & clean mattresses', 100);

  -- FEB: Kitchen
  insert into public.family_rooms (name, month, sort_order)
    values ('Kitchen', 2, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Deep clean fridge & freezer', 100),
    (v_room_id, 'Deep clean stove & oven', 110),
    (v_room_id, 'Deep clean dishwasher & filter', 120),
    (v_room_id, 'Clean garbage disposal & drains', 130),
    (v_room_id, 'Scrub trash can & recycling bin', 140),
    (v_room_id, 'Deep clean cabinets, drawers, & pantry', 150),
    (v_room_id, 'Clean vent above stove & filter', 160),
    (v_room_id, 'Clean shelves & top of fridge', 170);

  -- MAR: Laundry Room
  insert into public.family_rooms (name, month, sort_order)
    values ('Laundry Room', 3, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Deep clean washer', 100),
    (v_room_id, 'Deep clean dryer & lint trap', 110),
    (v_room_id, 'Deep clean cat closet 1', 120),
    (v_room_id, 'Dump both cat boxes', 130);

  -- APR: Living Room / Dining Room
  insert into public.family_rooms (name, month, sort_order)
    values ('Living Room / Dining Room', 4, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Clean media carts', 100),
    (v_room_id, 'Vacuum & clean couch, chair, & ottomans', 110),
    (v_room_id, 'Purge & clean cat toys', 120),
    (v_room_id, 'Clean cat tree', 130);

  -- MAY: Lobbies (Summer)
  insert into public.family_rooms (name, month, sort_order)
    values ('Lobbies (Summer)', 5, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Pack up Winter items', 100),
    (v_room_id, 'Unpack Summer items', 110),
    (v_room_id, 'Clean or replace rugs', 120),
    (v_room_id, 'Clean fans / ACs', 130);

  -- JUN: Outside
  insert into public.family_rooms (name, month, sort_order)
    values ('Outside', 6, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Deep clean outdoor trash can & recycling bin', 100),
    (v_room_id, 'Clean up rocks in driveway', 110),
    (v_room_id, 'Clean exterior of house & garage', 120),
    (v_room_id, 'Clean up yard', 130);

  -- JUL: Basement
  insert into public.family_rooms (name, month, sort_order)
    values ('Basement', 7, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Deep clean sump pumps', 100),
    (v_room_id, 'Clean furnace & filter', 110),
    (v_room_id, 'Clean hot water tank', 120),
    (v_room_id, 'Clean dehumidifier', 130),
    (v_room_id, 'Dump both cat boxes', 140);

  -- AUG: Bathrooms
  insert into public.family_rooms (name, month, sort_order)
    values ('Bathrooms', 8, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90);

  -- SEP: Garage & Loft
  insert into public.family_rooms (name, month, sort_order)
    values ('Garage & Loft', 9, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90);

  -- OCT: Offices
  insert into public.family_rooms (name, month, sort_order)
    values ('Offices', 10, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Deep clean cat closet 2', 100);

  -- NOV: Lobbies (Winter)
  insert into public.family_rooms (name, month, sort_order)
    values ('Lobbies (Winter)', 11, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90),
    (v_room_id, 'Pack up Summer items', 100),
    (v_room_id, 'Unpack Winter items', 110),
    (v_room_id, 'Clean or replace rugs', 120),
    (v_room_id, 'Clean fans / ACs', 130),
    (v_room_id, 'Dump both cat boxes', 140);

  -- DEC: Hallway / Stairs
  insert into public.family_rooms (name, month, sort_order)
    values ('Hallway / Stairs', 12, 1) returning id into v_room_id;
  insert into public.family_room_tasks (room_id, title, sort_order) values
    (v_room_id, 'Purge (if needed)', 10),
    (v_room_id, 'Clean windows, mirrors, & screens', 20),
    (v_room_id, 'Dust furniture, appliances, shelves, lights, & decorations', 30),
    (v_room_id, 'Vacuum floors, windowsills, ceiling, corners, fans / ACs, & vents', 40),
    (v_room_id, 'Mop floors', 50),
    (v_room_id, 'Wipe walls, doors, trim, & baseboards', 60),
    (v_room_id, 'Wash curtains / shades / blinds', 70),
    (v_room_id, 'Carpet scrub rugs', 80),
    (v_room_id, 'Clean out closets, cabinets, drawers, etc', 90);
end $$;

-- Tell PostgREST to reload so the new rows show up immediately.
select pg_notify('pgrst', 'reload schema');
