package models

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Report represents a generated report with analytics and metrics
type Report struct {
	ID              string        `json:"id" db:"id"`
	UserID          string        `json:"user_id" db:"user_id"`
	ReportType      ReportType    `json:"report_type" db:"report_type"`
	Period          ReportPeriod  `json:"period" db:"period"`
	StartDate       time.Time     `json:"start_date" db:"start_date"`
	EndDate         time.Time     `json:"end_date" db:"end_date"`
	Title           string        `json:"title" db:"title"`
	Description     string        `json:"description" db:"description"`
	Metrics         ReportMetrics `json:"metrics" db:"metrics"`
	Filters         ReportFilters `json:"filters" db:"filters"`
	GeneratedAt     time.Time     `json:"generated_at" db:"generated_at"`
	ExpiresAt       *time.Time    `json:"expires_at,omitempty" db:"expires_at"`
	IsPrivate       bool          `json:"is_private" db:"is_private"`
	ShareToken      *string       `json:"share_token,omitempty" db:"share_token"`
	DownloadCount   int           `json:"download_count" db:"download_count"`
	FileSize        *int64        `json:"file_size,omitempty" db:"file_size"` // in bytes
	Status          ReportStatus  `json:"status" db:"status"`
	ErrorMessage    *string       `json:"error_message,omitempty" db:"error_message"`
	CreatedAt       time.Time     `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at" db:"updated_at"`
}

// ReportType represents different types of reports
type ReportType string

const (
	ReportTypeProductivity ReportType = "productivity"
	ReportTypeTime         ReportType = "time"
	ReportTypeTasks        ReportType = "tasks"
	ReportTypePomodoro     ReportType = "pomodoro"
	ReportTypeGoals        ReportType = "goals"
	ReportTypeTrends       ReportType = "trends"
	ReportTypeComparison   ReportType = "comparison"
	ReportTypeCustom       ReportType = "custom"
	ReportTypeSummary      ReportType = "summary"
)

// ReportPeriod represents the time period for the report
type ReportPeriod string

const (
	PeriodDay     ReportPeriod = "day"
	PeriodWeek    ReportPeriod = "week"
	PeriodMonth   ReportPeriod = "month"
	PeriodQuarter ReportPeriod = "quarter"
	PeriodYear    ReportPeriod = "year"
	PeriodCustom  ReportPeriod = "custom"
	PeriodAllTime ReportPeriod = "all_time"
)

// ReportStatus represents the generation status of a report
type ReportStatus string

const (
	ReportStatusPending   ReportStatus = "pending"
	ReportStatusGenerating ReportStatus = "generating"
	ReportStatusCompleted ReportStatus = "completed"
	ReportStatusFailed    ReportStatus = "failed"
	ReportStatusExpired   ReportStatus = "expired"
)

// ReportMetrics contains all the metrics and data for a report
type ReportMetrics struct {
	// Basic Metrics
	TotalSessions        int     `json:"total_sessions"`
	CompletedSessions    int     `json:"completed_sessions"`
	CancelledSessions    int     `json:"cancelled_sessions"`
	TotalWorkTime        int     `json:"total_work_time"`        // in seconds
	TotalBreakTime       int     `json:"total_break_time"`       // in seconds
	TotalActiveTime      int     `json:"total_active_time"`      // in seconds
	AverageSessionLength float64 `json:"average_session_length"` // in seconds

	// Task Metrics
	TotalTasks         int     `json:"total_tasks"`
	CompletedTasks     int     `json:"completed_tasks"`
	PendingTasks       int     `json:"pending_tasks"`
	OverdueTasks       int     `json:"overdue_tasks"`
	TaskCompletionRate float64 `json:"task_completion_rate"` // percentage

	// Productivity Metrics
	ProductivityScore    float64 `json:"productivity_score"`    // 0-100
	FocusScore          float64 `json:"focus_score"`           // 0-100
	EfficiencyScore     float64 `json:"efficiency_score"`      // 0-100
	ConsistencyScore    float64 `json:"consistency_score"`     // 0-100
	InterruptionRate    float64 `json:"interruption_rate"`     // percentage
	AverageInterruptions float64 `json:"average_interruptions"` // per session

	// Time Distribution
	TimeDistribution     TimeDistribution     `json:"time_distribution"`
	TaskBreakdown        []TaskProductivity   `json:"task_breakdown,omitempty"`
	CategoryBreakdown    []CategoryBreakdown  `json:"category_breakdown,omitempty"`
	DailyBreakdown       []DailyMetrics      `json:"daily_breakdown,omitempty"`
	WeeklyBreakdown      []WeeklyMetrics     `json:"weekly_breakdown,omitempty"`

	// Goals and Achievements
	GoalProgress        []GoalProgress       `json:"goal_progress,omitempty"`
	Achievements        []Achievement        `json:"achievements,omitempty"`
	Streaks             StreakMetrics        `json:"streaks"`

	// Trends and Comparisons
	Trends              []TrendData          `json:"trends,omitempty"`
	PreviousPeriod      *ComparisonMetrics   `json:"previous_period,omitempty"`
	YearOverYear        *ComparisonMetrics   `json:"year_over_year,omitempty"`

	// Additional Analysis
	PeakProductivity    PeakProductivity     `json:"peak_productivity"`
	Recommendations     []Recommendation     `json:"recommendations,omitempty"`
	Insights           []Insight            `json:"insights,omitempty"`
}

