package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"pomodoro-backend/database"
	"pomodoro-backend/models"
)

type AnalyticsRepository struct {
	db *sql.DB
}

func NewAnalyticsRepository() *AnalyticsRepository {
	return &AnalyticsRepository{db: database.DB}
}

// GetAnalytics retrieves analytics data for today and this week
func (r *AnalyticsRepository) GetAnalytics(userID string) (*models.AnalyticsResponse, error) {
	today := time.Now()

	// Get today's stats
	todayStats, err := r.GetDailyStats(userID, today)
	if err != nil {
		return nil, fmt.Errorf("failed to get today's stats: %w", err)
	}

	// Get this week's stats (last 7 days)
	weekStart := today.AddDate(0, 0, -6) // 7 days including today
	weekStats, err := r.GetWeeklyStats(userID, weekStart)
	if err != nil {
		return nil, fmt.Errorf("failed to get week's stats: %w", err)
	}

	return &models.AnalyticsResponse{
		Today:    *todayStats,
		ThisWeek: *weekStats,
	}, nil
}

// GetDailyStats retrieves daily statistics for a specific date
func (r *AnalyticsRepository) GetDailyStats(userID string, date time.Time) (*models.DailyStatsResponse, error) {
	// Get sessions completed
	sessionsQuery := `
		SELECT COUNT(*)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND DATE(completed_at) = DATE($2)
	`

	var sessions int
	err := r.db.QueryRow(sessionsQuery, userID, date).Scan(&sessions)
	if err != nil {
		return nil, fmt.Errorf("failed to count daily sessions: %w", err)
	}

	// Get focus time in minutes
	focusQuery := `
		SELECT COALESCE(SUM(COALESCE(actual_duration, planned_duration) / 60), 0)
		FROM pomodoro_sessions
		WHERE user_id = $1
		AND status = 'completed'
		AND type = 'work'
		AND DATE(completed_at) = DATE($2)
	`

	var focusTime int
	err = r.db.QueryRow(focusQuery, userID, date).Scan(&focusTime)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate daily focus time: %w", err)
	}

	// Get tasks completed
	tasksQuery := `
		SELECT COUNT(*)
		FROM tasks
		WHERE user_id = $1
		AND status = 'completed'
		AND DATE(updated_at) = DATE($2)
	`

	var tasks int
	err = r.db.QueryRow(tasksQuery, userID, date).Scan(&tasks)
	if err != nil {
		return nil, fmt.Errorf("failed to count daily completed tasks: %w", err)
	}

	return &models.DailyStatsResponse{
		SessionsCompleted: sessions,
		FocusTime:         focusTime,
		TasksCompleted:    tasks,
	}, nil
}

