-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    report_type VARCHAR(30) NOT NULL DEFAULT 'productivity' CHECK (
        report_type IN ('productivity', 'time_tracking', 'task_completion', 'pomodoro_stats', 'weekly_summary', 'monthly_summary', 'custom')
    ),
    period_type VARCHAR(20) NOT NULL DEFAULT 'custom' CHECK (
        period_type IN ('day', 'week', 'month', 'quarter', 'year', 'custom')
    ),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'generated' CHECK (status IN ('generating', 'generated', 'failed', 'archived')),
    data JSONB NOT NULL DEFAULT '{}'::JSONB,
    metadata JSONB DEFAULT '{}'::JSONB,
    metrics JSONB DEFAULT '{}'::JSONB,
    charts_config JSONB DEFAULT '{}'::JSONB,
    filters JSONB DEFAULT '{}'::JSONB,
    format VARCHAR(10) DEFAULT 'json' CHECK (format IN ('json', 'pdf', 'csv', 'xlsx')),
    file_path TEXT,
    file_size_bytes BIGINT CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0),
    generation_time_ms INTEGER CHECK (generation_time_ms IS NULL OR generation_time_ms >= 0),
    is_scheduled BOOLEAN DEFAULT FALSE,
    schedule_config JSONB,
    last_generated_at TIMESTAMP WITH TIME ZONE,
    next_generation_at TIMESTAMP WITH TIME ZONE,
    generation_count INTEGER DEFAULT 1 CHECK (generation_count >= 0),
    is_shared BOOLEAN DEFAULT FALSE,
    share_token VARCHAR(255),
    share_expires_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Constraints
    CONSTRAINT valid_date_range CHECK (start_date <= end_date),
    CONSTRAINT valid_share_token CHECK (
        (is_shared = FALSE AND share_token IS NULL AND share_expires_at IS NULL) OR
        (is_shared = TRUE AND share_token IS NOT NULL)
    )
);

