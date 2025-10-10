package services

import (
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
)

// ReportRepository defines the interface for report data access
type ReportRepository interface {
	GetUserSessionStats(userID uuid.UUID, startDate, endDate time.Time) (*SessionStatsData, error)
	GetUserTaskStats(userID uuid.UUID, startDate, endDate time.Time) (*TaskStatsData, error)
	GetProductivityTrends(userID uuid.UUID, startDate, endDate time.Time, interval string) ([]*ProductivityDataPoint, error)
	GetTaskProductivity(userID uuid.UUID, startDate, endDate time.Time) ([]*TaskProductivityData, error)
	GetFocusPatterns(userID uuid.UUID, startDate, endDate time.Time) (*FocusPatternData, error)
	StoreGeneratedReport(report *models.Report) error
	GetStoredReport(userID uuid.UUID, reportType string, startDate, endDate time.Time) (*models.Report, error)
}

// ReportService handles analytics and report generation
type ReportService struct {
	repo            ReportRepository
	taskService     *TaskService
	pomodoroService *PomodoroService
	userService     *UserService
}

// ReportRequest represents a request for generating a report
type ReportRequest struct {
	UserID        uuid.UUID    `json:"user_id"`
	ReportType    ReportType   `json:"report_type" validate:"required,oneof=daily weekly monthly quarterly yearly custom"`
	StartDate     *time.Time   `json:"start_date,omitempty"`
	EndDate       *time.Time   `json:"end_date,omitempty"`
	IncludeTasks  bool         `json:"include_tasks"`
	IncludeTrends bool         `json:"include_trends"`
	Format        ReportFormat `json:"format" validate:"oneof=json csv pdf xlsx"`
	Timezone      string       `json:"timezone,omitempty"`
}

// ReportType represents different types of reports
type ReportType string

const (
	ReportTypeDaily     ReportType = "daily"
	ReportTypeWeekly    ReportType = "weekly"
	ReportTypeMonthly   ReportType = "monthly"
	ReportTypeQuarterly ReportType = "quarterly"
	ReportTypeYearly    ReportType = "yearly"
	ReportTypeCustom    ReportType = "custom"
)

// ReportFormat represents different export formats
type ReportFormat string

const (
	ReportFormatJSON ReportFormat = "json"
	ReportFormatCSV  ReportFormat = "csv"
	ReportFormatPDF  ReportFormat = "pdf"
	ReportFormatXLSX ReportFormat = "xlsx"
)

// ProductivityReport represents a comprehensive productivity report
type ProductivityReport struct {
	UserID      uuid.UUID  `json:"user_id"`
	ReportType  ReportType `json:"report_type"`
	StartDate   time.Time  `json:"start_date"`
	EndDate     time.Time  `json:"end_date"`
	GeneratedAt time.Time  `json:"generated_at"`

	// Session Statistics
	TotalSessions        int     `json:"total_sessions"`
	CompletedSessions    int     `json:"completed_sessions"`
	InterruptedSessions  int     `json:"interrupted_sessions"`
	TotalFocusTime       int     `json:"total_focus_time"`       // seconds
	TotalBreakTime       int     `json:"total_break_time"`       // seconds
	AverageSessionLength float64 `json:"average_session_length"` // seconds
	CompletionRate       float64 `json:"completion_rate"`        // percentage
	InterruptionRate     float64 `json:"interruption_rate"`      // percentage

	// Task Statistics
	TasksCreated        int     `json:"tasks_created"`
	TasksCompleted      int     `json:"tasks_completed"`
	TasksOverdue        int     `json:"tasks_overdue"`
	TaskCompletionRate  float64 `json:"task_completion_rate"`  // percentage
	AverageTaskDuration float64 `json:"average_task_duration"` // days

	// Productivity Metrics
	ProductivityScore   float64 `json:"productivity_score"`    // 0-100
	FocusScore          float64 `json:"focus_score"`           // 0-100
	EfficiencyScore     float64 `json:"efficiency_score"`      // 0-100
	GoalAchievementRate float64 `json:"goal_achievement_rate"` // percentage

	// Time Distribution
	WorkSessionTime int `json:"work_session_time"` // seconds
	ShortBreakTime  int `json:"short_break_time"`  // seconds
	LongBreakTime   int `json:"long_break_time"`   // seconds

	// Patterns and Trends
	PeakProductivityHours []int                    `json:"peak_productivity_hours"` // hours of day
	ProductivityTrends    []*ProductivityDataPoint `json:"productivity_trends,omitempty"`
	TaskBreakdown         []*TaskProductivityData  `json:"task_breakdown,omitempty"`
	FocusPatterns         *FocusPatternData        `json:"focus_patterns,omitempty"`

	// Goals and Streaks
	DailyGoalsMet  int `json:"daily_goals_met"`
	WeeklyGoalsMet int `json:"weekly_goals_met"`
	CurrentStreak  int `json:"current_streak"`
	LongestStreak  int `json:"longest_streak"`

	// Comparisons
	PreviousPeriodComparison *PeriodComparison `json:"previous_period_comparison,omitempty"`
}

