create extension if not exists pgcrypto;

create table if not exists public.family_people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color text not null default '#ec4899',
  active boolean not null default true,
  sort_order integer,
  created_at timestamptz not null default now()
);

alter table public.family_people
  add column if not exists active boolean not null default true;

alter table public.family_people
  add column if not exists sort_order integer;

do $$
begin
  if to_regclass('public.family_members') is not null then
    execute $copy_members$
      insert into public.family_people (id, name, color, active, sort_order, created_at)
      select
        legacy_member.id,
        legacy_member.name,
        coalesce(nullif(legacy_member.color, ''), '#ec4899'),
        true,
        row_number() over (order by legacy_member.created_at, legacy_member.name) * 10,
        coalesce(legacy_member.created_at, now())
      from public.family_members legacy_member
      where not exists (
        select 1
        from public.family_people person
        where person.id = legacy_member.id
          or lower(person.name) = lower(legacy_member.name)
      )
    $copy_members$;
  end if;
end $$;

alter table public.family_tasks
  add column if not exists assigned_person_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_tasks_assigned_person_id_fkey'
      and conrelid = 'public.family_tasks'::regclass
  ) then
    alter table public.family_tasks
      add constraint family_tasks_assigned_person_id_fkey
      foreign key (assigned_person_id)
      references public.family_people(id)
      on delete set null;
  end if;
end $$;

create table if not exists public.family_task_claims (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.family_tasks(id) on delete cascade,
  day_key text not null,
  person_id uuid not null references public.family_people(id) on delete cascade,
  claimed_at timestamptz not null default now()
);

create unique index if not exists family_task_claims_task_day_idx
  on public.family_task_claims (task_id, day_key);

create table if not exists public.family_task_type_colors (
  task_type text primary key,
  color text not null,
  updated_at timestamptz not null default now()
);

insert into public.family_task_type_colors (task_type, color)
values
  ('adhoc', '#22c55e'),
  ('daily', '#2563eb'),
  ('weekly', '#0f766e'),
  ('bi_weekly', '#0284c7'),
  ('monthly', '#14b8a6'),
  ('every_other_month', '#65a30d'),
  ('twice_a_year', '#eab308'),
  ('yearly', '#dc2626')
on conflict (task_type) do nothing;

create index if not exists family_tasks_assigned_person_idx
  on public.family_tasks (assigned_person_id);

create index if not exists family_people_active_sort_idx
  on public.family_people (active, sort_order, created_at);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_tasks to anon, authenticated;
grant select, insert, update, delete on public.family_people to anon, authenticated;
grant select, insert, update, delete on public.family_task_claims to anon, authenticated;
grant select, insert, update, delete on public.family_task_type_colors to anon, authenticated;

alter table public.family_tasks enable row level security;
alter table public.family_people enable row level security;
alter table public.family_task_claims enable row level security;
alter table public.family_task_type_colors enable row level security;

drop policy if exists "family_tasks_public_all" on public.family_tasks;
create policy "family_tasks_public_all"
  on public.family_tasks
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_people_public_all" on public.family_people;
create policy "family_people_public_all"
  on public.family_people
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_task_claims_public_all" on public.family_task_claims;
create policy "family_task_claims_public_all"
  on public.family_task_claims
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "family_task_type_colors_public_all" on public.family_task_type_colors;
create policy "family_task_type_colors_public_all"
  on public.family_task_type_colors
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
