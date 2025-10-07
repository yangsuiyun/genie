-- Drop tasks table and related objects
DROP TRIGGER IF EXISTS update_parent_task_progress_trigger ON tasks;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP FUNCTION IF EXISTS update_parent_task_progress();
DROP TABLE IF EXISTS tasks CASCADE;