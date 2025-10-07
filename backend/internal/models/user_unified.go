package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// ========== UNIFIED USER MODEL ==========
// This replaces the duplicate User structs in user.go and user_memory.go

// User represents a user in the system with unified interface for all storage backends
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

// UserPreferences contains unified user-specific configuration and preferences
// Supports both simplified (memory) and comprehensive (database) storage backends
type UserPreferences struct {
	// Core Pomodoro Settings (always present)
	WorkDuration       int  `json:"work_duration"`        // in seconds for DB, minutes for memory
	ShortBreakDuration int  `json:"short_break_duration"` // in seconds for DB, minutes for memory
	LongBreakDuration  int  `json:"long_break_duration"`  // in seconds for DB, minutes for memory
	SessionsUntilLongBreak int `json:"sessions_until_long_break"` // default: 4
	AutoStartBreaks    bool `json:"auto_start_breaks"`    // default: false
	AutoStartPomodoros bool `json:"auto_start_pomodoros"` // default: false

	// Core UI Settings (always present)
	NotificationsEnabled bool   `json:"notifications_enabled"`      // default: true
	SoundEnabled        bool   `json:"sound_enabled"`              // default: true
	Theme               string `json:"theme"`                      // "light", "dark", "auto"
	Language            string `json:"language"`                   // ISO 639-1 code, default: "en"

	// Extended Notification Settings (database only, optional for memory)
	DesktopNotifications    *bool `json:"desktop_notifications,omitempty"`      // default: true
	EmailNotifications      *bool `json:"email_notifications,omitempty"`        // default: false
	ReminderNotifications   *bool `json:"reminder_notifications,omitempty"`     // default: true
	DailyReportNotifications *bool `json:"daily_report_notifications,omitempty"` // default: false
	ReminderTiming          *int  `json:"reminder_timing,omitempty"`            // minutes

	// Extended Display Settings (database only, optional for memory)
	DateFormat          *string `json:"date_format,omitempty"`          // default: "YYYY-MM-DD"
	TimeFormat          *string `json:"time_format,omitempty"`          // "12h" or "24h"
	FirstDayOfWeek      *int    `json:"first_day_of_week,omitempty"`    // 0=Sunday, 1=Monday, default: 1
	ShowCompletedTasks  *bool   `json:"show_completed_tasks,omitempty"` // default: true

	// Extended Productivity Settings (database only, optional for memory)
	FocusMode           *bool `json:"focus_mode,omitempty"`            // Hide distracting elements
	MinimalistMode      *bool `json:"minimalist_mode,omitempty"`       // Simplified UI
	ShowProductivityScore *bool `json:"show_productivity_score,omitempty"` // default: true
	WeeklyGoal          *int  `json:"weekly_goal,omitempty"`           // target pomodoros per week
	DailyGoal           *int  `json:"daily_goal,omitempty"`            // target pomodoros per day

	// Extended Advanced Settings (database only, optional for memory)
	SyncEnabled         *bool     `json:"sync_enabled,omitempty"`          // default: true
	OfflineMode         *bool     `json:"offline_mode,omitempty"`          // default: false
	DataRetentionDays   *int      `json:"data_retention_days,omitempty"`   // default: 365
	ExportFormat        *string   `json:"export_format,omitempty"`         // "json", "csv", "pdf"
	BackupEnabled       *bool     `json:"backup_enabled,omitempty"`        // default: false
	AnalyticsEnabled    *bool     `json:"analytics_enabled,omitempty"`     // default: true
	BetaFeaturesEnabled *bool     `json:"beta_features_enabled,omitempty"` // default: false
	CustomSounds        []string  `json:"custom_sounds,omitempty"`         // paths to custom notification sounds
}

// ========== USER FACTORY FUNCTIONS ==========

// NewUser creates a new user with default preferences (database version)
func NewUser(email, name, passwordHash string) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		Name:         name,
		PasswordHash: passwordHash,
		Preferences:  *NewDefaultPreferences(),
		CreatedAt:    now,
		UpdatedAt:    now,
		IsActive:     true,
		Timezone:     "UTC",
	}
}

