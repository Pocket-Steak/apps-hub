-- Add second day-of-week for twice_weekly recurrence
alter table public.family_tasks
  add column if not exists recurrence_day_of_week_2 integer not null default 4;

-- Add week-of-month for Nth-weekday monthly recurrence (1-5, -1 = last)
alter table public.family_tasks
  add column if not exists recurrence_week_of_month integer not null default 1;

-- Validate new columns
update public.family_tasks
  set recurrence_day_of_week_2 = 4
  where recurrence_day_of_week_2 < 0 or recurrence_day_of_week_2 > 6;

update public.family_tasks
  set recurrence_week_of_month = 1
  where recurrence_week_of_month not in (-1, 1, 2, 3, 4, 5);

-- Drop the old recurrence_interval constraint and recreate with twice_weekly
alter table public.family_tasks
  drop constraint if exists family_tasks_recurrence_interval_check;

alter table public.family_tasks
  add constraint family_tasks_recurrence_interval_check
  check (recurrence_interval in (
    'daily',
    'weekly',
    'twice_weekly',
    'bi_weekly',
    'monthly',
    'every_other_month',
    'twice_a_year',
    'yearly'
  ));

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'family_tasks_recurrence_day_of_week_2_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_day_of_week_2_check
      check (recurrence_day_of_week_2 between 0 and 6);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'family_tasks_recurrence_week_of_month_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_week_of_month_check
      check (recurrence_week_of_month in (-1, 1, 2, 3, 4, 5));
  end if;
end $$;

-- Add twice_weekly task type color
insert into public.family_task_type_colors (task_type, color)
values ('twice_weekly', '#7c3aed')
on conflict (task_type) do nothing;

select pg_notify('pgrst', 'reload schema');
