-- Remove exact-duplicate rows from family_tasks
-- "Exact" = same title AND same recurrence_interval AND same schedule fields.
-- Keeps the OLDEST row in each duplicate group (by created_at, then id).
-- Intentional same-title-different-schedule rows (e.g. Garbage Disposal Jan&Jul
-- + Apr&Oct) are preserved because their schedule columns differ.
--
-- NOTE: this is a hard delete. If a duplicate has completion rows in
-- family_task_completions or claims in family_task_claims, those become
-- orphans. Cleanup queries for those are at the bottom of this file.

-- ─── STEP 1: PREVIEW (run first to see what would be deleted) ───────────
WITH ranked AS (
  SELECT
    id,
    title,
    recurrence_interval,
    created_at,
    ROW_NUMBER() OVER (
      PARTITION BY
        title,
        recurrence_interval,
        recurrence_day_of_week,
        recurrence_day_of_week_2,
        recurrence_week_of_month,
        recurrence_month,
        recurrence_month_2,
        recurrence_day_of_month
      ORDER BY created_at ASC, id ASC
    ) AS rn
  FROM family_tasks
)
SELECT id, title, recurrence_interval, created_at
FROM ranked
WHERE rn > 1
ORDER BY title, created_at;

-- ─── STEP 2: DELETE the duplicates (run after reviewing above) ──────────
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY
        title,
        recurrence_interval,
        recurrence_day_of_week,
        recurrence_day_of_week_2,
        recurrence_week_of_month,
        recurrence_month,
        recurrence_month_2,
        recurrence_day_of_month
      ORDER BY created_at ASC, id ASC
    ) AS rn
  FROM family_tasks
)
DELETE FROM family_tasks
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- ─── STEP 3 (optional): clean up orphaned completion / claim rows ──────
DELETE FROM family_task_completions
WHERE task_id NOT IN (SELECT id FROM family_tasks);

DELETE FROM family_task_claims
WHERE task_id NOT IN (SELECT id FROM family_tasks);
