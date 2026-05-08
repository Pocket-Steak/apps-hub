create extension if not exists pgcrypto;

create table if not exists public.family_notes (
  id text primary key default gen_random_uuid()::text,
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_notes'
      and column_name = 'id'
      and udt_name = 'uuid'
  ) then
    alter table public.family_notes
      alter column id drop default;

    alter table public.family_notes
      alter column id type text
      using id::text;

    alter table public.family_notes
      alter column id set default gen_random_uuid()::text;
  end if;
end $$;

alter table public.family_notes
  add column if not exists body text not null default '';

alter table public.family_notes
  add column if not exists created_at timestamptz not null default now();

alter table public.family_notes
  add column if not exists updated_at timestamptz not null default now();

update public.family_notes
  set body = ''
  where body is null;

update public.family_notes
  set created_at = coalesce(updated_at, now())
  where created_at is null;

update public.family_notes
  set updated_at = coalesce(created_at, now())
  where updated_at is null;

alter table public.family_notes
  alter column body set default '';

alter table public.family_notes
  alter column body set not null;

alter table public.family_notes
  alter column created_at set default now();

alter table public.family_notes
  alter column created_at set not null;

alter table public.family_notes
  alter column updated_at set default now();

alter table public.family_notes
  alter column updated_at set not null;

create index if not exists family_notes_updated_idx
  on public.family_notes (updated_at desc);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.family_notes to anon, authenticated;

alter table public.family_notes enable row level security;

drop policy if exists "family_notes_public_all" on public.family_notes;
create policy "family_notes_public_all"
  on public.family_notes
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
