package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"pomodoro-backend/database"
	"pomodoro-backend/models"
)

type SessionRepository struct {
	db *sql.DB
}

func NewSessionRepository() *SessionRepository {
	return &SessionRepository{db: database.DB}
}

// CreateSession creates a new pomodoro session
func (r *SessionRepository) CreateSession(userID string, req models.StartSessionRequest) (*models.PomodoroSession, error) {
	query := `
		INSERT INTO pomodoro_sessions (user_id, task_id, type, duration, remaining_time)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, started_at, created_at, updated_at
	`

	var session models.PomodoroSession
	session.UserID = userID
	session.TaskID = req.TaskID
	session.Type = req.Type
	session.Duration = req.Duration
	session.RemainingTime = req.Duration
	session.Status = "active"

	err := r.db.QueryRow(query, userID, req.TaskID, req.Type, req.Duration, req.Duration).Scan(
		&session.ID, &session.StartedAt, &session.CreatedAt, &session.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	return &session, nil
}

// GetSession retrieves a session by ID
func (r *SessionRepository) GetSession(sessionID, userID string) (*models.PomodoroSession, error) {
	query := `
		SELECT id, user_id, task_id, type, duration, started_at, completed_at, status, remaining_time, created_at, updated_at
		FROM pomodoro_sessions
		WHERE id = $1 AND user_id = $2
	`

	var session models.PomodoroSession
	err := r.db.QueryRow(query, sessionID, userID).Scan(
		&session.ID, &session.UserID, &session.TaskID, &session.Type,
		&session.Duration, &session.StartedAt, &session.CompletedAt,
		&session.Status, &session.RemainingTime, &session.CreatedAt, &session.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("session not found")
		}
		return nil, fmt.Errorf("failed to query session: %w", err)
	}

	return &session, nil
}

// UpdateSession updates a session
func (r *SessionRepository) UpdateSession(sessionID, userID string, req models.UpdateSessionRequest) (*models.PomodoroSession, error) {
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++

		// If status is completed, set completed_at
		if *req.Status == "completed" {
			setParts = append(setParts, fmt.Sprintf("completed_at = $%d", argIndex))
			args = append(args, time.Now())
			argIndex++
		}
	}

	if req.RemainingTime != nil {
		setParts = append(setParts, fmt.Sprintf("remaining_time = $%d", argIndex))
		args = append(args, *req.RemainingTime)
		argIndex++
	}

	if len(setParts) == 0 {
		return r.GetSession(sessionID, userID)
	}

	query := fmt.Sprintf(`
		UPDATE pomodoro_sessions
		SET %s
		WHERE id = $%d AND user_id = $%d
	`, joinStrings(setParts, ", "), argIndex, argIndex+1)

	args = append(args, sessionID, userID)

	_, err := r.db.Exec(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update session: %w", err)
	}

	return r.GetSession(sessionID, userID)
}

// GetActiveSessions retrieves all active sessions for a user
func (r *SessionRepository) GetActiveSessions(userID string) ([]models.PomodoroSession, error) {
	query := `
		SELECT id, user_id, task_id, type, duration, started_at, completed_at, status, remaining_time, created_at, updated_at
		FROM pomodoro_sessions
		WHERE user_id = $1 AND status IN ('active', 'paused')
		ORDER BY started_at DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query active sessions: %w", err)
	}
	defer rows.Close()

	var sessions []models.PomodoroSession
	for rows.Next() {
		var session models.PomodoroSession
		err := rows.Scan(
			&session.ID, &session.UserID, &session.TaskID, &session.Type,
			&session.Duration, &session.StartedAt, &session.CompletedAt,
			&session.Status, &session.RemainingTime, &session.CreatedAt, &session.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan session: %w", err)
		}
		sessions = append(sessions, session)
	}

	return sessions, nil
}

// GetCompletedSessionsCount returns the count of completed sessions for a specific date
func (r *SessionRepository) GetCompletedSessionsCount(userID string, date time.Time) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND DATE(completed_at) = DATE($2)
	`

	var count int
	err := r.db.QueryRow(query, userID, date).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count completed sessions: %w", err)
	}

	return count, nil
}

