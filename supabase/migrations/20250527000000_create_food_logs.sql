create table food_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade not null,
  name       text not null,
  calories   int not null,
  protein_g  float,
  carbs_g    float,
  fat_g      float,
  meal_type  text check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')) not null,
  logged_at  timestamptz not null default now()
);

alter table food_logs enable row level security;

create policy "Users can manage their own food logs"
  on food_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
