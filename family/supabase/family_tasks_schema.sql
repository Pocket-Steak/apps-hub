create extension if not exists pgcrypto;

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  color text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.family_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  owner_name text,
  points integer not null default 1 check (points >= 0),
  active boolean not null default true,
  sort_order integer,
  created_at timestamptz not null default now()
);

create table if not exists public.family_task_completions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.family_tasks(id) on delete cascade,
  completed_by text not null,
  points integer not null default 0 check (points >= 0),
  completed_at timestamptz not null default now(),
  day_key text not null,
  week_start text not null
);

create index if not exists family_tasks_active_sort_idx
  on public.family_tasks (active, sort_order, created_at);

create index if not exists family_task_completions_week_idx
  on public.family_task_completions (week_start, completed_at desc);

create unique index if not exists family_task_completions_task_day_idx
  on public.family_task_completions (task_id, day_key);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_members to anon, authenticated;
grant select, insert, update, delete on public.family_tasks to anon, authenticated;
grant select, insert, update, delete on public.family_task_completions to anon, authenticated;

alter table public.family_members enable row level security;
alter table public.family_tasks enable row level security;
alter table public.family_task_completions enable row level security;

drop policy if exists "family_members_public_all" on public.family_members;
create policy "family_members_public_all"
  on public.family_members
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_tasks_public_all" on public.family_tasks;
create policy "family_tasks_public_all"
  on public.family_tasks
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_task_completions_public_all" on public.family_task_completions;
create policy "family_task_completions_public_all"
  on public.family_task_completions
  for all
  to anon, authenticated
  using (true)
  with check (true);

insert into public.family_members (name, color)
values
  ('Andrew', '#ff9d2f'),
  ('Nichol', '#8b5cf6'),
  ('Jolie', '#22c55e')
on conflict (name) do update
set color = excluded.color;
