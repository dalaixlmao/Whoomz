create table weight_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  weight_kg  numeric(5, 2) not null,
  logged_at  timestamptz not null default now()
);

alter table weight_logs enable row level security;

create policy "users manage own weight logs"
  on weight_logs for all
  using (auth.uid() = user_id);
