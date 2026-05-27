create table workout_exercises (
  id             uuid primary key default gen_random_uuid(),
  workout_id     uuid references workouts(id) on delete cascade not null,
  exercise_name  text not null,
  tracking_type  text check (tracking_type in (
                   'sets_reps_weight',
                   'distance_duration',
                   'laps',
                   'duration_only',
                   'freeform'
                 )) not null,
  metrics        jsonb not null default '{}',
  "order"        int not null,
  notes          text
);

alter table workout_exercises enable row level security;

-- RLS via join: user must own the parent workout (no direct user_id column)
create policy "Users can manage exercises in their own workouts"
  on workout_exercises for all
  using (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );
