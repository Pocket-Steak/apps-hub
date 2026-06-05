-- Room of the Month: one room is deep-cleaned each calendar month.
-- A room is assigned a month (1-12); the dashboard "Room of the Month" tile
-- shows whichever room maps to the current month and opens a checklist overlay.
-- Room-task completions are keyed by period_key = 'YYYY-MM' (the month), so the
-- checklist resets fresh every time that room's month comes back around — the same
-- period-key reset pattern used by family_project_task_completions.

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
    select 1
    from pg_constraint
    where conname = 'family_rooms_month_check'
      and conrelid = 'public.family_rooms'::regclass
  ) then
    alter table public.family_rooms
      add constraint family_rooms_month_check
      check (month between 1 and 12);
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
create policy "family_rooms_public_all"
  on public.family_rooms
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_room_tasks_public_all" on public.family_room_tasks;
create policy "family_room_tasks_public_all"
  on public.family_room_tasks
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_room_task_completions_public_all"
  on public.family_room_task_completions;
create policy "family_room_task_completions_public_all"
  on public.family_room_task_completions
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
