alter table public.novels
  add column if not exists user_id uuid references auth.users (id) on delete set null;

create index if not exists novels_user_id_idx
  on public.novels (user_id);
