-- Database Query Optimization and Additional Indexes
-- This file contains additional indexes and optimizations beyond the basic table indexes

-- ============================================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- ============================================================================

-- User Performance Indexes
-- -------------------------

-- Index for user email lookups (login, registration)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_lower ON users(LOWER(email));

-- Index for user verification and reset token lookups
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_tokens_active ON users(verification_token, reset_token)
WHERE verification_token IS NOT NULL OR reset_token IS NOT NULL;

-- Index for active users (not deleted)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_active ON users(id, created_at)
WHERE deleted_at IS NULL;

-- Task Performance Indexes
-- -------------------------

-- Composite index for user's active tasks with priority ordering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_user_active_priority ON tasks(user_id, status, priority, due_date)
WHERE deleted_at IS NULL AND status != 'completed';

-- Index for overdue tasks
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_overdue ON tasks(user_id, due_date, status)
WHERE deleted_at IS NULL AND due_date < NOW() AND status NOT IN ('completed', 'cancelled');

-- Index for tasks requiring sync
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_sync_pending ON tasks(user_id, sync_version, last_synced_at)
WHERE deleted_at IS NULL AND (last_synced_at IS NULL OR last_synced_at < updated_at);

-- Index for recurring task management
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_recurring_due ON tasks(is_recurring, next_occurrence)
WHERE deleted_at IS NULL AND is_recurring = TRUE AND next_occurrence <= NOW();

-- Index for task completion analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_completion_analytics ON tasks(user_id, status, completed_at, created_at)
WHERE deleted_at IS NULL;

-- Index for task search by title and description
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tasks_search_text ON tasks USING GIN(
    setweight(to_tsvector('english', title), 'A') ||
    setweight(to_tsvector('english', COALESCE(description, '')), 'B')
) WHERE deleted_at IS NULL;

-- Subtask Performance Indexes
-- ----------------------------

-- Index for subtask ordering within tasks
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subtasks_task_completion ON subtasks(task_id, status, order_index)
WHERE deleted_at IS NULL;

-- Index for subtask sync status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subtasks_sync_pending ON subtasks(task_id, sync_version, last_synced_at)
WHERE deleted_at IS NULL AND (last_synced_at IS NULL OR last_synced_at < updated_at);

-- Pomodoro Session Performance Indexes
-- -------------------------------------

-- Index for active session lookup (user can only have one active session)
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_pomodoro_sessions_user_active ON pomodoro_sessions(user_id)
WHERE deleted_at IS NULL AND status IN ('active', 'paused');

-- Index for session analytics and reporting
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pomodoro_sessions_analytics ON pomodoro_sessions(
    user_id, type, status, DATE(completed_at), productivity_rating, focus_rating
) WHERE deleted_at IS NULL AND completed_at IS NOT NULL;

-- Index for task-specific session tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pomodoro_sessions_task_tracking ON pomodoro_sessions(
    task_id, status, completed_at
) WHERE deleted_at IS NULL AND task_id IS NOT NULL;

-- Index for daily session summaries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pomodoro_sessions_daily ON pomodoro_sessions(
    user_id, DATE(started_at), type
) WHERE deleted_at IS NULL AND started_at IS NOT NULL;

