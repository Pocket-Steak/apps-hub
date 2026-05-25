-- Family Doodles: finger-drawn images saved from any device (family hub,
-- HQ.V2 mobile/terminal, PinkLimeade mobile). Images stored as a PNG
-- base64 data URL in image_data for portability across the three apps.
--
-- Run this in the Supabase SQL editor against the family Supabase project
-- (vmmdskviwqddgalccoyc.supabase.co).

create table if not exists public.family_doodles (
  id uuid primary key default gen_random_uuid(),
  image_data text not null,
  width int not null default 800,
  height int not null default 800,
  created_at timestamptz not null default now()
);

create index if not exists family_doodles_created_at_idx
  on public.family_doodles (created_at desc);

alter table public.family_doodles enable row level security;

drop policy if exists "family_doodles_public_all" on public.family_doodles;
create policy "family_doodles_public_all"
  on public.family_doodles
  for all
  to anon, authenticated
  using (true)
  with check (true);

select pg_notify('pgrst', 'reload schema');