// TimeDistribution represents how time is distributed across different activities
type TimeDistribution struct {
	WorkTime        int     `json:"work_time"`        // in seconds
	BreakTime       int     `json:"break_time"`       // in seconds
	OverheadTime    int     `json:"overhead_time"`    // in seconds
	WorkPercentage  float64 `json:"work_percentage"`  // percentage
	BreakPercentage float64 `json:"break_percentage"` // percentage
	HourlyDistribution map[int]int `json:"hourly_distribution"` // hour -> seconds
	DayOfWeekDistribution map[string]int `json:"day_of_week_distribution"` // day -> seconds
}

// CategoryBreakdown represents time spent on different task categories
type CategoryBreakdown struct {
	Category    string  `json:"category"`
	TimeSpent   int     `json:"time_spent"`   // in seconds
	Sessions    int     `json:"sessions"`
	Tasks       int     `json:"tasks"`
	Percentage  float64 `json:"percentage"`
	Trend       string  `json:"trend"` // "up", "down", "stable"
}

// DailyMetrics represents metrics for a specific day
type DailyMetrics struct {
	Date              string  `json:"date"`
	Sessions          int     `json:"sessions"`
	CompletedSessions int     `json:"completed_sessions"`
	WorkTime          int     `json:"work_time"`
	Tasks             int     `json:"tasks"`
	CompletedTasks    int     `json:"completed_tasks"`
	ProductivityScore float64 `json:"productivity_score"`
	FocusScore        float64 `json:"focus_score"`
	Interruptions     int     `json:"interruptions"`
}

// WeeklyMetrics represents metrics for a specific week
type WeeklyMetrics struct {
	WeekStart         string  `json:"week_start"`
	WeekEnd           string  `json:"week_end"`
	Sessions          int     `json:"sessions"`
	CompletedSessions int     `json:"completed_sessions"`
	WorkTime          int     `json:"work_time"`
	Tasks             int     `json:"tasks"`
	CompletedTasks    int     `json:"completed_tasks"`
	ProductivityScore float64 `json:"productivity_score"`
	GoalAchievement   float64 `json:"goal_achievement"` // percentage
	Consistency       float64 `json:"consistency"`      // percentage
}

// GoalProgress represents progress towards specific goals
type GoalProgress struct {
	GoalType        string  `json:"goal_type"`        // "daily", "weekly", "monthly"
	GoalTarget      int     `json:"goal_target"`
	GoalAchieved    int     `json:"goal_achieved"`
	GoalPercentage  float64 `json:"goal_percentage"`
	DaysRemaining   int     `json:"days_remaining"`
	OnTrack         bool    `json:"on_track"`
	PredictedFinish string  `json:"predicted_finish"`
}

// Achievement represents unlocked achievements
type Achievement struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Icon        string    `json:"icon"`
	UnlockedAt  time.Time `json:"unlocked_at"`
	Type        string    `json:"type"` // "streak", "milestone", "efficiency", etc.
	Level       int       `json:"level"`
	Points      int       `json:"points"`
}

// StreakMetrics represents various streak information
type StreakMetrics struct {
	CurrentStreak    int         `json:"current_streak"`    // consecutive days
	LongestStreak    int         `json:"longest_streak"`
	WeeklyStreak     int         `json:"weekly_streak"`     // consecutive weeks
	MonthlyStreak    int         `json:"monthly_streak"`    // consecutive months
	StreakType       string      `json:"streak_type"`       // "daily", "weekly", etc.
	StreakHistory    []StreakDay `json:"streak_history,omitempty"`
	LastStreakDate   *string     `json:"last_streak_date,omitempty"`
}

// StreakDay represents a day in the streak history
type StreakDay struct {
	Date          string `json:"date"`
	GoalMet       bool   `json:"goal_met"`
	Sessions      int    `json:"sessions"`
	MinutesWorked int    `json:"minutes_worked"`
}