-- Index for session sync status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pomodoro_sessions_sync_pending ON pomodoro_sessions(
    user_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND (last_synced_at IS NULL OR last_synced_at < updated_at);

-- Notes Performance Indexes
-- --------------------------

-- Index for note search with ranking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notes_search_ranked ON notes USING GIN(
    setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
    setweight(to_tsvector('english', content), 'B')
) WHERE deleted_at IS NULL AND is_archived = FALSE;

-- Index for user's pinned notes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notes_user_pinned_active ON notes(user_id, updated_at DESC)
WHERE deleted_at IS NULL AND is_pinned = TRUE AND is_archived = FALSE;

-- Index for notes by task and session
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notes_entity_references ON notes(task_id, session_id, created_at DESC)
WHERE deleted_at IS NULL AND (task_id IS NOT NULL OR session_id IS NOT NULL);

-- Index for note sync status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notes_sync_pending ON notes(
    user_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND (last_synced_at IS NULL OR last_synced_at < updated_at);

-- Reminders Performance Indexes
-- ------------------------------

-- Index for reminder processing queue
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reminders_processing_queue ON reminders(
    status, scheduled_for, priority DESC, retry_count
) WHERE deleted_at IS NULL AND status = 'pending' AND retry_count < max_retries;

-- Index for snoozed reminders ready for reactivation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reminders_snooze_ready ON reminders(
    snoozed_until, user_id
) WHERE deleted_at IS NULL AND status = 'snoozed';

-- Index for user's upcoming reminders
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reminders_user_upcoming ON reminders(
    user_id, scheduled_for, status
) WHERE deleted_at IS NULL AND status IN ('pending', 'snoozed');

-- Index for reminder analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reminders_analytics ON reminders(
    user_id, reminder_type, delivery_method, DATE(created_at)
) WHERE deleted_at IS NULL;

-- Reports Performance Indexes
-- ----------------------------

-- Index for user's recent reports
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reports_user_recent ON reports(
    user_id, report_type, created_at DESC
) WHERE deleted_at IS NULL;

-- Index for scheduled report generation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reports_scheduled_generation ON reports(
    is_scheduled, next_generation_at, status
) WHERE deleted_at IS NULL AND is_scheduled = TRUE AND status != 'generating';

-- Index for shared reports access
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reports_shared_access ON reports(
    share_token, share_expires_at
) WHERE deleted_at IS NULL AND is_shared = TRUE AND share_token IS NOT NULL;

-- Index for report data queries (JSONB optimization)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reports_data_metrics ON reports USING GIN(
    (data -> 'summary'), (metrics)
) WHERE deleted_at IS NULL;

-- ============================================================================
-- CROSS-TABLE PERFORMANCE INDEXES
-- ============================================================================

-- User Activity Timeline Index
-- Combines multiple tables for activity feeds
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_activity_timeline ON (
    SELECT user_id, 'task' as type, created_at, updated_at
    FROM tasks WHERE deleted_at IS NULL
    UNION ALL
    SELECT user_id, 'session' as type, created_at, updated_at
    FROM pomodoro_sessions WHERE deleted_at IS NULL
    UNION ALL
    SELECT user_id, 'note' as type, created_at, updated_at
    FROM notes WHERE deleted_at IS NULL
);

-- ============================================================================
-- SYNC OPTIMIZATION INDEXES
-- ============================================================================

-- Cross-table sync status for conflict resolution
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sync_conflicts_tasks ON tasks(
    user_id, device_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND device_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sync_conflicts_subtasks ON subtasks(
    device_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND device_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sync_conflicts_sessions ON pomodoro_sessions(
    user_id, device_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND device_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sync_conflicts_notes ON notes(
    user_id, device_id, sync_version, last_synced_at
) WHERE deleted_at IS NULL AND device_id IS NOT NULL;

-- ============================================================================
-- ANALYTICAL INDEXES FOR REPORTING
-- ============================================================================

-- Productivity Analytics Indexes
-- -------------------------------

-- Daily productivity metrics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_daily_productivity ON (
    SELECT
        user_id,
        DATE(created_at) as date,
        'task_created' as metric_type,
        1 as value
    FROM tasks WHERE deleted_at IS NULL
    UNION ALL
    SELECT
        user_id,
        DATE(completed_at) as date,
        'task_completed' as metric_type,
        1 as value
    FROM tasks WHERE deleted_at IS NULL AND completed_at IS NOT NULL
    UNION ALL
    SELECT
        user_id,
        DATE(completed_at) as date,
        'pomodoro_completed' as metric_type,
        duration_minutes as value
    FROM pomodoro_sessions
    WHERE deleted_at IS NULL AND status = 'completed' AND type = 'work'
);

-- Weekly/Monthly aggregation indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_weekly_aggregation ON (
    SELECT
        user_id,
        date_trunc('week', created_at) as week,
        date_trunc('month', created_at) as month,
        COUNT(*) as task_count
    FROM tasks
    WHERE deleted_at IS NULL
    GROUP BY user_id, date_trunc('week', created_at), date_trunc('month', created_at)
);

-- ============================================================================
-- CONSTRAINT INDEXES FOR DATA INTEGRITY
-- ============================================================================

-- Ensure unique active sessions per user
-- (This is already created above as idx_pomodoro_sessions_user_active)

-- Ensure unique share tokens for reports
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_reports_share_token_unique ON reports(share_token)
WHERE deleted_at IS NULL AND share_token IS NOT NULL;

-- Ensure unique order indexes for subtasks within a task
-- (This is already created in the subtasks migration)

-- ============================================================================
-- CLEANUP AND MAINTENANCE INDEXES
-- ============================================================================

-- Index for cleanup operations (finding old deleted records)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cleanup_deleted_records ON (
    SELECT 'tasks' as table_name, id, deleted_at FROM tasks WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'subtasks' as table_name, id, deleted_at FROM subtasks WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'pomodoro_sessions' as table_name, id, deleted_at FROM pomodoro_sessions WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'notes' as table_name, id, deleted_at FROM notes WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'reminders' as table_name, id, deleted_at FROM reminders WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'reports' as table_name, id, deleted_at FROM reports WHERE deleted_at IS NOT NULL
);

-- Index for token cleanup (expired verification and reset tokens)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cleanup_expired_tokens ON users(
    verification_token_expires_at, reset_token_expires_at
) WHERE verification_token_expires_at < NOW() OR reset_token_expires_at < NOW();

-- Index for shared report cleanup
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cleanup_expired_shares ON reports(
    share_expires_at
) WHERE is_shared = TRUE AND share_expires_at < NOW();

-- ============================================================================
-- STATISTICS UPDATE COMMANDS
-- ============================================================================

-- Update table statistics for better query planning
ANALYZE users;
ANALYZE tasks;
ANALYZE subtasks;
ANALYZE pomodoro_sessions;
ANALYZE notes;
ANALYZE reminders;
ANALYZE reports;
ANALYZE recurrence_rules;

-- ============================================================================
-- QUERY OPTIMIZATION HINTS
-- ============================================================================

-- Create extension for advanced indexing if not exists
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- For similarity search
CREATE EXTENSION IF NOT EXISTS btree_gin; -- For composite GIN indexes

-- Enable query plan analysis
SET log_statement = 'none';
SET log_min_duration_statement = 1000; -- Log slow queries (>1 second)

-- ============================================================================
-- MATERIALIZED VIEWS FOR COMPLEX ANALYTICS
-- ============================================================================

-- Daily user statistics materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_user_stats AS
SELECT
    u.id as user_id,
    DATE(d.date) as stat_date,
    COALESCE(t.tasks_created, 0) as tasks_created,
    COALESCE(t.tasks_completed, 0) as tasks_completed,
    COALESCE(p.pomodoros_completed, 0) as pomodoros_completed,
    COALESCE(p.total_work_minutes, 0) as total_work_minutes,
    COALESCE(p.avg_productivity_rating, 0) as avg_productivity_rating,
    COALESCE(n.notes_created, 0) as notes_created
FROM users u
CROSS JOIN generate_series(
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE,
    '1 day'::interval
) d(date)
LEFT JOIN (
    SELECT
        user_id,
        DATE(created_at) as date,
        COUNT(*) as tasks_created,
        COUNT(*) FILTER (WHERE status = 'completed') as tasks_completed
    FROM tasks
    WHERE deleted_at IS NULL
    GROUP BY user_id, DATE(created_at)
) t ON t.user_id = u.id AND t.date = DATE(d.date)
LEFT JOIN (
    SELECT
        user_id,
        DATE(completed_at) as date,
        COUNT(*) as pomodoros_completed,
        SUM(duration_minutes) as total_work_minutes,
        AVG((productivity_rating + focus_rating) / 2.0) as avg_productivity_rating
    FROM pomodoro_sessions
    WHERE deleted_at IS NULL AND status = 'completed' AND type = 'work'
    GROUP BY user_id, DATE(completed_at)
) p ON p.user_id = u.id AND p.date = DATE(d.date)
LEFT JOIN (
    SELECT
        user_id,
        DATE(created_at) as date,
        COUNT(*) as notes_created
    FROM notes
    WHERE deleted_at IS NULL
    GROUP BY user_id, DATE(created_at)
) n ON n.user_id = u.id AND n.date = DATE(d.date)
WHERE u.deleted_at IS NULL;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_daily_user_stats_user_date ON daily_user_stats(user_id, stat_date);

-- Weekly user statistics materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS weekly_user_stats AS
SELECT
    user_id,
    date_trunc('week', stat_date) as week_start,
    SUM(tasks_created) as weekly_tasks_created,
    SUM(tasks_completed) as weekly_tasks_completed,
    SUM(pomodoros_completed) as weekly_pomodoros_completed,
    SUM(total_work_minutes) as weekly_work_minutes,
    AVG(avg_productivity_rating) as weekly_avg_productivity_rating,
    SUM(notes_created) as weekly_notes_created
FROM daily_user_stats
GROUP BY user_id, date_trunc('week', stat_date);

-- Create index on weekly stats
CREATE INDEX IF NOT EXISTS idx_weekly_user_stats_user_week ON weekly_user_stats(user_id, week_start);

-- ============================================================================
-- REFRESH SCHEDULE FOR MATERIALIZED VIEWS
-- ============================================================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_user_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_user_stats;
END;
$$ LANGUAGE plpgsql;

-- Note: In production, you would schedule this function to run periodically
-- using pg_cron or an external scheduler

-- ============================================================================
-- PERFORMANCE MONITORING QUERIES
-- ============================================================================

-- Query to find unused indexes
-- (This is a diagnostic query, not an index creation)
/*
SELECT
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename, indexname;
*/

-- Query to find slow queries
-- (This requires pg_stat_statements extension)
/*
SELECT
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
*/

-- ============================================================================
-- COMMENTS FOR MAINTENANCE
-- ============================================================================

COMMENT ON MATERIALIZED VIEW daily_user_stats IS 'Daily aggregated user activity statistics for reporting and analytics';
COMMENT ON MATERIALIZED VIEW weekly_user_stats IS 'Weekly aggregated user activity statistics for trend analysis';
COMMENT ON FUNCTION refresh_analytics_views IS 'Refreshes all materialized views for analytics - should be scheduled to run daily';