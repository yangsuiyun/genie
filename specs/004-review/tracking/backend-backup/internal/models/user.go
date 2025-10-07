package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// User represents a user in the system
type User struct {
	ID          string            `json:"id" db:"id"`
	Email       string            `json:"email" db:"email"`
	Name        string            `json:"name" db:"name"`
	PasswordHash string           `json:"-" db:"password_hash"` // Never expose in JSON
	Preferences UserPreferences   `json:"preferences" db:"preferences"`
	CreatedAt   time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at" db:"updated_at"`
	LastLoginAt *time.Time        `json:"last_login_at,omitempty" db:"last_login_at"`
	IsActive    bool              `json:"is_active" db:"is_active"`
	Timezone    string            `json:"timezone" db:"timezone"`
	AvatarURL   *string           `json:"avatar_url,omitempty" db:"avatar_url"`
}

// UserPreferences contains user-specific configuration and preferences
type UserPreferences struct {
	// Pomodoro Settings
	WorkDuration       int  `json:"work_duration"`        // in seconds, default: 1500 (25 min)
	ShortBreakDuration int  `json:"short_break_duration"` // in seconds, default: 300 (5 min)
	LongBreakDuration  int  `json:"long_break_duration"`  // in seconds, default: 900 (15 min)
	SessionsUntilLongBreak int `json:"sessions_until_long_break"` // default: 4
	AutoStartBreaks    bool `json:"auto_start_breaks"`    // default: false
	AutoStartPomodoros bool `json:"auto_start_pomodoros"` // default: false

	// Notification Settings
	NotificationsEnabled     bool `json:"notifications_enabled"`      // default: true
	SoundEnabled            bool `json:"sound_enabled"`              // default: true
	DesktopNotifications    bool `json:"desktop_notifications"`      // default: true
	EmailNotifications      bool `json:"email_notifications"`        // default: false
	ReminderNotifications   bool `json:"reminder_notifications"`     // default: true
	DailyReportNotifications bool `json:"daily_report_notifications"` // default: false

	// Display Settings
	Theme               string `json:"theme"`                // "light", "dark", "auto"
	Language            string `json:"language"`             // ISO 639-1 code, default: "en"
	DateFormat          string `json:"date_format"`          // default: "YYYY-MM-DD"
	TimeFormat          string `json:"time_format"`          // "12h" or "24h"
	FirstDayOfWeek      int    `json:"first_day_of_week"`    // 0=Sunday, 1=Monday, default: 1
	ShowCompletedTasks  bool   `json:"show_completed_tasks"` // default: true

	// Productivity Settings
	FocusMode           bool   `json:"focus_mode"`            // Hide distracting elements
	MinimalistMode      bool   `json:"minimalist_mode"`       // Simplified UI
	ShowProductivityScore bool `json:"show_productivity_score"` // default: true
	WeeklyGoal          int    `json:"weekly_goal"`           // target pomodoros per week
	DailyGoal           int    `json:"daily_goal"`            // target pomodoros per day

	// Advanced Settings
	SyncEnabled         bool     `json:"sync_enabled"`          // default: true
	OfflineMode         bool     `json:"offline_mode"`          // default: false
	DataRetentionDays   int      `json:"data_retention_days"`   // default: 365
	ExportFormat        string   `json:"export_format"`         // "json", "csv", "pdf"
	BackupEnabled       bool     `json:"backup_enabled"`        // default: false
	AnalyticsEnabled    bool     `json:"analytics_enabled"`     // default: true
	BetaFeaturesEnabled bool     `json:"beta_features_enabled"` // default: false
	CustomSounds        []string `json:"custom_sounds"`         // paths to custom notification sounds
}

// NewUser creates a new user with default preferences
func NewUser(email, name, passwordHash string) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		Name:         name,
		PasswordHash: passwordHash,
		Preferences:  DefaultUserPreferences(),
		CreatedAt:    now,
		UpdatedAt:    now,
		IsActive:     true,
		Timezone:     "UTC",
	}
}