// SessionStatsData represents session statistics from the database
type SessionStatsData struct {
	TotalSessions       int     `json:"total_sessions"`
	CompletedSessions   int     `json:"completed_sessions"`
	InterruptedSessions int     `json:"interrupted_sessions"`
	TotalWorkTime       int     `json:"total_work_time"`
	TotalBreakTime      int     `json:"total_break_time"`
	AverageLength       float64 `json:"average_length"`
	InterruptionCount   int     `json:"interruption_count"`
}

// TaskStatsData represents task statistics from the database
type TaskStatsData struct {
	TasksCreated      int     `json:"tasks_created"`
	TasksCompleted    int     `json:"tasks_completed"`
	TasksOverdue      int     `json:"tasks_overdue"`
	AverageCompletion float64 `json:"average_completion"` // days
}

// ProductivityDataPoint represents a single data point in productivity trends
type ProductivityDataPoint struct {
	Date              time.Time `json:"date"`
	ProductivityScore float64   `json:"productivity_score"`
	SessionsCompleted int       `json:"sessions_completed"`
	TasksCompleted    int       `json:"tasks_completed"`
	FocusTime         int       `json:"focus_time"`
	InterruptionRate  float64   `json:"interruption_rate"`
}

// TaskProductivityData represents productivity data for a specific task
type TaskProductivityData struct {
	TaskID             uuid.UUID  `json:"task_id"`
	TaskTitle          string     `json:"task_title"`
	SessionsCompleted  int        `json:"sessions_completed"`
	TotalFocusTime     int        `json:"total_focus_time"`
	AverageSessionTime float64    `json:"average_session_time"`
	InterruptionRate   float64    `json:"interruption_rate"`
	CompletionDate     *time.Time `json:"completion_date,omitempty"`
	EstimatedVsActual  *float64   `json:"estimated_vs_actual,omitempty"`
}

// FocusPatternData represents focus patterns analysis
type FocusPatternData struct {
	PeakHours               []int              `json:"peak_hours"`
	ProductivityByHour      map[int]float64    `json:"productivity_by_hour"`
	ProductivityByDayOfWeek map[string]float64 `json:"productivity_by_day_of_week"`
	BestFocusTimeOfDay      string             `json:"best_focus_time_of_day"`
	AverageSessionsByHour   map[int]int        `json:"average_sessions_by_hour"`
}

// PeriodComparison represents comparison with previous period
type PeriodComparison struct {
	SessionsChange         float64 `json:"sessions_change"`          // percentage
	FocusTimeChange        float64 `json:"focus_time_change"`        // percentage
	ProductivityChange     float64 `json:"productivity_change"`      // percentage
	TaskCompletionChange   float64 `json:"task_completion_change"`   // percentage
	InterruptionRateChange float64 `json:"interruption_rate_change"` // percentage
}

// NewReportService creates a new report service
func NewReportService(repo ReportRepository) *ReportService {
	return &ReportService{
		repo: repo,
	}
}

// SetDependencies sets dependent services
func (s *ReportService) SetDependencies(taskService *TaskService, pomodoroService *PomodoroService, userService *UserService) {
	s.taskService = taskService
	s.pomodoroService = pomodoroService
	s.userService = userService
}

