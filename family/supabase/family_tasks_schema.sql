create extension if not exists pgcrypto;

create table if not exists public.family_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  active boolean not null default true,
  recurrence_interval text not null default 'daily',
  recurrence_day_of_week integer not null default 1,
  recurrence_month integer not null default 1,
  recurrence_day_of_month integer not null default 1,
  recurrence_start_date date,
  sort_order integer,
  created_at timestamptz not null default now()
);

alter table public.family_tasks
  add column if not exists recurrence_interval text not null default 'daily';

alter table public.family_tasks
  add column if not exists recurrence_day_of_week integer not null default 1;

alter table public.family_tasks
  add column if not exists recurrence_month integer not null default 1;

alter table public.family_tasks
  add column if not exists recurrence_day_of_month integer not null default 1;

alter table public.family_tasks
  add column if not exists recurrence_start_date date;

update public.family_tasks
  set recurrence_interval = 'daily'
  where recurrence_interval is null;

update public.family_tasks
  set recurrence_day_of_week = 1
  where recurrence_day_of_week is null
    or recurrence_day_of_week < 0
    or recurrence_day_of_week > 6;

update public.family_tasks
  set recurrence_month = 1
  where recurrence_month is null
    or recurrence_month < 1
    or recurrence_month > 12;

update public.family_tasks
  set recurrence_day_of_month = 1
  where recurrence_day_of_month is null
    or recurrence_day_of_month < 1
    or recurrence_day_of_month > 31;

update public.family_tasks
  set recurrence_start_date = coalesce(created_at::date, current_date)
  where recurrence_start_date is null
    and coalesce(sort_order, 0) > 0;

alter table public.family_tasks
  alter column recurrence_interval set default 'daily';

alter table public.family_tasks
  alter column recurrence_interval set not null;

alter table public.family_tasks
  alter column recurrence_day_of_week set default 1;

alter table public.family_tasks
  alter column recurrence_day_of_week set not null;

alter table public.family_tasks
  alter column recurrence_month set default 1;

alter table public.family_tasks
  alter column recurrence_month set not null;

alter table public.family_tasks
  alter column recurrence_day_of_month set default 1;

alter table public.family_tasks
  alter column recurrence_day_of_month set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_tasks_recurrence_interval_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_interval_check
      check (recurrence_interval in (
        'daily',
        'weekly',
        'bi_weekly',
        'monthly',
        'every_other_month',
        'twice_a_year',
        'yearly'
      ));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_tasks_recurrence_day_of_week_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_day_of_week_check
      check (recurrence_day_of_week between 0 and 6);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_tasks_recurrence_month_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_month_check
      check (recurrence_month between 1 and 12);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_tasks_recurrence_day_of_month_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_day_of_month_check
      check (recurrence_day_of_month between 1 and 31);
  end if;
end $$;

alter table public.family_tasks
  alter column sort_order drop not null;

create table if not exists public.family_task_completions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.family_tasks(id) on delete cascade,
  completed_at timestamptz not null default now(),
  day_key text not null,
  week_start text not null
);

alter table public.family_task_completions
  drop column if exists completed_by;

alter table public.family_task_completions
  drop column if exists points;

create table if not exists public.family_grocery_items (
  id uuid primary key default gen_random_uuid(),
  item text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  purchased_at timestamptz
);

create index if not exists family_tasks_active_sort_idx
  on public.family_tasks (active, sort_order, created_at);

create index if not exists family_task_completions_week_idx
  on public.family_task_completions (week_start, completed_at desc);

create unique index if not exists family_task_completions_task_day_idx
  on public.family_task_completions (task_id, day_key);

create index if not exists family_grocery_items_active_created_idx
  on public.family_grocery_items (active, created_at desc);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_tasks to anon, authenticated;
grant select, insert, update, delete on public.family_task_completions to anon, authenticated;
grant select, insert, update, delete on public.family_grocery_items to anon, authenticated;

alter table public.family_tasks enable row level security;
alter table public.family_task_completions enable row level security;
alter table public.family_grocery_items enable row level security;

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

drop policy if exists "family_grocery_items_public_all" on public.family_grocery_items;
create policy "family_grocery_items_public_all"
  on public.family_grocery_items
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
