-- Extend recurrence_interval check constraint to allow the new
-- "quarterly" (every 3 months from an anchor month) and "project"
-- (one-off until marked done) recurrence types.
--
-- Run this in the Supabase SQL editor against the family Supabase project.

alter table public.family_project_tasks
  drop constraint if exists family_project_tasks_recurrence_interval_check;

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
