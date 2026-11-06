-- Run this once in Supabase Dashboard > SQL Editor for the project used by index.html.
-- Existing website records/photos are NOT deleted or replaced by this setup.

create table if not exists public.cadet_changes (
  cadet_key text primary key,
  action text not null check (action in ('upsert','delete')),
  record jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.cadet_changes enable row level security;

-- Visitors can read the changes that are layered over the existing static directory.
drop policy if exists "Public can read cadet changes" on public.cadet_changes;
create policy "Public can read cadet changes"
  on public.cadet_changes for select
  to anon, authenticated
  using (true);

-- Admin and ANO accounts may add/edit records. Role is checked against user_roles.
drop policy if exists "Staff can add cadet changes" on public.cadet_changes;
create policy "Staff can add cadet changes"
  on public.cadet_changes for insert
  to authenticated
  with check (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  );

drop policy if exists "Staff can update cadet changes" on public.cadet_changes;
create policy "Staff can update cadet changes"
  on public.cadet_changes for update
  to authenticated
  using (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  )
  with check (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  );

-- Public photo URLs are used in the directory; uploads are restricted to staff.
insert into storage.buckets (id, name, public)
values ('cadet-photos', 'cadet-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view cadet photos" on storage.objects;
create policy "Public can view cadet photos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'cadet-photos');

drop policy if exists "Staff can upload cadet photos" on storage.objects;
create policy "Staff can upload cadet photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'cadet-photos' and exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  );

drop policy if exists "Staff can update cadet photos" on storage.objects;
create policy "Staff can update cadet photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'cadet-photos' and exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  )
  with check (
    bucket_id = 'cadet-photos' and exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role in ('admin','ano')
    )
  );

drop policy if exists "Admin can delete cadet photos" on storage.objects;
create policy "Admin can delete cadet photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'cadet-photos' and exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role = 'admin'
    )
  );
