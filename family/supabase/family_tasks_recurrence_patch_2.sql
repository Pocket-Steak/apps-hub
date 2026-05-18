-- Add second month for Twice A Year so it can fire on the Nth weekday
-- of two independently chosen months (e.g. 1st Sunday of January and July).
alter table public.family_tasks
  add column if not exists recurrence_month_2 integer not null default 7;

update public.family_tasks
  set recurrence_month_2 = 7
  where recurrence_month_2 < 1 or recurrence_month_2 > 12;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'family_tasks_recurrence_month_2_check'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_recurrence_month_2_check
      check (recurrence_month_2 between 1 and 12);
  end if;
end $$;

select pg_notify('pgrst', 'reload schema');