// NewMemoryUser creates a new user for in-memory storage (simplified version)
func NewMemoryUser(email, name, passwordHash string) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		Name:         name,
		PasswordHash: passwordHash,
		Preferences:  *NewMemoryPreferences(),
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// NewDefaultPreferences creates comprehensive preferences for database storage
func NewDefaultPreferences() *UserPreferences {
	trueBool := true
	falseBool := false
	return &UserPreferences{
		// Core settings (always present)
		WorkDuration:           1500, // 25 minutes in seconds
		ShortBreakDuration:     300,  // 5 minutes in seconds
		LongBreakDuration:      900,  // 15 minutes in seconds
		SessionsUntilLongBreak: 4,
		AutoStartBreaks:        false,
		AutoStartPomodoros:     false,
		NotificationsEnabled:   true,
		SoundEnabled:          true,
		Theme:                 "light",
		Language:              "en",

		// Extended settings (database only)
		DesktopNotifications:     &trueBool,
		EmailNotifications:       &falseBool,
		ReminderNotifications:    &trueBool,
		DailyReportNotifications: &falseBool,
		DateFormat:              stringPtr("YYYY-MM-DD"),
		TimeFormat:              stringPtr("24h"),
		FirstDayOfWeek:          intPtr(1),
		ShowCompletedTasks:      &trueBool,
		FocusMode:               &falseBool,
		MinimalistMode:          &falseBool,
		ShowProductivityScore:   &trueBool,
		WeeklyGoal:              intPtr(35),
		DailyGoal:               intPtr(8),
		SyncEnabled:             &trueBool,
		OfflineMode:             &falseBool,
		DataRetentionDays:       intPtr(365),
		ExportFormat:            stringPtr("json"),
		BackupEnabled:           &falseBool,
		AnalyticsEnabled:        &trueBool,
		BetaFeaturesEnabled:     &falseBool,
	}
}

// NewMemoryPreferences creates simplified preferences for in-memory storage
func NewMemoryPreferences() *UserPreferences {
	return &UserPreferences{
		// Core settings only (minutes for memory storage)
		WorkDuration:           25, // 25 minutes
		ShortBreakDuration:     5,  // 5 minutes
		LongBreakDuration:      15, // 15 minutes
		SessionsUntilLongBreak: 4,
		AutoStartBreaks:        false,
		AutoStartPomodoros:     false,
		NotificationsEnabled:   true,
		SoundEnabled:          true,
		Theme:                 "light",
		Language:              "en",
		// Extended settings are nil/omitted for memory storage
	}
}

// ========== LEGACY COMPATIBILITY TYPES ==========
// These maintain compatibility with existing code while migration occurs

// UserCreateRequest for registration (from user_memory.go)
type UserCreateRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
	Name     string `json:"name" binding:"required,min=2"`
}

// UserLoginRequest for login (from user_memory.go)
type UserLoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// UserResponse for API responses (no password)
type UserResponse struct {
	ID          string          `json:"id"`
	Email       string          `json:"email"`
	Name        string          `json:"name"`
	Preferences UserPreferences `json:"preferences"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

// ========== UTILITY FUNCTIONS ==========

// stringPtr returns a pointer to the given string
func stringPtr(s string) *string {
	return &s
}

// intPtr returns a pointer to the given int
func intPtr(i int) *int {
	return &i
}

// ToUserResponse converts a User to UserResponse (safe for API)
func (u *User) ToUserResponse() UserResponse {
	return UserResponse{
		ID:          u.ID,
		Email:       u.Email,
		Name:        u.Name,
		Preferences: u.Preferences,
		CreatedAt:   u.CreatedAt,
		UpdatedAt:   u.UpdatedAt,
	}
}

// HashPassword hashes a password using bcrypt
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword compares a password with its hash
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// ToMemoryFormat converts database preferences (seconds) to memory format (minutes)
func (p *UserPreferences) ToMemoryFormat() *UserPreferences {
	return &UserPreferences{
		WorkDuration:           p.WorkDuration / 60,  // seconds to minutes
		ShortBreakDuration:     p.ShortBreakDuration / 60,
		LongBreakDuration:      p.LongBreakDuration / 60,
		SessionsUntilLongBreak: p.SessionsUntilLongBreak,
		AutoStartBreaks:        p.AutoStartBreaks,
		AutoStartPomodoros:     p.AutoStartPomodoros,
		NotificationsEnabled:   p.NotificationsEnabled,
		SoundEnabled:          p.SoundEnabled,
		Theme:                 p.Theme,
		Language:              p.Language,
		// Extended fields are omitted in memory format
	}
}

// ToDatabaseFormat converts memory preferences (minutes) to database format (seconds)
func (p *UserPreferences) ToDatabaseFormat() *UserPreferences {
	dbPrefs := NewDefaultPreferences()

	// Convert core settings from minutes to seconds
	dbPrefs.WorkDuration = p.WorkDuration * 60
	dbPrefs.ShortBreakDuration = p.ShortBreakDuration * 60
	dbPrefs.LongBreakDuration = p.LongBreakDuration * 60
	dbPrefs.SessionsUntilLongBreak = p.SessionsUntilLongBreak
	dbPrefs.AutoStartBreaks = p.AutoStartBreaks
	dbPrefs.AutoStartPomodoros = p.AutoStartPomodoros
	dbPrefs.NotificationsEnabled = p.NotificationsEnabled
	dbPrefs.SoundEnabled = p.SoundEnabled
	dbPrefs.Theme = p.Theme
	dbPrefs.Language = p.Language

	return dbPrefs
}