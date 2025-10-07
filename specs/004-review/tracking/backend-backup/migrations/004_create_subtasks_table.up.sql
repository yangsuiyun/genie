-- Create subtasks table
CREATE TABLE IF NOT EXISTS subtasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    order_index INTEGER NOT NULL DEFAULT 0,
    estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    actual_minutes INTEGER DEFAULT 0 CHECK (actual_minutes >= 0),
    completed_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for subtasks table
CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON subtasks(task_id);
CREATE INDEX IF NOT EXISTS idx_subtasks_status ON subtasks(status);
CREATE INDEX IF NOT EXISTS idx_subtasks_order_index ON subtasks(order_index);
CREATE INDEX IF NOT EXISTS idx_subtasks_completed_at ON subtasks(completed_at);
CREATE INDEX IF NOT EXISTS idx_subtasks_created_at ON subtasks(created_at);
CREATE INDEX IF NOT EXISTS idx_subtasks_updated_at ON subtasks(updated_at);
CREATE INDEX IF NOT EXISTS idx_subtasks_deleted_at ON subtasks(deleted_at);
CREATE INDEX IF NOT EXISTS idx_subtasks_sync_version ON subtasks(sync_version);
CREATE INDEX IF NOT EXISTS idx_subtasks_device_id ON subtasks(device_id);
CREATE INDEX IF NOT EXISTS idx_subtasks_last_synced_at ON subtasks(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_subtasks_task_order ON subtasks(task_id, order_index);
CREATE INDEX IF NOT EXISTS idx_subtasks_task_status ON subtasks(task_id, status);

-- Create trigger for subtasks table
CREATE TRIGGER update_subtasks_updated_at
    BEFORE UPDATE ON subtasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to update parent task progress when subtask changes
CREATE OR REPLACE FUNCTION update_task_progress_from_subtasks()
RETURNS TRIGGER AS $$
DECLARE
    total_subtasks INTEGER;
    completed_subtasks INTEGER;
    new_progress DECIMAL(5,2);
BEGIN
    -- Get the task_id (could be from NEW or OLD depending on operation)
    DECLARE task_uuid UUID;
    BEGIN
        IF TG_OP = 'DELETE' THEN
            task_uuid := OLD.task_id;
        ELSE
            task_uuid := NEW.task_id;
        END IF;

        -- Count total and completed subtasks
        SELECT
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE status = 'completed') as completed
        INTO total_subtasks, completed_subtasks
        FROM subtasks
        WHERE task_id = task_uuid AND deleted_at IS NULL;

        -- Calculate new progress percentage
        IF total_subtasks = 0 THEN
            new_progress := 0;
        ELSE
            new_progress := (completed_subtasks::DECIMAL / total_subtasks::DECIMAL) * 100;
        END IF;

        -- Update parent task progress
        UPDATE tasks
        SET
            progress_percentage = new_progress,
            updated_at = NOW()
        WHERE id = task_uuid;
    END;

    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Create triggers to update task progress when subtasks change
CREATE TRIGGER update_task_progress_on_subtask_insert
    AFTER INSERT ON subtasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_progress_from_subtasks();

CREATE TRIGGER update_task_progress_on_subtask_update
    AFTER UPDATE OF status ON subtasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_progress_from_subtasks();

CREATE TRIGGER update_task_progress_on_subtask_delete
    AFTER DELETE ON subtasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_progress_from_subtasks();

-- Add unique constraint for task_id and order_index combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_subtasks_task_order_unique
ON subtasks(task_id, order_index)
WHERE deleted_at IS NULL;

-- Add comments
COMMENT ON TABLE subtasks IS 'Subtasks that belong to parent tasks';
COMMENT ON COLUMN subtasks.order_index IS 'Order of subtask within parent task (0-based)';
COMMENT ON COLUMN subtasks.estimated_minutes IS 'Estimated time to complete subtask in minutes';
COMMENT ON COLUMN subtasks.actual_minutes IS 'Actual time spent on subtask in minutes';
COMMENT ON COLUMN subtasks.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN subtasks.device_id IS 'ID of device that last modified this subtask';