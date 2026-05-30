create table daily_notes (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references auth.users(id) on delete cascade,
  date     date not null,
  note     text not null,
  unique (user_id, date)
);

alter table daily_notes enable row level security;

create policy "users manage own daily notes"
  on daily_notes for all
  using (auth.uid() = user_id);
