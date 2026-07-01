-- Trainer-scheduled weight trial days: specific date + workout schedule day

CREATE TABLE public.workout_weight_trials (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_day_id  UUID NOT NULL REFERENCES public.workout_schedule_days(id) ON DELETE CASCADE,
  trainee_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trial_date       DATE NOT NULL,
  note             TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (trainee_id, trial_date)
);

CREATE INDEX idx_workout_weight_trials_trainee_date
  ON public.workout_weight_trials (trainee_id, trial_date);

CREATE INDEX idx_workout_weight_trials_schedule_day
  ON public.workout_weight_trials (schedule_day_id);

CREATE TRIGGER on_workout_weight_trial_updated
  BEFORE UPDATE ON public.workout_weight_trials
  FOR EACH ROW EXECUTE FUNCTION public.set_workout_updated_at();

ALTER TABLE public.workout_weight_trials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainees read own weight trials"
  ON public.workout_weight_trials FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers manage assigned weight trials"
  ON public.workout_weight_trials FOR ALL
  USING (public.is_trainer_of_trainee(trainee_id))
  WITH CHECK (
    trainer_id = auth.uid()
    AND public.is_trainer_of_trainee(trainee_id)
  );
