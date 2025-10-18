-- ======================================================================
-- Ensure extensions (for gen_random_uuid)
-- ======================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ======================================================================
-- Helper trigger function: auto-update updated_at on UPDATE
-- ======================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ======================================================================
-- WINDOWS TABLE  (public.wellness_program_windows)
-- Final shape as per your dump:
-- id uuid PK, program_id uuid NOT NULL, window_index int NOT NULL,
-- offset_sec int NOT NULL, reveal_seconds int NOT NULL DEFAULT 60,
-- window_marks int NOT NULL DEFAULT 5, announce boolean NOT NULL DEFAULT true,
-- created_at timestamptz NOT NULL DEFAULT now(),
-- updated_at timestamptz NOT NULL DEFAULT now(),
-- duration_sec int NOT NULL DEFAULT 900,
-- enabled boolean NOT NULL DEFAULT true
-- ======================================================================

-- 0) Create table if it doesn't exist (minimal structure to allow ALTERs)
CREATE TABLE IF NOT EXISTS public.wellness_program_windows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

-- 1) Ensure required columns exist (with defaults where appropriate)
ALTER TABLE public.wellness_program_windows
  ADD COLUMN IF NOT EXISTS program_id     uuid                     NOT NULL,
  ADD COLUMN IF NOT EXISTS window_index   integer                  NOT NULL,
  ADD COLUMN IF NOT EXISTS offset_sec     integer                  NOT NULL,
  ADD COLUMN IF NOT EXISTS reveal_seconds integer                  NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS window_marks   integer                  NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS announce       boolean                  NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at     timestamp with time zone NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at     timestamp with time zone NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS duration_sec   integer                  NOT NULL DEFAULT 900,
  ADD COLUMN IF NOT EXISTS enabled        boolean                  NOT NULL DEFAULT true;

-- 2) Backfill NULLs (safety) then enforce NOT NULL (idempotent)
UPDATE public.wellness_program_windows SET reveal_seconds = 60  WHERE reveal_seconds IS NULL;
UPDATE public.wellness_program_windows SET window_marks   = 5   WHERE window_marks   IS NULL;
UPDATE public.wellness_program_windows SET announce       = TRUE WHERE announce       IS NULL;
UPDATE public.wellness_program_windows SET created_at     = NOW() WHERE created_at   IS NULL;
UPDATE public.wellness_program_windows SET updated_at     = NOW() WHERE updated_at   IS NULL;
UPDATE public.wellness_program_windows SET duration_sec   = 900 WHERE duration_sec   IS NULL;
UPDATE public.wellness_program_windows SET enabled        = TRUE WHERE enabled       IS NULL;

ALTER TABLE public.wellness_program_windows
  ALTER COLUMN program_id     SET NOT NULL,
  ALTER COLUMN window_index   SET NOT NULL,
  ALTER COLUMN offset_sec     SET NOT NULL,
  ALTER COLUMN reveal_seconds SET NOT NULL,
  ALTER COLUMN window_marks   SET NOT NULL,
  ALTER COLUMN announce       SET NOT NULL,
  ALTER COLUMN created_at     SET NOT NULL,
  ALTER COLUMN updated_at     SET NOT NULL,
  ALTER COLUMN duration_sec   SET NOT NULL,
  ALTER COLUMN enabled        SET NOT NULL;

-- 3) Range checks (idempotent by constraint name)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpw_window_index_ck') THEN
    ALTER TABLE public.wellness_program_windows
      ADD CONSTRAINT wpw_window_index_ck CHECK (window_index >= 1);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpw_offset_sec_ck') THEN
    ALTER TABLE public.wellness_program_windows
      ADD CONSTRAINT wpw_offset_sec_ck CHECK (offset_sec >= 0);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpw_duration_sec_ck') THEN
    ALTER TABLE public.wellness_program_windows
      ADD CONSTRAINT wpw_duration_sec_ck CHECK (duration_sec > 0);
  END IF;
END $$;

-- 4) (Optional) FK to programs (only if programs table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'wellness_programs' AND relkind = 'r') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'wpw_program_fk'
    ) THEN
      ALTER TABLE public.wellness_program_windows
        ADD CONSTRAINT wpw_program_fk
        FOREIGN KEY (program_id)
        REFERENCES public.wellness_programs(id)
        ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- 5) Unique key for upsert (program_id, window_index)
--    (If duplicates exist, migration will fail; clean manually or script a cleanup step.)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpw_program_id_window_index_uniq') THEN
    ALTER TABLE public.wellness_program_windows
      ADD CONSTRAINT wpw_program_id_window_index_uniq
      UNIQUE (program_id, window_index);
  END IF;
END $$;

-- 6) Helpful indexes
CREATE INDEX IF NOT EXISTS idx_wpw_program_id ON public.wellness_program_windows (program_id);

-- 7) Auto-updating updated_at trigger
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_wpw'
  ) THEN
    CREATE TRIGGER set_timestamp_wpw
    BEFORE UPDATE ON public.wellness_program_windows
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

-- ======================================================================
-- AUDIOS TABLE  (public.wellness_program_audios)
-- Shape aligned with your routes:
-- id uuid PK, program_id uuid NOT NULL, language_code text NOT NULL,
-- audio_url text NOT NULL, enabled boolean NOT NULL DEFAULT true,
-- volume numeric(3,2) NULL, created_at timestamptz NOT NULL DEFAULT now(),
-- updated_at timestamptz NOT NULL DEFAULT now(),
-- UNIQUE (program_id, language_code)
-- ======================================================================

-- 0) Create table if missing (minimal)
CREATE TABLE IF NOT EXISTS public.wellness_program_audios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

-- 1) Ensure columns
ALTER TABLE public.wellness_program_audios
  ADD COLUMN IF NOT EXISTS program_id     uuid                     NOT NULL,
  ADD COLUMN IF NOT EXISTS language_code  text                     NOT NULL,
  ADD COLUMN IF NOT EXISTS audio_url      text                     NOT NULL,
  ADD COLUMN IF NOT EXISTS enabled        boolean                  NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS volume         numeric(3,2),
  ADD COLUMN IF NOT EXISTS created_at     timestamp with time zone NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at     timestamp with time zone NOT NULL DEFAULT now();

-- 2) Range check for volume (0..1)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpa_volume_ck') THEN
    ALTER TABLE public.wellness_program_audios
      ADD CONSTRAINT wpa_volume_ck CHECK (volume IS NULL OR (volume >= 0 AND volume <= 1));
  END IF;
END $$;

-- 3) (Optional) FK to programs if table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'wellness_programs' AND relkind = 'r') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'wpa_program_fk'
    ) THEN
      ALTER TABLE public.wellness_program_audios
        ADD CONSTRAINT wpa_program_fk
        FOREIGN KEY (program_id)
        REFERENCES public.wellness_programs(id)
        ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- 4) Unique key for upsert (program_id, language_code)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wpa_program_id_language_code_uniq') THEN
    ALTER TABLE public.wellness_program_audios
      ADD CONSTRAINT wpa_program_id_language_code_uniq
      UNIQUE (program_id, language_code);
  END IF;
END $$;

-- 5) Helpful index
CREATE INDEX IF NOT EXISTS idx_wpa_program_id ON public.wellness_program_audios (program_id);

-- 6) Auto-updating updated_at trigger
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_wpa'
  ) THEN
    CREATE TRIGGER set_timestamp_wpa
    BEFORE UPDATE ON public.wellness_program_audios
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

-- ======================================================================
-- Refresh PostgREST schema cache (Supabase)
-- ======================================================================
NOTIFY pgrst, 'reload schema';
