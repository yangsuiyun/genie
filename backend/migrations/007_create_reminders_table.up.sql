-- Create reminders table
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    reminder_type VARCHAR(20) NOT NULL DEFAULT 'task_due' CHECK (
        reminder_type IN ('task_due', 'task_start', 'session_start', 'session_break', 'custom', 'daily_review', 'weekly_review')
    ),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'dismissed', 'snoozed', 'failed')),
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    snoozed_until TIMESTAMP WITH TIME ZONE,
    delivery_method VARCHAR(20) NOT NULL DEFAULT 'push' CHECK (
        delivery_method IN ('push', 'email', 'sms', 'in_app', 'desktop')
    ),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule_id UUID REFERENCES recurrence_rules(id) ON DELETE SET NULL,
    next_occurrence TIMESTAMP WITH TIME ZONE,
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    metadata JSONB DEFAULT '{}'::JSONB,
    retry_count INTEGER DEFAULT 0 CHECK (retry_count >= 0),
    max_retries INTEGER DEFAULT 3 CHECK (max_retries >= 0),
    last_retry_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for reminders table
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_task_id ON reminders(task_id);
CREATE INDEX IF NOT EXISTS idx_reminders_reminder_type ON reminders(reminder_type);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON reminders(status);
CREATE INDEX IF NOT EXISTS idx_reminders_scheduled_for ON reminders(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_reminders_sent_at ON reminders(sent_at);
CREATE INDEX IF NOT EXISTS idx_reminders_snoozed_until ON reminders(snoozed_until);
CREATE INDEX IF NOT EXISTS idx_reminders_delivery_method ON reminders(delivery_method);
CREATE INDEX IF NOT EXISTS idx_reminders_is_recurring ON reminders(is_recurring);
CREATE INDEX IF NOT EXISTS idx_reminders_recurrence_rule_id ON reminders(recurrence_rule_id);
CREATE INDEX IF NOT EXISTS idx_reminders_next_occurrence ON reminders(next_occurrence);
CREATE INDEX IF NOT EXISTS idx_reminders_priority ON reminders(priority);
CREATE INDEX IF NOT EXISTS idx_reminders_retry_count ON reminders(retry_count);
CREATE INDEX IF NOT EXISTS idx_reminders_created_at ON reminders(created_at);
CREATE INDEX IF NOT EXISTS idx_reminders_updated_at ON reminders(updated_at);
CREATE INDEX IF NOT EXISTS idx_reminders_deleted_at ON reminders(deleted_at);
CREATE INDEX IF NOT EXISTS idx_reminders_sync_version ON reminders(sync_version);
CREATE INDEX IF NOT EXISTS idx_reminders_device_id ON reminders(device_id);
CREATE INDEX IF NOT EXISTS idx_reminders_last_synced_at ON reminders(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reminders_user_status_scheduled ON reminders(user_id, status, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_reminders_pending_scheduled ON reminders(status, scheduled_for) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_reminders_snoozed_until_active ON reminders(snoozed_until) WHERE status = 'snoozed';
CREATE INDEX IF NOT EXISTS idx_reminders_task_scheduled ON reminders(task_id, scheduled_for) WHERE task_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reminders_recurring_next ON reminders(is_recurring, next_occurrence) WHERE is_recurring = TRUE;

-- Create trigger for reminders table
CREATE TRIGGER update_reminders_updated_at
    BEFORE UPDATE ON reminders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to get due reminders
CREATE OR REPLACE FUNCTION get_due_reminders(
    check_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    batch_size INTEGER DEFAULT 100
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    task_id UUID,
    title VARCHAR(255),
    message TEXT,
    reminder_type VARCHAR(20),
    delivery_method VARCHAR(20),
    priority VARCHAR(10),
    metadata JSONB,
    scheduled_for TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.user_id,
        r.task_id,
        r.title,
        r.message,
        r.reminder_type,
        r.delivery_method,
        r.priority,
        r.metadata,
        r.scheduled_for
    FROM reminders r
    WHERE r.deleted_at IS NULL
    AND r.status = 'pending'
    AND r.scheduled_for <= check_time
    AND r.retry_count < r.max_retries
    ORDER BY r.priority DESC, r.scheduled_for ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Create function to get snoozed reminders that are ready
CREATE OR REPLACE FUNCTION get_ready_snoozed_reminders(
    check_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    batch_size INTEGER DEFAULT 100
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    task_id UUID,
    title VARCHAR(255),
    message TEXT,
    reminder_type VARCHAR(20),
    delivery_method VARCHAR(20),
    priority VARCHAR(10),
    metadata JSONB,
    snoozed_until TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.user_id,
        r.task_id,
        r.title,
        r.message,
        r.reminder_type,
        r.delivery_method,
        r.priority,
        r.metadata,
        r.snoozed_until
    FROM reminders r
    WHERE r.deleted_at IS NULL
    AND r.status = 'snoozed'
    AND r.snoozed_until <= check_time
    ORDER BY r.priority DESC, r.snoozed_until ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Create function to mark reminder as sent
CREATE OR REPLACE FUNCTION mark_reminder_sent(
    reminder_id UUID,
    sent_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE reminders
    SET
        status = 'sent',
        sent_at = sent_timestamp,
        updated_at = NOW()
    WHERE id = reminder_id
    AND status IN ('pending', 'snoozed');

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- Create function to mark reminder as failed and increment retry
CREATE OR REPLACE FUNCTION mark_reminder_failed(
    reminder_id UUID,
    failure_reason_text TEXT,
    retry_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
    current_retries INTEGER;
    max_retry_limit INTEGER;
BEGIN
    -- Get current retry info
    SELECT retry_count, max_retries INTO current_retries, max_retry_limit
    FROM reminders
    WHERE id = reminder_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Update reminder with failure info
    UPDATE reminders
    SET
        retry_count = retry_count + 1,
        last_retry_at = retry_timestamp,
        failure_reason = failure_reason_text,
        status = CASE
            WHEN retry_count + 1 >= max_retries THEN 'failed'
            ELSE 'pending'
        END,
        updated_at = NOW()
    WHERE id = reminder_id;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- Create function to snooze reminder
CREATE OR REPLACE FUNCTION snooze_reminder(
    reminder_id UUID,
    snooze_until TIMESTAMP WITH TIME ZONE
)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE reminders
    SET
        status = 'snoozed',
        snoozed_until = snooze_until,
        updated_at = NOW()
    WHERE id = reminder_id
    AND status IN ('pending', 'sent');

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- Create function to dismiss reminder
CREATE OR REPLACE FUNCTION dismiss_reminder(
    reminder_id UUID,
    dismiss_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE reminders
    SET
        status = 'dismissed',
        dismissed_at = dismiss_timestamp,
        updated_at = NOW()
    WHERE id = reminder_id
    AND status IN ('pending', 'sent', 'snoozed');

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows > 0;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE reminders IS 'Scheduled reminders for tasks and other events';
COMMENT ON COLUMN reminders.reminder_type IS 'Type of reminder determining when and why it triggers';
COMMENT ON COLUMN reminders.status IS 'Current status of the reminder in its lifecycle';
COMMENT ON COLUMN reminders.scheduled_for IS 'When the reminder should be triggered';
COMMENT ON COLUMN reminders.delivery_method IS 'How the reminder should be delivered to the user';
COMMENT ON COLUMN reminders.is_recurring IS 'Whether this reminder repeats according to a rule';
COMMENT ON COLUMN reminders.next_occurrence IS 'Next scheduled time for recurring reminders';
COMMENT ON COLUMN reminders.metadata IS 'Additional data for reminder customization';
COMMENT ON COLUMN reminders.retry_count IS 'Number of delivery attempts made';
COMMENT ON COLUMN reminders.max_retries IS 'Maximum number of delivery attempts allowed';
COMMENT ON COLUMN reminders.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN reminders.device_id IS 'ID of device that last modified this reminder';
COMMENT ON FUNCTION get_due_reminders IS 'Get reminders that are due for delivery';
COMMENT ON FUNCTION get_ready_snoozed_reminders IS 'Get snoozed reminders that are ready to be reactivated';
COMMENT ON FUNCTION mark_reminder_sent IS 'Mark a reminder as successfully sent';
COMMENT ON FUNCTION mark_reminder_failed IS 'Mark a reminder as failed and increment retry count';
COMMENT ON FUNCTION snooze_reminder IS 'Snooze a reminder until a specified time';
COMMENT ON FUNCTION dismiss_reminder IS 'Dismiss a reminder permanently';