// GetFocusTime returns the total focus time for a specific date
func (r *SessionRepository) GetFocusTime(userID string, date time.Time) (int, error) {
	query := `
		SELECT COALESCE(SUM(duration / 60), 0)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND DATE(completed_at) = DATE($2)
	`

	var focusTime int
	err := r.db.QueryRow(query, userID, date).Scan(&focusTime)
	if err != nil {
		return 0, fmt.Errorf("failed to calculate focus time: %w", err)
	}

	return focusTime, nil
}

// GetWeeklyStats returns weekly statistics
func (r *SessionRepository) GetWeeklyStats(userID string, startDate time.Time) (*models.WeeklyStatsResponse, error) {
	endDate := startDate.AddDate(0, 0, 7)

	// Get completed sessions
	sessionsQuery := `
		SELECT COUNT(*)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND completed_at >= $2 AND completed_at < $3
	`

	var sessions int
	err := r.db.QueryRow(sessionsQuery, userID, startDate, endDate).Scan(&sessions)
	if err != nil {
		return nil, fmt.Errorf("failed to count weekly sessions: %w", err)
	}

	// Get focus time
	focusQuery := `
		SELECT COALESCE(SUM(duration / 60), 0)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND completed_at >= $2 AND completed_at < $3
	`

	var focusTime int
	err = r.db.QueryRow(focusQuery, userID, startDate, endDate).Scan(&focusTime)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate weekly focus time: %w", err)
	}

	// Get completed tasks (from task repository would be better, but for now...)
	tasksQuery := `
		SELECT COUNT(*)
		FROM tasks
		WHERE user_id = $1
		AND status = 'completed'
		AND updated_at >= $2 AND updated_at < $3
	`

	var tasks int
	err = r.db.QueryRow(tasksQuery, userID, startDate, endDate).Scan(&tasks)
	if err != nil {
		return nil, fmt.Errorf("failed to count weekly completed tasks: %w", err)
	}

	return &models.WeeklyStatsResponse{
		SessionsCompleted: sessions,
		FocusTime:         focusTime,
		TasksCompleted:    tasks,
	}, nil
}

// DeleteSession deletes a session (stops it)
func (r *SessionRepository) DeleteSession(sessionID, userID string) error {
	// First update to cancelled status, then delete if needed
	query := `
		UPDATE pomodoro_sessions
		SET status = 'cancelled', completed_at = NOW()
		WHERE id = $1 AND user_id = $2
	`

	result, err := r.db.Exec(query, sessionID, userID)
	if err != nil {
		return fmt.Errorf("failed to cancel session: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check cancelled rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("session not found")
	}

	return nil
}

// GetSessionHistory retrieves session history for a user
func (r *SessionRepository) GetSessionHistory(userID string, limit int) ([]models.PomodoroSession, error) {
	query := `
		SELECT id, user_id, task_id, type, duration, started_at, completed_at, status, remaining_time, created_at, updated_at
		FROM pomodoro_sessions
		WHERE user_id = $1
		ORDER BY started_at DESC
		LIMIT $2
	`

	rows, err := r.db.Query(query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query session history: %w", err)
	}
	defer rows.Close()

	var sessions []models.PomodoroSession
	for rows.Next() {
		var session models.PomodoroSession
		err := rows.Scan(
			&session.ID, &session.UserID, &session.TaskID, &session.Type,
			&session.Duration, &session.StartedAt, &session.CompletedAt,
			&session.Status, &session.RemainingTime, &session.CreatedAt, &session.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan session: %w", err)
		}
		sessions = append(sessions, session)
	}

	return sessions, nil
}