// GenerateReport generates a productivity report
func (s *ReportService) GenerateReport(req ReportRequest) (*ProductivityReport, error) {
	// Determine date range based on report type
	startDate, endDate, err := s.calculateDateRange(req)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate date range: %w", err)
	}

	// Check if report already exists (for caching)
	if cachedReport, err := s.repo.GetStoredReport(req.UserID, string(req.ReportType), startDate, endDate); err == nil && cachedReport != nil {
		// Return cached report if it's recent enough (e.g., generated within last hour)
		if time.Since(cachedReport.GeneratedAt) < time.Hour {
			return s.convertStoredReport(cachedReport), nil
		}
	}

	// Get session statistics
	sessionStats, err := s.repo.GetUserSessionStats(req.UserID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get session stats: %w", err)
	}

	// Get task statistics
	taskStats, err := s.repo.GetUserTaskStats(req.UserID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get task stats: %w", err)
	}

	// Get focus patterns
	focusPatterns, err := s.repo.GetFocusPatterns(req.UserID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get focus patterns: %w", err)
	}

	// Create report
	report := &ProductivityReport{
		UserID:      req.UserID,
		ReportType:  req.ReportType,
		StartDate:   startDate,
		EndDate:     endDate,
		GeneratedAt: time.Now(),
	}

	// Fill session data
	s.fillSessionData(report, sessionStats)

	// Fill task data
	s.fillTaskData(report, taskStats)

	// Calculate productivity scores
	s.calculateProductivityScores(report)

	// Fill focus patterns
	report.FocusPatterns = focusPatterns
	report.PeakProductivityHours = focusPatterns.PeakHours

	// Get user goals and calculate achievement
	if s.userService != nil {
		s.calculateGoalAchievement(report, req.UserID)
	}

	// Get streak data
	if s.pomodoroService != nil {
		s.fillStreakData(report, req.UserID)
	}

	// Include optional data if requested
	if req.IncludeTrends {
		trends, err := s.repo.GetProductivityTrends(req.UserID, startDate, endDate, "daily")
		if err == nil {
			report.ProductivityTrends = trends
		}
	}

	if req.IncludeTasks {
		taskBreakdown, err := s.repo.GetTaskProductivity(req.UserID, startDate, endDate)
		if err == nil {
			report.TaskBreakdown = taskBreakdown
		}
	}

	// Calculate previous period comparison
	s.calculatePreviousPeriodComparison(report, req)

	// Store the generated report for caching
	s.storeReport(report)

	return report, nil
}

// GetDashboardStats generates quick dashboard statistics
func (s *ReportService) GetDashboardStats(userID uuid.UUID) (map[string]interface{}, error) {
	now := time.Now()

	// Today's stats
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	todayStats, err := s.repo.GetUserSessionStats(userID, startOfDay, now)
	if err != nil {
		return nil, err
	}

	// This week's stats
	weekday := int(now.Weekday())
	if weekday == 0 { // Sunday
		weekday = 7
	}
	startOfWeek := now.AddDate(0, 0, -(weekday - 1))
	startOfWeek = time.Date(startOfWeek.Year(), startOfWeek.Month(), startOfWeek.Day(), 0, 0, 0, 0, startOfWeek.Location())
	weekStats, err := s.repo.GetUserSessionStats(userID, startOfWeek, now)
	if err != nil {
		return nil, err
	}

	// Get user goals
	var dailyGoal, weeklyGoal int
	if s.userService != nil {
		user, err := s.userService.GetByID(userID.String())
		if err == nil {
			dailyGoal = user.Preferences.WeeklyGoal / 7 // Approximate daily goal
			weeklyGoal = user.Preferences.WeeklyGoal
		}
	}

	return map[string]interface{}{
		"today": map[string]interface{}{
			"sessions_completed": todayStats.CompletedSessions,
			"focus_time":         todayStats.TotalWorkTime,
			"goal_progress":      float64(todayStats.CompletedSessions) / float64(dailyGoal) * 100,
		},
		"week": map[string]interface{}{
			"sessions_completed": weekStats.CompletedSessions,
			"focus_time":         weekStats.TotalWorkTime,
			"goal_progress":      float64(weekStats.CompletedSessions) / float64(weeklyGoal) * 100,
		},
		"goals": map[string]interface{}{
			"daily":  dailyGoal,
			"weekly": weeklyGoal,
		},
	}, nil
}

// GetProductivityTrends gets productivity trends for visualization
func (s *ReportService) GetProductivityTrends(userID uuid.UUID, startDate, endDate time.Time, interval string) ([]*ProductivityDataPoint, error) {
	return s.repo.GetProductivityTrends(userID, startDate, endDate, interval)
}

// ExportReport exports a report in the specified format
func (s *ReportService) ExportReport(report *ProductivityReport, format ReportFormat) ([]byte, string, error) {
	switch format {
	case ReportFormatJSON:
		return s.exportJSON(report)
	case ReportFormatCSV:
		return s.exportCSV(report)
	case ReportFormatPDF:
		return s.exportPDF(report)
	case ReportFormatXLSX:
		return s.exportXLSX(report)
	default:
		return nil, "", fmt.Errorf("unsupported format: %s", format)
	}
}

// Helper methods

