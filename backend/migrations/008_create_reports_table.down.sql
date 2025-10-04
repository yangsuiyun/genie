-- Drop reports table and related objects
DROP FUNCTION IF EXISTS cleanup_expired_shared_reports();
DROP FUNCTION IF EXISTS get_reports_due_for_generation(TIMESTAMP WITH TIME ZONE, INTEGER);
DROP FUNCTION IF EXISTS generate_productivity_report_data(UUID, DATE, DATE);
DROP TRIGGER IF EXISTS update_reports_updated_at ON reports;
DROP TABLE IF EXISTS reports CASCADE;