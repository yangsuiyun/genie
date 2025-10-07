-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled', 'on_hold')),
    priority VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    tags TEXT[] DEFAULT '{}',
    estimated_pomodoros INTEGER DEFAULT 1 CHECK (estimated_pomodoros > 0),
    actual_pomodoros INTEGER DEFAULT 0 CHECK (actual_pomodoros >= 0),
    progress_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    recurrence_rule_id UUID REFERENCES recurrence_rules(id) ON DELETE SET NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    next_occurrence TIMESTAMP WITH TIME ZONE,
    original_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for tasks table
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks(completed_at);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id ON tasks(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_recurrence_rule_id ON tasks(recurrence_rule_id);
CREATE INDEX IF NOT EXISTS idx_tasks_is_recurring ON tasks(is_recurring);
CREATE INDEX IF NOT EXISTS idx_tasks_next_occurrence ON tasks(next_occurrence);
CREATE INDEX IF NOT EXISTS idx_tasks_original_task_id ON tasks(original_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_tags ON tasks USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);
CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON tasks(updated_at);
CREATE INDEX IF NOT EXISTS idx_tasks_deleted_at ON tasks(deleted_at);
CREATE INDEX IF NOT EXISTS idx_tasks_sync_version ON tasks(sync_version);
CREATE INDEX IF NOT EXISTS idx_tasks_device_id ON tasks(device_id);
CREATE INDEX IF NOT EXISTS idx_tasks_last_synced_at ON tasks(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_user_status_priority ON tasks(user_id, status, priority);
CREATE INDEX IF NOT EXISTS idx_tasks_user_due_date ON tasks(user_id, due_date) WHERE due_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_user_recurring ON tasks(user_id, is_recurring) WHERE is_recurring = TRUE;

-- Create trigger for tasks table
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to update parent task progress
CREATE OR REPLACE FUNCTION update_parent_task_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if this task has a parent
    IF NEW.parent_task_id IS NOT NULL THEN
        UPDATE tasks
        SET progress_percentage = (
            SELECT COALESCE(AVG(progress_percentage), 0)
            FROM tasks
            WHERE parent_task_id = NEW.parent_task_id
            AND deleted_at IS NULL
        ),
        updated_at = NOW()
        WHERE id = NEW.parent_task_id;
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to update parent task progress
CREATE TRIGGER update_parent_task_progress_trigger
    AFTER UPDATE OF progress_percentage ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_parent_task_progress();

-- Add comments
COMMENT ON TABLE tasks IS 'User tasks with hierarchical structure and recurrence support';
COMMENT ON COLUMN tasks.estimated_pomodoros IS 'Estimated number of pomodoro sessions needed';
COMMENT ON COLUMN tasks.actual_pomodoros IS 'Actual number of pomodoro sessions completed';
COMMENT ON COLUMN tasks.progress_percentage IS 'Task completion percentage (0-100)';
COMMENT ON COLUMN tasks.parent_task_id IS 'Parent task for subtask hierarchies';
COMMENT ON COLUMN tasks.recurrence_rule_id IS 'Reference to recurrence pattern';
COMMENT ON COLUMN tasks.next_occurrence IS 'Next scheduled occurrence for recurring tasks';
COMMENT ON COLUMN tasks.original_task_id IS 'Reference to original task for recurring instances';
COMMENT ON COLUMN tasks.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN tasks.device_id IS 'ID of device that last modified this task';