// calculateDateRange determines the date range based on report type
func (s *ReportService) calculateDateRange(req ReportRequest) (time.Time, time.Time, error) {
	now := time.Now()

	if req.ReportType == ReportTypeCustom {
		if req.StartDate == nil || req.EndDate == nil {
			return time.Time{}, time.Time{}, fmt.Errorf("custom reports require start and end dates")
		}
		return *req.StartDate, *req.EndDate, nil
	}

	switch req.ReportType {
	case ReportTypeDaily:
		start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		end := start.Add(24 * time.Hour)
		return start, end, nil

	case ReportTypeWeekly:
		weekday := int(now.Weekday())
		if weekday == 0 { // Sunday
			weekday = 7
		}
		start := now.AddDate(0, 0, -(weekday - 1))
		start = time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, start.Location())
		end := start.Add(7 * 24 * time.Hour)
		return start, end, nil

	case ReportTypeMonthly:
		start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		end := start.AddDate(0, 1, 0)
		return start, end, nil

	case ReportTypeQuarterly:
		quarter := int((now.Month()-1)/3) + 1
		startMonth := time.Month((quarter-1)*3 + 1)
		start := time.Date(now.Year(), startMonth, 1, 0, 0, 0, 0, now.Location())
		end := start.AddDate(0, 3, 0)
		return start, end, nil

	case ReportTypeYearly:
		start := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
		end := start.AddDate(1, 0, 0)
		return start, end, nil

	default:
		return time.Time{}, time.Time{}, fmt.Errorf("unsupported report type: %s", req.ReportType)
	}
}

// fillSessionData fills session-related data in the report
func (s *ReportService) fillSessionData(report *ProductivityReport, stats *SessionStatsData) {
	report.TotalSessions = stats.TotalSessions
	report.CompletedSessions = stats.CompletedSessions
	report.InterruptedSessions = stats.InterruptedSessions
	report.TotalFocusTime = stats.TotalWorkTime
	report.TotalBreakTime = stats.TotalBreakTime
	report.AverageSessionLength = stats.AverageLength

	if stats.TotalSessions > 0 {
		report.CompletionRate = float64(stats.CompletedSessions) / float64(stats.TotalSessions) * 100
		report.InterruptionRate = float64(stats.InterruptionCount) / float64(stats.TotalSessions) * 100
	}
}

// fillTaskData fills task-related data in the report
func (s *ReportService) fillTaskData(report *ProductivityReport, stats *TaskStatsData) {
	report.TasksCreated = stats.TasksCreated
	report.TasksCompleted = stats.TasksCompleted
	report.TasksOverdue = stats.TasksOverdue
	report.AverageTaskDuration = stats.AverageCompletion

	if stats.TasksCreated > 0 {
		report.TaskCompletionRate = float64(stats.TasksCompleted) / float64(stats.TasksCreated) * 100
	}
}

// calculateProductivityScores calculates various productivity scores
func (s *ReportService) calculateProductivityScores(report *ProductivityReport) {
	// Focus Score: Based on completion rate and interruption rate
	focusScore := report.CompletionRate * (1 - report.InterruptionRate/100)
	report.FocusScore = math.Max(0, math.Min(100, focusScore))

	// Efficiency Score: Based on actual vs planned session times
	efficiencyScore := 100.0 // Simplified calculation
	if report.AverageSessionLength > 0 {
		// Assume 25 minutes is optimal
		optimal := 1500.0 // 25 minutes in seconds
		efficiency := math.Min(report.AverageSessionLength, optimal) / optimal * 100
		efficiencyScore = efficiency
	}
	report.EfficiencyScore = efficiencyScore

	// Overall Productivity Score: Weighted average
	report.ProductivityScore = (report.FocusScore*0.4 + efficiencyScore*0.3 + report.TaskCompletionRate*0.3)
}

// calculateGoalAchievement calculates goal achievement rates
func (s *ReportService) calculateGoalAchievement(report *ProductivityReport, userID uuid.UUID) {
	user, err := s.userService.GetByID(userID.String())
	if err != nil {
		return
	}

	dailyGoal := user.Preferences.DailyGoal
	weeklyGoal := user.Preferences.WeeklyGoal

	// Calculate based on report period
	days := int(report.EndDate.Sub(report.StartDate).Hours() / 24)
	expectedSessions := dailyGoal * days

	if expectedSessions > 0 {
		report.GoalAchievementRate = float64(report.CompletedSessions) / float64(expectedSessions) * 100
	}

	// Calculate actual goals met (simplified)
	report.DailyGoalsMet = int(float64(report.CompletedSessions) / float64(dailyGoal))
	report.WeeklyGoalsMet = report.CompletedSessions / weeklyGoal
}