// GetWeeklyStats retrieves weekly statistics for a date range
func (r *AnalyticsRepository) GetWeeklyStats(userID string, startDate time.Time) (*models.WeeklyStatsResponse, error) {
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
		SELECT COALESCE(SUM(COALESCE(actual_duration, planned_duration) / 60), 0)
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

	// Get completed tasks
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

// UpdateDailyStats updates or creates daily statistics
func (r *AnalyticsRepository) UpdateDailyStats(userID string, date time.Time) error {
	// Get fresh stats for the date
	stats, err := r.GetDailyStats(userID, date)
	if err != nil {
		return fmt.Errorf("failed to calculate daily stats: %w", err)
	}

	// Insert or update daily stats
	query := `
		INSERT INTO daily_stats (user_id, date, sessions_completed, focus_time, tasks_completed)
		VALUES ($1, DATE($2), $3, $4, $5)
		ON CONFLICT (user_id, date)
		DO UPDATE SET
			sessions_completed = $3,
			focus_time = $4,
			tasks_completed = $5,
			updated_at = NOW()
	`

	_, err = r.db.Exec(query, userID, date, stats.SessionsCompleted, stats.FocusTime, stats.TasksCompleted)
	if err != nil {
		return fmt.Errorf("failed to update daily stats: %w", err)
	}

	return nil
}

// GetDailyStatsHistory retrieves daily statistics for a date range
func (r *AnalyticsRepository) GetDailyStatsHistory(userID string, startDate, endDate time.Time) ([]models.DailyStats, error) {
	query := `
		SELECT user_id, date, sessions_completed, focus_time, tasks_completed, created_at, updated_at
		FROM daily_stats
		WHERE user_id = $1
		AND date >= DATE($2)
		AND date <= DATE($3)
		ORDER BY date DESC
	`

	rows, err := r.db.Query(query, userID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query daily stats history: %w", err)
	}
	defer rows.Close()

	var stats []models.DailyStats
	for rows.Next() {
		var stat models.DailyStats
		err := rows.Scan(
			&stat.UserID, &stat.Date, &stat.SessionsCompleted,
			&stat.FocusTime, &stat.TasksCompleted,
			&stat.CreatedAt, &stat.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan daily stat: %w", err)
		}
		stats = append(stats, stat)
	}

	return stats, nil
}

// GetProductivityTrend calculates productivity trend (simple implementation)
func (r *AnalyticsRepository) GetProductivityTrend(userID string, days int) (string, error) {
	// Get stats for the last N days
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	history, err := r.GetDailyStatsHistory(userID, startDate, endDate)
	if err != nil {
		return "", fmt.Errorf("failed to get productivity history: %w", err)
	}

	if len(history) < 2 {
		return "stable", nil
	}

	// Simple trend calculation: compare first half with second half
	halfPoint := len(history) / 2

	var firstHalfAvg, secondHalfAvg float64

	for i := 0; i < halfPoint; i++ {
		firstHalfAvg += float64(history[i].SessionsCompleted + history[i].TasksCompleted)
	}
	firstHalfAvg /= float64(halfPoint)

	for i := halfPoint; i < len(history); i++ {
		secondHalfAvg += float64(history[i].SessionsCompleted + history[i].TasksCompleted)
	}
	secondHalfAvg /= float64(len(history) - halfPoint)

	diff := secondHalfAvg - firstHalfAvg
	threshold := firstHalfAvg * 0.1 // 10% threshold

	if diff > threshold {
		return "increasing", nil
	} else if diff < -threshold {
		return "decreasing", nil
	}

	return "stable", nil
}

// GetCompletionRate calculates task completion rate
func (r *AnalyticsRepository) GetCompletionRate(userID string, days int) (float64, error) {
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	// Get total tasks created in period
	totalQuery := `
		SELECT COUNT(*)
		FROM tasks
		WHERE user_id = $1
		AND created_at >= $2 AND created_at <= $3
	`

	var total int
	err := r.db.QueryRow(totalQuery, userID, startDate, endDate).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("failed to count total tasks: %w", err)
	}

	if total == 0 {
		return 0, nil
	}

	// Get completed tasks in period
	completedQuery := `
		SELECT COUNT(*)
		FROM tasks
		WHERE user_id = $1
		AND status = 'completed'
		AND created_at >= $2 AND created_at <= $3
	`

	var completed int
	err = r.db.QueryRow(completedQuery, userID, startDate, endDate).Scan(&completed)
	if err != nil {
		return 0, fmt.Errorf("failed to count completed tasks: %w", err)
	}

	return float64(completed) / float64(total) * 100, nil
}

// GenerateReport generates a comprehensive report
func (r *AnalyticsRepository) GenerateReport(userID string, days int) (map[string]interface{}, error) {
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	// Get various metrics
	weeklyStats, err := r.GetWeeklyStats(userID, startDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get weekly stats: %w", err)
	}

	completionRate, err := r.GetCompletionRate(userID, days)
	if err != nil {
		return nil, fmt.Errorf("failed to get completion rate: %w", err)
	}

	trend, err := r.GetProductivityTrend(userID, days)
	if err != nil {
		return nil, fmt.Errorf("failed to get productivity trend: %w", err)
	}

	report := map[string]interface{}{
		"period_days":         days,
		"total_sessions":      weeklyStats.SessionsCompleted,
		"total_focus_time":    weeklyStats.FocusTime,
		"tasks_completed":     weeklyStats.TasksCompleted,
		"completion_rate":     completionRate,
		"productivity_trend":  trend,
		"generated_at":        time.Now(),
	}

	return report, nil
}