// TrendData represents trend information over time
type TrendData struct {
	Metric      string      `json:"metric"`
	DataPoints  []DataPoint `json:"data_points"`
	Trend       string      `json:"trend"`       // "increasing", "decreasing", "stable"
	TrendValue  float64     `json:"trend_value"` // percentage change
	Correlation float64     `json:"correlation"` // with productivity
}

// DataPoint represents a single data point in a trend
type DataPoint struct {
	Date        string  `json:"date"`
	Value       float64 `json:"value"`
	MovingAvg   float64 `json:"moving_avg,omitempty"`
	Prediction  float64 `json:"prediction,omitempty"`
}

// ComparisonMetrics represents comparison with previous periods
type ComparisonMetrics struct {
	Period                 string  `json:"period"`
	Sessions               int     `json:"sessions"`
	SessionsChange         float64 `json:"sessions_change"`         // percentage
	WorkTime               int     `json:"work_time"`
	WorkTimeChange         float64 `json:"work_time_change"`        // percentage
	ProductivityScore      float64 `json:"productivity_score"`
	ProductivityChange     float64 `json:"productivity_change"`     // percentage
	TasksCompleted         int     `json:"tasks_completed"`
	TasksCompletedChange   float64 `json:"tasks_completed_change"`  // percentage
	CompletionRate         float64 `json:"completion_rate"`
	CompletionRateChange   float64 `json:"completion_rate_change"`  // percentage
}

// PeakProductivity represents when the user is most productive
type PeakProductivity struct {
	BestDayOfWeek    string                `json:"best_day_of_week"`
	BestTimeOfDay    string                `json:"best_time_of_day"`
	BestHour         int                   `json:"best_hour"`
	ProductivityPattern ProductivityPattern `json:"productivity_pattern"`
	OptimalSessionLength int                `json:"optimal_session_length"` // in minutes
	OptimalBreakLength   int                `json:"optimal_break_length"`   // in minutes
}

// ProductivityPattern represents productivity patterns
type ProductivityPattern struct {
	MorningScore    float64 `json:"morning_score"`    // 6-12
	AfternoonScore  float64 `json:"afternoon_score"`  // 12-18
	EveningScore    float64 `json:"evening_score"`    // 18-22
	NightScore      float64 `json:"night_score"`      // 22-6
	WeekdayScore    float64 `json:"weekday_score"`
	WeekendScore    float64 `json:"weekend_score"`
	PatternType     string  `json:"pattern_type"`     // "early_bird", "night_owl", "balanced"
}

// Recommendation represents actionable recommendations
type Recommendation struct {
	ID          string `json:"id"`
	Type        string `json:"type"`        // "schedule", "duration", "break", "goal"
	Priority    string `json:"priority"`    // "high", "medium", "low"
	Title       string `json:"title"`
	Description string `json:"description"`
	Action      string `json:"action"`
	Impact      string `json:"impact"`      // expected impact
	Confidence  float64 `json:"confidence"` // 0-100
	BasedOn     string `json:"based_on"`    // what data this is based on
}

// Insight represents data-driven insights
type Insight struct {
	ID          string  `json:"id"`
	Type        string  `json:"type"`        // "pattern", "anomaly", "achievement", "opportunity"
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Significance string `json:"significance"` // "high", "medium", "low"
	Metric      string  `json:"metric"`
	Value       float64 `json:"value"`
	Change      float64 `json:"change"`      // percentage change
	Context     string  `json:"context"`
}

// ReportFilters represents filters applied to generate the report
type ReportFilters struct {
	Tags            []string `json:"tags,omitempty"`
	TaskCategories  []string `json:"task_categories,omitempty"`
	Projects        []string `json:"projects,omitempty"`
	Priorities      []string `json:"priorities,omitempty"`
	CompletedOnly   bool     `json:"completed_only"`
	IncludeBreaks   bool     `json:"include_breaks"`
	IncludeWeekends bool     `json:"include_weekends"`
	MinSessionLength *int    `json:"min_session_length,omitempty"`
	MaxSessionLength *int    `json:"max_session_length,omitempty"`
}

