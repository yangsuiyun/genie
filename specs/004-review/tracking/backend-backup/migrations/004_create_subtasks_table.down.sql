-- Drop subtasks table and related objects
DROP TRIGGER IF EXISTS update_task_progress_on_subtask_delete ON subtasks;
DROP TRIGGER IF EXISTS update_task_progress_on_subtask_update ON subtasks;
DROP TRIGGER IF EXISTS update_task_progress_on_subtask_insert ON subtasks;
DROP TRIGGER IF EXISTS update_subtasks_updated_at ON subtasks;
DROP FUNCTION IF EXISTS update_task_progress_from_subtasks();
DROP TABLE IF EXISTS subtasks CASCADE;