// DefaultUserPreferences returns the default user preferences
func DefaultUserPreferences() UserPreferences {
	return UserPreferences{
		// Pomodoro Settings
		WorkDuration:           1500, // 25 minutes
		ShortBreakDuration:     300,  // 5 minutes
		LongBreakDuration:      900,  // 15 minutes
		SessionsUntilLongBreak: 4,
		AutoStartBreaks:        false,
		AutoStartPomodoros:     false,

		// Notification Settings
		NotificationsEnabled:     true,
		SoundEnabled:            true,
		DesktopNotifications:    true,
		EmailNotifications:      false,
		ReminderNotifications:   true,
		DailyReportNotifications: false,

		// Display Settings
		Theme:               "light",
		Language:            "en",
		DateFormat:          "YYYY-MM-DD",
		TimeFormat:          "24h",
		FirstDayOfWeek:      1, // Monday
		ShowCompletedTasks:  true,

		// Productivity Settings
		FocusMode:             false,
		MinimalistMode:        false,
		ShowProductivityScore: true,
		WeeklyGoal:           25, // 5 pomodoros per day * 5 working days
		DailyGoal:            5,

		// Advanced Settings
		SyncEnabled:         true,
		OfflineMode:         false,
		DataRetentionDays:   365,
		ExportFormat:        "json",
		BackupEnabled:       false,
		AnalyticsEnabled:    true,
		BetaFeaturesEnabled: false,
		CustomSounds:        []string{},
	}
}

// UpdatePreferences updates the user's preferences
func (u *User) UpdatePreferences(prefs UserPreferences) {
	u.Preferences = prefs
	u.UpdatedAt = time.Now()
}

// UpdateLastLogin updates the user's last login timestamp
func (u *User) UpdateLastLogin() {
	now := time.Now()
	u.LastLoginAt = &now
	u.UpdatedAt = now
}

// SetAvatar sets the user's avatar URL
func (u *User) SetAvatar(url string) {
	u.AvatarURL = &url
	u.UpdatedAt = time.Now()
}

// Deactivate marks the user as inactive
func (u *User) Deactivate() {
	u.IsActive = false
	u.UpdatedAt = time.Now()
}

// Activate marks the user as active
func (u *User) Activate() {
	u.IsActive = true
	u.UpdatedAt = time.Time{}
}

// ValidatePreferences validates user preferences
func (u *User) ValidatePreferences() error {
	prefs := u.Preferences

	// Validate durations
	if prefs.WorkDuration < 60 || prefs.WorkDuration > 3600 {
		return NewValidationError("work_duration", "must be between 60 and 3600 seconds")
	}
	if prefs.ShortBreakDuration < 60 || prefs.ShortBreakDuration > 1800 {
		return NewValidationError("short_break_duration", "must be between 60 and 1800 seconds")
	}
	if prefs.LongBreakDuration < 300 || prefs.LongBreakDuration > 3600 {
		return NewValidationError("long_break_duration", "must be between 300 and 3600 seconds")
	}

	// Validate sessions until long break
	if prefs.SessionsUntilLongBreak < 2 || prefs.SessionsUntilLongBreak > 10 {
		return NewValidationError("sessions_until_long_break", "must be between 2 and 10")
	}

	// Validate theme
	validThemes := map[string]bool{"light": true, "dark": true, "auto": true}
	if !validThemes[prefs.Theme] {
		return NewValidationError("theme", "must be 'light', 'dark', or 'auto'")
	}

	// Validate time format
	if prefs.TimeFormat != "12h" && prefs.TimeFormat != "24h" {
		return NewValidationError("time_format", "must be '12h' or '24h'")
	}

	// Validate first day of week
	if prefs.FirstDayOfWeek < 0 || prefs.FirstDayOfWeek > 6 {
		return NewValidationError("first_day_of_week", "must be between 0 (Sunday) and 6 (Saturday)")
	}

	// Validate goals
	if prefs.DailyGoal < 1 || prefs.DailyGoal > 20 {
		return NewValidationError("daily_goal", "must be between 1 and 20 pomodoros")
	}
	if prefs.WeeklyGoal < 1 || prefs.WeeklyGoal > 100 {
		return NewValidationError("weekly_goal", "must be between 1 and 100 pomodoros")
	}

	// Validate data retention
	if prefs.DataRetentionDays < 30 || prefs.DataRetentionDays > 2555 { // 7 years max
		return NewValidationError("data_retention_days", "must be between 30 and 2555 days")
	}

	// Validate export format
	validFormats := map[string]bool{"json": true, "csv": true, "pdf": true, "xlsx": true}
	if !validFormats[prefs.ExportFormat] {
		return NewValidationError("export_format", "must be 'json', 'csv', 'pdf', or 'xlsx'")
	}

	return nil
}

