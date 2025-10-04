-- Create pomodoro sessions table
CREATE TABLE IF NOT EXISTS pomodoro_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'work' CHECK (type IN ('work', 'short_break', 'long_break')),
    status VARCHAR(20) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'paused', 'completed', 'cancelled', 'interrupted')),
    duration_minutes INTEGER NOT NULL DEFAULT 25 CHECK (duration_minutes > 0),
    remaining_seconds INTEGER DEFAULT 0 CHECK (remaining_seconds >= 0),
    started_at TIMESTAMP WITH TIME ZONE,
    paused_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    interruptions INTEGER DEFAULT 0 CHECK (interruptions >= 0),
    interruption_notes TEXT[],
    session_number INTEGER DEFAULT 1 CHECK (session_number > 0),
    is_break_after BOOLEAN DEFAULT FALSE,
    productivity_rating INTEGER CHECK (productivity_rating IS NULL OR (productivity_rating >= 1 AND productivity_rating <= 5)),
    focus_rating INTEGER CHECK (focus_rating IS NULL OR (focus_rating >= 1 AND focus_rating <= 5)),
    tags TEXT[] DEFAULT '{}',
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for pomodoro sessions table
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_id ON pomodoro_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_task_id ON pomodoro_sessions(task_id);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_type ON pomodoro_sessions(type);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_status ON pomodoro_sessions(status);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_started_at ON pomodoro_sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_completed_at ON pomodoro_sessions(completed_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_session_number ON pomodoro_sessions(session_number);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_productivity_rating ON pomodoro_sessions(productivity_rating);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_focus_rating ON pomodoro_sessions(focus_rating);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_tags ON pomodoro_sessions USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_created_at ON pomodoro_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_updated_at ON pomodoro_sessions(updated_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_deleted_at ON pomodoro_sessions(deleted_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_sync_version ON pomodoro_sessions(sync_version);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_device_id ON pomodoro_sessions(device_id);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_last_synced_at ON pomodoro_sessions(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_status ON pomodoro_sessions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_type_completed ON pomodoro_sessions(user_id, type, completed_at);
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_task_completed ON pomodoro_sessions(task_id, completed_at) WHERE task_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_date_range ON pomodoro_sessions(user_id, started_at) WHERE started_at IS NOT NULL;

-- Create trigger for pomodoro sessions table
CREATE TRIGGER update_pomodoro_sessions_updated_at
    BEFORE UPDATE ON pomodoro_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to update task's actual pomodoros count
CREATE OR REPLACE FUNCTION update_task_actual_pomodoros()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if this session is for a task and is completed
    IF NEW.task_id IS NOT NULL AND NEW.status = 'completed' AND NEW.type = 'work' THEN
        UPDATE tasks
        SET
            actual_pomodoros = (
                SELECT COUNT(*)
                FROM pomodoro_sessions
                WHERE task_id = NEW.task_id
                AND status = 'completed'
                AND type = 'work'
                AND deleted_at IS NULL
            ),
            updated_at = NOW()
        WHERE id = NEW.task_id;
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to update task's actual pomodoros
CREATE TRIGGER update_task_actual_pomodoros_trigger
    AFTER UPDATE OF status ON pomodoro_sessions
    FOR EACH ROW
    WHEN (NEW.status = 'completed' AND NEW.type = 'work')
    EXECUTE FUNCTION update_task_actual_pomodoros();

-- Create function to validate session state transitions
CREATE OR REPLACE FUNCTION validate_session_state_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- Define valid state transitions
    IF OLD.status IS NOT NULL THEN
        CASE OLD.status
            WHEN 'planned' THEN
                IF NEW.status NOT IN ('active', 'cancelled') THEN
                    RAISE EXCEPTION 'Invalid transition from planned to %', NEW.status;
                END IF;
            WHEN 'active' THEN
                IF NEW.status NOT IN ('paused', 'completed', 'cancelled', 'interrupted') THEN
                    RAISE EXCEPTION 'Invalid transition from active to %', NEW.status;
                END IF;
            WHEN 'paused' THEN
                IF NEW.status NOT IN ('active', 'completed', 'cancelled') THEN
                    RAISE EXCEPTION 'Invalid transition from paused to %', NEW.status;
                END IF;
            WHEN 'completed' THEN
                -- Completed sessions cannot change status
                IF NEW.status != 'completed' THEN
                    RAISE EXCEPTION 'Cannot change status of completed session';
                END IF;
            WHEN 'cancelled' THEN
                -- Cancelled sessions cannot change status
                IF NEW.status != 'cancelled' THEN
                    RAISE EXCEPTION 'Cannot change status of cancelled session';
                END IF;
            WHEN 'interrupted' THEN
                IF NEW.status NOT IN ('active', 'cancelled') THEN
                    RAISE EXCEPTION 'Invalid transition from interrupted to %', NEW.status;
                END IF;
        END CASE;
    END IF;

    -- Set timestamps based on status
    CASE NEW.status
        WHEN 'active' THEN
            IF OLD.status = 'planned' THEN
                NEW.started_at = NOW();
            END IF;
            NEW.paused_at = NULL;
        WHEN 'paused' THEN
            NEW.paused_at = NOW();
        WHEN 'completed' THEN
            NEW.completed_at = NOW();
            NEW.paused_at = NULL;
        WHEN 'cancelled' THEN
            NEW.cancelled_at = NOW();
            NEW.paused_at = NULL;
    END CASE;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for session state validation
CREATE TRIGGER validate_session_state_transition_trigger
    BEFORE UPDATE OF status ON pomodoro_sessions
    FOR EACH ROW
    EXECUTE FUNCTION validate_session_state_transition();

-- Add comments
COMMENT ON TABLE pomodoro_sessions IS 'Pomodoro work and break sessions with state tracking';
COMMENT ON COLUMN pomodoro_sessions.type IS 'Type of session: work, short_break, or long_break';
COMMENT ON COLUMN pomodoro_sessions.status IS 'Current status of the session';
COMMENT ON COLUMN pomodoro_sessions.duration_minutes IS 'Planned duration in minutes';
COMMENT ON COLUMN pomodoro_sessions.remaining_seconds IS 'Remaining time in seconds (for pause/resume)';
COMMENT ON COLUMN pomodoro_sessions.interruptions IS 'Number of interruptions during session';
COMMENT ON COLUMN pomodoro_sessions.interruption_notes IS 'Notes about each interruption';
COMMENT ON COLUMN pomodoro_sessions.session_number IS 'Session number in current cycle';
COMMENT ON COLUMN pomodoro_sessions.is_break_after IS 'Whether this session triggers a break';
COMMENT ON COLUMN pomodoro_sessions.productivity_rating IS 'User rating of productivity (1-5)';
COMMENT ON COLUMN pomodoro_sessions.focus_rating IS 'User rating of focus level (1-5)';
COMMENT ON COLUMN pomodoro_sessions.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN pomodoro_sessions.device_id IS 'ID of device that last modified this session';