-- Create indexes for reports table
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_report_type ON reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_period_type ON reports(period_type);
CREATE INDEX IF NOT EXISTS idx_reports_start_date ON reports(start_date);
CREATE INDEX IF NOT EXISTS idx_reports_end_date ON reports(end_date);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_format ON reports(format);
CREATE INDEX IF NOT EXISTS idx_reports_is_scheduled ON reports(is_scheduled);
CREATE INDEX IF NOT EXISTS idx_reports_last_generated_at ON reports(last_generated_at);
CREATE INDEX IF NOT EXISTS idx_reports_next_generation_at ON reports(next_generation_at);
CREATE INDEX IF NOT EXISTS idx_reports_is_shared ON reports(is_shared);
CREATE INDEX IF NOT EXISTS idx_reports_share_token ON reports(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_share_expires_at ON reports(share_expires_at) WHERE share_expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at);
CREATE INDEX IF NOT EXISTS idx_reports_updated_at ON reports(updated_at);
CREATE INDEX IF NOT EXISTS idx_reports_deleted_at ON reports(deleted_at);
CREATE INDEX IF NOT EXISTS idx_reports_sync_version ON reports(sync_version);
CREATE INDEX IF NOT EXISTS idx_reports_device_id ON reports(device_id);
CREATE INDEX IF NOT EXISTS idx_reports_last_synced_at ON reports(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reports_user_type_period ON reports(user_id, report_type, period_type);
CREATE INDEX IF NOT EXISTS idx_reports_user_status ON reports(user_id, status);
CREATE INDEX IF NOT EXISTS idx_reports_user_date_range ON reports(user_id, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_reports_scheduled_next ON reports(is_scheduled, next_generation_at) WHERE is_scheduled = TRUE;
CREATE INDEX IF NOT EXISTS idx_reports_shared_active ON reports(is_shared, share_expires_at) WHERE is_shared = TRUE;

-- Create JSONB indexes for querying report data
CREATE INDEX IF NOT EXISTS idx_reports_data_gin ON reports USING GIN(data);
CREATE INDEX IF NOT EXISTS idx_reports_metadata_gin ON reports USING GIN(metadata);
CREATE INDEX IF NOT EXISTS idx_reports_metrics_gin ON reports USING GIN(metrics);
CREATE INDEX IF NOT EXISTS idx_reports_filters_gin ON reports USING GIN(filters);

-- Create trigger for reports table
CREATE TRIGGER update_reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to generate productivity report data
CREATE OR REPLACE FUNCTION generate_productivity_report_data(
    report_user_id UUID,
    report_start_date DATE,
    report_end_date DATE
)
RETURNS JSONB AS $$
DECLARE
    result JSONB := '{}'::JSONB;
    total_tasks INTEGER;
    completed_tasks INTEGER;
    total_pomodoros INTEGER;
    total_work_time_minutes INTEGER;
    avg_session_rating DECIMAL(3,2);
    daily_stats JSONB;
    task_stats JSONB;
    productivity_trends JSONB;
BEGIN
    -- Get basic task statistics
    SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'completed') as completed
    INTO total_tasks, completed_tasks
    FROM tasks
    WHERE user_id = report_user_id
    AND DATE(created_at) BETWEEN report_start_date AND report_end_date
    AND deleted_at IS NULL;

    -- Get pomodoro statistics
    SELECT
        COUNT(*) as total_sessions,
        SUM(duration_minutes) as total_minutes,
        AVG((productivity_rating + focus_rating) / 2.0) as avg_rating
    INTO total_pomodoros, total_work_time_minutes, avg_session_rating
    FROM pomodoro_sessions
    WHERE user_id = report_user_id
    AND type = 'work'
    AND status = 'completed'
    AND DATE(completed_at) BETWEEN report_start_date AND report_end_date
    AND deleted_at IS NULL;

    -- Build daily statistics
    SELECT jsonb_agg(
        jsonb_build_object(
            'date', daily_date,
            'tasks_created', tasks_created,
            'tasks_completed', tasks_completed,
            'pomodoros_completed', pomodoros_completed,
            'work_time_minutes', work_time_minutes,
            'productivity_score', productivity_score
        )
    ) INTO daily_stats
    FROM (
        SELECT
            DATE(d.date) as daily_date,
            COALESCE(t.tasks_created, 0) as tasks_created,
            COALESCE(t.tasks_completed, 0) as tasks_completed,
            COALESCE(p.pomodoros_completed, 0) as pomodoros_completed,
            COALESCE(p.work_time_minutes, 0) as work_time_minutes,
            COALESCE(p.avg_productivity, 0) as productivity_score
        FROM generate_series(
            report_start_date::timestamp,
            report_end_date::timestamp,
            '1 day'::interval
        ) d(date)
        LEFT JOIN (
            SELECT
                DATE(created_at) as task_date,
                COUNT(*) as tasks_created,
                COUNT(*) FILTER (WHERE status = 'completed') as tasks_completed
            FROM tasks
            WHERE user_id = report_user_id
            AND DATE(created_at) BETWEEN report_start_date AND report_end_date
            AND deleted_at IS NULL
            GROUP BY DATE(created_at)
        ) t ON t.task_date = DATE(d.date)
        LEFT JOIN (
            SELECT
                DATE(completed_at) as session_date,
                COUNT(*) as pomodoros_completed,
                SUM(duration_minutes) as work_time_minutes,
                AVG((productivity_rating + focus_rating) / 2.0) as avg_productivity
            FROM pomodoro_sessions
            WHERE user_id = report_user_id
            AND type = 'work'
            AND status = 'completed'
            AND DATE(completed_at) BETWEEN report_start_date AND report_end_date
            AND deleted_at IS NULL
            GROUP BY DATE(completed_at)
        ) p ON p.session_date = DATE(d.date)
        ORDER BY daily_date
    ) daily_data;

    -- Build task statistics by priority and status
    SELECT jsonb_build_object(
        'by_priority', jsonb_object_agg(priority, task_count),
        'by_status', jsonb_object_agg(status, status_count)
    ) INTO task_stats
    FROM (
        SELECT priority, COUNT(*) as task_count
        FROM tasks
        WHERE user_id = report_user_id
        AND DATE(created_at) BETWEEN report_start_date AND report_end_date
        AND deleted_at IS NULL
        GROUP BY priority
    ) priority_stats,
    (
        SELECT status, COUNT(*) as status_count
        FROM tasks
        WHERE user_id = report_user_id
        AND DATE(created_at) BETWEEN report_start_date AND report_end_date
        AND deleted_at IS NULL
        GROUP BY status
    ) status_stats;

    -- Build result
    result := jsonb_build_object(
        'summary', jsonb_build_object(
            'total_tasks', COALESCE(total_tasks, 0),
            'completed_tasks', COALESCE(completed_tasks, 0),
            'completion_rate', CASE
                WHEN total_tasks > 0 THEN ROUND((completed_tasks::DECIMAL / total_tasks::DECIMAL) * 100, 2)
                ELSE 0
            END,
            'total_pomodoros', COALESCE(total_pomodoros, 0),
            'total_work_time_minutes', COALESCE(total_work_time_minutes, 0),
            'total_work_time_hours', ROUND(COALESCE(total_work_time_minutes, 0) / 60.0, 2),
            'average_session_rating', COALESCE(avg_session_rating, 0),
            'period_days', report_end_date - report_start_date + 1
        ),
        'daily_stats', COALESCE(daily_stats, '[]'::jsonb),
        'task_stats', COALESCE(task_stats, '{}'::jsonb),
        'generated_at', to_jsonb(NOW())
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create function to get scheduled reports that need generation
CREATE OR REPLACE FUNCTION get_reports_due_for_generation(
    check_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    batch_size INTEGER DEFAULT 50
)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    title VARCHAR(255),
    report_type VARCHAR(30),
    period_type VARCHAR(20),
    schedule_config JSONB,
    next_generation_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.user_id,
        r.title,
        r.report_type,
        r.period_type,
        r.schedule_config,
        r.next_generation_at
    FROM reports r
    WHERE r.deleted_at IS NULL
    AND r.is_scheduled = TRUE
    AND r.status != 'generating'
    AND r.next_generation_at <= check_time
    ORDER BY r.next_generation_at ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Create function to cleanup expired shared reports
CREATE OR REPLACE FUNCTION cleanup_expired_shared_reports()
RETURNS INTEGER AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    UPDATE reports
    SET
        is_shared = FALSE,
        share_token = NULL,
        share_expires_at = NULL,
        updated_at = NOW()
    WHERE is_shared = TRUE
    AND share_expires_at IS NOT NULL
    AND share_expires_at < NOW();

    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RETURN cleaned_count;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE reports IS 'Generated analytics reports with scheduling and sharing capabilities';
COMMENT ON COLUMN reports.report_type IS 'Type of report determining what data is included';
COMMENT ON COLUMN reports.period_type IS 'Time period covered by the report';
COMMENT ON COLUMN reports.data IS 'Main report data in JSON format';
COMMENT ON COLUMN reports.metadata IS 'Additional metadata about report generation';
COMMENT ON COLUMN reports.metrics IS 'Key metrics and KPIs calculated for the report';
COMMENT ON COLUMN reports.charts_config IS 'Configuration for chart rendering';
COMMENT ON COLUMN reports.filters IS 'Filters applied during report generation';
COMMENT ON COLUMN reports.file_path IS 'Path to generated file (PDF, CSV, etc.)';
COMMENT ON COLUMN reports.is_scheduled IS 'Whether this report is automatically generated on a schedule';
COMMENT ON COLUMN reports.schedule_config IS 'Configuration for scheduled report generation';
COMMENT ON COLUMN reports.is_shared IS 'Whether this report is shared via public link';
COMMENT ON COLUMN reports.share_token IS 'Unique token for shared report access';
COMMENT ON COLUMN reports.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN reports.device_id IS 'ID of device that last modified this report';
COMMENT ON FUNCTION generate_productivity_report_data IS 'Generate productivity report data for specified date range';
COMMENT ON FUNCTION get_reports_due_for_generation IS 'Get scheduled reports that need to be generated';
COMMENT ON FUNCTION cleanup_expired_shared_reports IS 'Remove sharing configuration from expired shared reports';