// ToPublicUser returns a user struct safe for public API responses
func (u *User) ToPublicUser() PublicUser {
	return PublicUser{
		ID:          u.ID,
		Email:       u.Email,
		Name:        u.Name,
		Preferences: u.Preferences,
		CreatedAt:   u.CreatedAt,
		LastLoginAt: u.LastLoginAt,
		Timezone:    u.Timezone,
		AvatarURL:   u.AvatarURL,
	}
}

// PublicUser represents user data safe for public API responses
type PublicUser struct {
	ID          string           `json:"id"`
	Email       string           `json:"email"`
	Name        string           `json:"name"`
	Preferences UserPreferences  `json:"preferences"`
	CreatedAt   time.Time        `json:"created_at"`
	LastLoginAt *time.Time       `json:"last_login_at,omitempty"`
	Timezone    string           `json:"timezone"`
	AvatarURL   *string          `json:"avatar_url,omitempty"`
}

// MarshalPreferencesJSON marshals preferences to JSON for database storage
func (u *User) MarshalPreferencesJSON() ([]byte, error) {
	return json.Marshal(u.Preferences)
}

// UnmarshalPreferencesJSON unmarshals preferences from JSON database storage
func (u *User) UnmarshalPreferencesJSON(data []byte) error {
	return json.Unmarshal(data, &u.Preferences)
}

// ValidationError represents a validation error for user preferences
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

func (e ValidationError) Error() string {
	return e.Field + ": " + e.Message
}

// NewValidationError creates a new validation error
func NewValidationError(field, message string) ValidationError {
	return ValidationError{
		Field:   field,
		Message: message,
	}
}

// UserStats represents aggregate statistics for a user
type UserStats struct {
	UserID               string    `json:"user_id"`
	TotalPomodoros       int       `json:"total_pomodoros"`
	TotalWorkTime        int       `json:"total_work_time"`        // in seconds
	TotalBreakTime       int       `json:"total_break_time"`       // in seconds
	CompletedTasks       int       `json:"completed_tasks"`
	CurrentStreak        int       `json:"current_streak"`         // consecutive days with completed pomodoros
	LongestStreak        int       `json:"longest_streak"`
	AverageSessionLength float64   `json:"average_session_length"` // in seconds
	ProductivityScore    float64   `json:"productivity_score"`     // 0-100
	LastUpdated          time.Time `json:"last_updated"`
}

// UserGoalProgress represents progress towards user goals
type UserGoalProgress struct {
	UserID          string    `json:"user_id"`
	Date            time.Time `json:"date"`
	DailyGoal       int       `json:"daily_goal"`
	DailyCompleted  int       `json:"daily_completed"`
	WeeklyGoal      int       `json:"weekly_goal"`
	WeeklyCompleted int       `json:"weekly_completed"`
	GoalsMet        bool      `json:"goals_met"`
}