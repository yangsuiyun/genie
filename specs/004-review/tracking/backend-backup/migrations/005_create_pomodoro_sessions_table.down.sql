-- Drop pomodoro sessions table and related objects
DROP TRIGGER IF EXISTS validate_session_state_transition_trigger ON pomodoro_sessions;
DROP TRIGGER IF EXISTS update_task_actual_pomodoros_trigger ON pomodoro_sessions;
DROP TRIGGER IF EXISTS update_pomodoro_sessions_updated_at ON pomodoro_sessions;
DROP FUNCTION IF EXISTS validate_session_state_transition();
DROP FUNCTION IF EXISTS update_task_actual_pomodoros();
DROP TABLE IF EXISTS pomodoro_sessions CASCADE;