// NewReport creates a new report
func NewReport(userID string, reportType ReportType, period ReportPeriod, startDate, endDate time.Time) *Report {
	now := time.Now()
	return &Report{
		ID:          uuid.New().String(),
		UserID:      userID,
		ReportType:  reportType,
		Period:      period,
		StartDate:   startDate,
		EndDate:     endDate,
		Title:       generateReportTitle(reportType, period, startDate, endDate),
		Metrics:     ReportMetrics{},
		Filters:     ReportFilters{},
		GeneratedAt: now,
		IsPrivate:   true,
		Status:      ReportStatusPending,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

// generateReportTitle generates a default title for the report
func generateReportTitle(reportType ReportType, period ReportPeriod, startDate, endDate time.Time) string {
	typeStr := string(reportType)
	periodStr := string(period)

	if period == PeriodCustom {
		return fmt.Sprintf("%s Report (%s to %s)",
			capitalizeFirst(typeStr),
			startDate.Format("Jan 2"),
			endDate.Format("Jan 2, 2006"))
	}

	return fmt.Sprintf("%s %s Report", capitalizeFirst(periodStr), capitalizeFirst(typeStr))
}

// capitalizeFirst capitalizes the first letter of a string
func capitalizeFirst(s string) string {
	if len(s) == 0 {
		return s
	}
	return strings.ToUpper(s[:1]) + s[1:]
}

// SetTitle sets a custom title for the report
func (r *Report) SetTitle(title string) {
	r.Title = title
	r.UpdatedAt = time.Now()
}

// SetDescription sets a description for the report
func (r *Report) SetDescription(description string) {
	r.Description = description
	r.UpdatedAt = time.Now()
}

// SetFilters sets the filters for the report
func (r *Report) SetFilters(filters ReportFilters) {
	r.Filters = filters
	r.UpdatedAt = time.Now()
}

// SetMetrics sets the calculated metrics for the report
func (r *Report) SetMetrics(metrics ReportMetrics) {
	r.Metrics = metrics
	r.UpdatedAt = time.Now()
}

// MarkAsGenerating marks the report as currently being generated
func (r *Report) MarkAsGenerating() {
	r.Status = ReportStatusGenerating
	r.UpdatedAt = time.Now()
}

// MarkAsCompleted marks the report as completed
func (r *Report) MarkAsCompleted() {
	r.Status = ReportStatusCompleted
	r.UpdatedAt = time.Now()
}

// MarkAsFailed marks the report as failed with an error message
func (r *Report) MarkAsFailed(errorMessage string) {
	r.Status = ReportStatusFailed
	r.ErrorMessage = &errorMessage
	r.UpdatedAt = time.Now()
}

// GenerateShareToken generates a token for sharing the report
func (r *Report) GenerateShareToken() string {
	token := uuid.New().String()
	r.ShareToken = &token
	r.UpdatedAt = time.Now()
	return token
}

// RevokeShareToken revokes the share token
func (r *Report) RevokeShareToken() {
	r.ShareToken = nil
	r.UpdatedAt = time.Now()
}

// SetExpiration sets when the report expires
func (r *Report) SetExpiration(expiresAt time.Time) {
	r.ExpiresAt = &expiresAt
	r.UpdatedAt = time.Now()
}

// IsExpired checks if the report has expired
func (r *Report) IsExpired() bool {
	if r.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*r.ExpiresAt)
}

// IncrementDownloadCount increments the download counter
func (r *Report) IncrementDownloadCount() {
	r.DownloadCount++
	r.UpdatedAt = time.Now()
}

// SetFileSize sets the file size for exported reports
func (r *Report) SetFileSize(size int64) {
	r.FileSize = &size
	r.UpdatedAt = time.Now()
}

// GetSummary returns a summary of the report metrics
func (r *Report) GetSummary() ReportSummary {
	return ReportSummary{
		ReportID:          r.ID,
		ReportType:        r.ReportType,
		Period:            r.Period,
		TotalSessions:     r.Metrics.TotalSessions,
		CompletedSessions: r.Metrics.CompletedSessions,
		TotalWorkTime:     r.Metrics.TotalWorkTime,
		ProductivityScore: r.Metrics.ProductivityScore,
		TasksCompleted:    r.Metrics.CompletedTasks,
		GoalsAchieved:     r.calculateGoalsAchieved(),
		KeyInsight:        r.getKeyInsight(),
		GeneratedAt:       r.GeneratedAt,
	}
}

// calculateGoalsAchieved calculates how many goals were achieved
func (r *Report) calculateGoalsAchieved() int {
	achieved := 0
	for _, goal := range r.Metrics.GoalProgress {
		if goal.GoalPercentage >= 100 {
			achieved++
		}
	}
	return achieved
}

// getKeyInsight returns the most significant insight
func (r *Report) getKeyInsight() string {
	if len(r.Metrics.Insights) == 0 {
		return ""
	}

	// Find the highest significance insight
	var keyInsight Insight
	for _, insight := range r.Metrics.Insights {
		if insight.Significance == "high" {
			keyInsight = insight
			break
		}
	}

	if keyInsight.ID == "" && len(r.Metrics.Insights) > 0 {
		keyInsight = r.Metrics.Insights[0]
	}

	return keyInsight.Description
}

// Validate validates the report fields
func (r *Report) Validate() error {
	// Validate report type
	validTypes := map[ReportType]bool{
		ReportTypeProductivity: true,
		ReportTypeTime:         true,
		ReportTypeTasks:        true,
		ReportTypePomodoro:     true,
		ReportTypeGoals:        true,
		ReportTypeTrends:       true,
		ReportTypeComparison:   true,
		ReportTypeCustom:       true,
		ReportTypeSummary:      true,
	}
	if !validTypes[r.ReportType] {
		return NewValidationError("report_type", "invalid report type")
	}

	// Validate period
	validPeriods := map[ReportPeriod]bool{
		PeriodDay:     true,
		PeriodWeek:    true,
		PeriodMonth:   true,
		PeriodQuarter: true,
		PeriodYear:    true,
		PeriodCustom:  true,
		PeriodAllTime: true,
	}
	if !validPeriods[r.Period] {
		return NewValidationError("period", "invalid period")
	}

	// Validate date range
	if r.EndDate.Before(r.StartDate) {
		return NewValidationError("date_range", "end date must be after start date")
	}

	// Validate title
	if len(r.Title) > 200 {
		return NewValidationError("title", "title must be 200 characters or less")
	}

	// Validate description
	if len(r.Description) > 1000 {
		return NewValidationError("description", "description must be 1000 characters or less")
	}

	return nil
}

// MarshalMetricsJSON marshals metrics to JSON for database storage
func (r *Report) MarshalMetricsJSON() ([]byte, error) {
	return json.Marshal(r.Metrics)
}

// UnmarshalMetricsJSON unmarshals metrics from JSON database storage
func (r *Report) UnmarshalMetricsJSON(data []byte) error {
	return json.Unmarshal(data, &r.Metrics)
}

// MarshalFiltersJSON marshals filters to JSON for database storage
func (r *Report) MarshalFiltersJSON() ([]byte, error) {
	return json.Marshal(r.Filters)
}

// UnmarshalFiltersJSON unmarshals filters from JSON database storage
func (r *Report) UnmarshalFiltersJSON(data []byte) error {
	return json.Unmarshal(data, &r.Filters)
}

// ReportSummary represents a lightweight summary of a report
type ReportSummary struct {
	ReportID          string       `json:"report_id"`
	ReportType        ReportType   `json:"report_type"`
	Period            ReportPeriod `json:"period"`
	TotalSessions     int          `json:"total_sessions"`
	CompletedSessions int          `json:"completed_sessions"`
	TotalWorkTime     int          `json:"total_work_time"`
	ProductivityScore float64      `json:"productivity_score"`
	TasksCompleted    int          `json:"tasks_completed"`
	GoalsAchieved     int          `json:"goals_achieved"`
	KeyInsight        string       `json:"key_insight"`
	GeneratedAt       time.Time    `json:"generated_at"`
}

// ReportTemplate represents a template for generating reports
type ReportTemplate struct {
	ID              string        `json:"id" db:"id"`
	UserID          string        `json:"user_id" db:"user_id"`
	Name            string        `json:"name" db:"name"`
	Description     string        `json:"description" db:"description"`
	ReportType      ReportType    `json:"report_type" db:"report_type"`
	DefaultPeriod   ReportPeriod  `json:"default_period" db:"default_period"`
	DefaultFilters  ReportFilters `json:"default_filters" db:"default_filters"`
	IncludedMetrics []string      `json:"included_metrics" db:"included_metrics"`
	AutoGenerate    bool          `json:"auto_generate" db:"auto_generate"`
	Schedule        *string       `json:"schedule,omitempty" db:"schedule"` // cron expression
	CreatedAt       time.Time     `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at" db:"updated_at"`
	LastUsed        *time.Time    `json:"last_used,omitempty" db:"last_used"`
	UsageCount      int           `json:"usage_count" db:"usage_count"`
}

// NewReportTemplate creates a new report template
func NewReportTemplate(userID, name, description string, reportType ReportType, period ReportPeriod) *ReportTemplate {
	now := time.Now()
	return &ReportTemplate{
		ID:              uuid.New().String(),
		UserID:          userID,
		Name:            name,
		Description:     description,
		ReportType:      reportType,
		DefaultPeriod:   period,
		DefaultFilters:  ReportFilters{},
		IncludedMetrics: []string{},
		AutoGenerate:    false,
		CreatedAt:       now,
		UpdatedAt:       now,
		UsageCount:      0,
	}
}