// fillStreakData fills streak information
func (s *ReportService) fillStreakData(report *ProductivityReport, userID uuid.UUID) {
	streakData, err := s.pomodoroService.GetStreak(userID)
	if err != nil {
		return
	}

	report.CurrentStreak = streakData.CurrentStreak
	report.LongestStreak = streakData.LongestStreak
}

// calculatePreviousPeriodComparison calculates comparison with previous period
func (s *ReportService) calculatePreviousPeriodComparison(report *ProductivityReport, req ReportRequest) {
	// Calculate previous period dates
	duration := report.EndDate.Sub(report.StartDate)
	prevStart := report.StartDate.Add(-duration)
	prevEnd := report.StartDate

	// Get previous period stats
	prevSessionStats, err := s.repo.GetUserSessionStats(req.UserID, prevStart, prevEnd)
	if err != nil {
		return
	}

	prevTaskStats, err := s.repo.GetUserTaskStats(req.UserID, prevStart, prevEnd)
	if err != nil {
		return
	}

	// Calculate changes
	comparison := &PeriodComparison{}

	if prevSessionStats.CompletedSessions > 0 {
		comparison.SessionsChange = (float64(report.CompletedSessions) - float64(prevSessionStats.CompletedSessions)) / float64(prevSessionStats.CompletedSessions) * 100
	}

	if prevSessionStats.TotalWorkTime > 0 {
		comparison.FocusTimeChange = (float64(report.TotalFocusTime) - float64(prevSessionStats.TotalWorkTime)) / float64(prevSessionStats.TotalWorkTime) * 100
	}

	if prevTaskStats.TasksCompleted > 0 {
		comparison.TaskCompletionChange = (float64(report.TasksCompleted) - float64(prevTaskStats.TasksCompleted)) / float64(prevTaskStats.TasksCompleted) * 100
	}

	report.PreviousPeriodComparison = comparison
}

// storeReport stores the generated report for caching
func (s *ReportService) storeReport(report *ProductivityReport) {
	reportModel := &models.Report{
		ID:          uuid.New().String(),
		UserID:      report.UserID.String(),
		StartDate:   report.StartDate,
		EndDate:     report.EndDate,
		ReportType:  models.ReportType(report.ReportType),
		Title:       "Productivity Report",
		Description: fmt.Sprintf("Report for period %s to %s", report.StartDate.Format("2006-01-02"), report.EndDate.Format("2006-01-02")),
		GeneratedAt: report.GeneratedAt,
		Status:      models.ReportTaskStatusCompleted,
		// Convert metrics to JSON and store
	}

	err := s.repo.StoreGeneratedReport(reportModel)
	if err != nil {
		fmt.Printf("Warning: failed to store report: %v\n", err)
	}
}

// convertStoredReport converts a stored report model to ProductivityReport
func (s *ReportService) convertStoredReport(stored *models.Report) *ProductivityReport {
	// Convert stored report back to ProductivityReport
	// This is a simplified conversion - in practice, you'd unmarshal the metrics JSON
	return &ProductivityReport{
		UserID:            uuid.MustParse(stored.UserID),
		ReportType:        ReportType(stored.ReportType),
		StartDate:         stored.StartDate,
		EndDate:           stored.EndDate,
		GeneratedAt:       stored.GeneratedAt,
		CompletedSessions: 0, // Would need to parse from Metrics JSON
		TasksCompleted:    0, // Would need to parse from Metrics JSON
		TotalFocusTime:    0, // Would need to parse from Metrics JSON
	}
}

// Export functions (simplified implementations)

func (s *ReportService) exportJSON(report *ProductivityReport) ([]byte, string, error) {
	// Implementation would marshal report to JSON
	return nil, "application/json", fmt.Errorf("JSON export not yet implemented")
}

func (s *ReportService) exportCSV(report *ProductivityReport) ([]byte, string, error) {
	// Implementation would convert report to CSV format
	return nil, "text/csv", fmt.Errorf("CSV export not yet implemented")
}

func (s *ReportService) exportPDF(report *ProductivityReport) ([]byte, string, error) {
	// Implementation would generate PDF using a library like gofpdf
	return nil, "application/pdf", fmt.Errorf("PDF export not yet implemented")
}

func (s *ReportService) exportXLSX(report *ProductivityReport) ([]byte, string, error) {
	// Implementation would generate Excel file using a library like excelize
	return nil, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fmt.Errorf("XLSX export not yet implemented")
}
