-- Projects: separate task system (independent from family_tasks).
-- Daily tile = recurrence_interval = 'daily'
-- Date-specific tile = every other recurrence (weekly, twice_weekly, bi_weekly,
-- monthly, every_other_month, twice_a_year, yearly).
-- Date-specific tiles only appear once the current period start has arrived,
-- and show a green/yellow/red age color (1-3 days green, 4-6 yellow, 7+ red)
-- until a completion is written for that period.

create extension if not exists pgcrypto;

create table if not exists public.family_project_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  active boolean not null default true,
  recurrence_interval text not null default 'daily',
  recurrence_day_of_week integer not null default 1,
  recurrence_day_of_week_2 integer not null default 4,
  recurrence_week_of_month integer not null default 1,
  recurrence_month integer not null default 1,
  recurrence_month_2 integer not null default 7,
  recurrence_day_of_month integer not null default 1,
  recurrence_start_date date,
  sort_order integer,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_recurrence_interval_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_recurrence_interval_check
      check (recurrence_interval in (
        'daily',
        'weekly',
        'twice_weekly',
        'bi_weekly',
        'monthly',
        'every_other_month',
        'quarterly',
        'twice_a_year',
        'yearly',
        'project'
      ));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_day_of_week_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_day_of_week_check
      check (recurrence_day_of_week between 0 and 6);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_day_of_week_2_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_day_of_week_2_check
      check (recurrence_day_of_week_2 between 0 and 6);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_week_of_month_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_week_of_month_check
      check (recurrence_week_of_month = -1 or recurrence_week_of_month between 1 and 5);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_month_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_month_check
      check (recurrence_month between 1 and 12);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_month_2_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_month_2_check
      check (recurrence_month_2 between 1 and 12);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_project_tasks_day_of_month_check'
      and conrelid = 'public.family_project_tasks'::regclass
  ) then
    alter table public.family_project_tasks
      add constraint family_project_tasks_day_of_month_check
      check (recurrence_day_of_month between 1 and 31);
  end if;
end $$;

create table if not exists public.family_project_task_completions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.family_project_tasks(id) on delete cascade,
  period_key text not null,
  completed_at timestamptz not null default now()
);

create unique index if not exists family_project_task_completions_task_period_idx
  on public.family_project_task_completions (task_id, period_key);

create index if not exists family_project_tasks_active_sort_idx
  on public.family_project_tasks (active, sort_order, created_at);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_project_tasks to anon, authenticated;
grant select, insert, update, delete on public.family_project_task_completions to anon, authenticated;

alter table public.family_project_tasks enable row level security;
alter table public.family_project_task_completions enable row level security;

drop policy if exists "family_project_tasks_public_all" on public.family_project_tasks;
create policy "family_project_tasks_public_all"
  on public.family_project_tasks
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_project_task_completions_public_all"
  on public.family_project_task_completions;
create policy "family_project_task_completions_public_all"
  on public.family_project_task_completions
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
