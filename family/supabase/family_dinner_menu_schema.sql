create extension if not exists pgcrypto;

create table if not exists public.family_dinner_menu (
  id text primary key default gen_random_uuid()::text,
  dinner_date date not null,
  week_start date not null,
  meal text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_dinner_menu'
      and column_name = 'id'
      and udt_name = 'uuid'
  ) then
    alter table public.family_dinner_menu
      alter column id drop default;

    alter table public.family_dinner_menu
      alter column id type text
      using id::text;

    alter table public.family_dinner_menu
      alter column id set default gen_random_uuid()::text;
  end if;
end $$;

alter table public.family_dinner_menu
  add column if not exists dinner_date date;

alter table public.family_dinner_menu
  add column if not exists week_start date;

alter table public.family_dinner_menu
  add column if not exists meal text not null default '';

alter table public.family_dinner_menu
  add column if not exists created_at timestamptz not null default now();

alter table public.family_dinner_menu
  add column if not exists updated_at timestamptz not null default now();

update public.family_dinner_menu
  set meal = ''
  where meal is null;

update public.family_dinner_menu
  set week_start = dinner_date - ((extract(dow from dinner_date)::integer + 6) % 7)
  where week_start is null
    and dinner_date is not null;

alter table public.family_dinner_menu
  alter column dinner_date set not null;

alter table public.family_dinner_menu
  alter column week_start set not null;

alter table public.family_dinner_menu
  alter column meal set default '';

alter table public.family_dinner_menu
  alter column meal set not null;

alter table public.family_dinner_menu
  alter column created_at set default now();

alter table public.family_dinner_menu
  alter column created_at set not null;

alter table public.family_dinner_menu
  alter column updated_at set default now();

alter table public.family_dinner_menu
  alter column updated_at set not null;

create unique index if not exists family_dinner_menu_date_idx
  on public.family_dinner_menu (dinner_date);

create index if not exists family_dinner_menu_week_idx
  on public.family_dinner_menu (week_start, dinner_date);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_dinner_menu to anon, authenticated;

alter table public.family_dinner_menu enable row level security;

drop policy if exists "family_dinner_menu_public_all" on public.family_dinner_menu;
create policy "family_dinner_menu_public_all"
  on public.family_dinner_menu
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
