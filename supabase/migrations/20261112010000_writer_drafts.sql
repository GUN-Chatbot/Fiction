create table if not exists public.writer_drafts (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  novel_id uuid references public.novels (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists writer_drafts_user_updated_idx
  on public.writer_drafts (user_id, updated_at desc);

alter table public.writer_drafts enable row level security;

grant select, insert, update, delete on public.writer_drafts to authenticated;

drop policy if exists "Users can read their writer drafts"
  on public.writer_drafts;
create policy "Users can read their writer drafts"
  on public.writer_drafts for select
  using (auth.uid() = user_id);

drop policy if exists "Users can create their writer drafts"
  on public.writer_drafts;
create policy "Users can create their writer drafts"
  on public.writer_drafts for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their writer drafts"
  on public.writer_drafts;
create policy "Users can update their writer drafts"
  on public.writer_drafts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their writer drafts"
  on public.writer_drafts;
create policy "Users can delete their writer drafts"
  on public.writer_drafts for delete
  using (auth.uid() = user_id);
