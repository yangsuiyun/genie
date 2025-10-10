package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"
)

// User represents a user in the system
type User struct {
	ID        string    `json:"id" db:"id"`
	Email     string    `json:"email" db:"email"`
	Name      string    `json:"name" db:"name"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// Task represents a task with subtasks support
type Task struct {
	ID          string     `json:"id" db:"id"`
	UserID      string     `json:"user_id" db:"user_id"`
	Title       string     `json:"title" db:"title"`
	Description *string    `json:"description" db:"description"`
	Priority    string     `json:"priority" db:"priority"` // high, medium, low
	Status      string     `json:"status" db:"status"`     // pending, in_progress, completed
	DueDate     *time.Time `json:"due_date" db:"due_date"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
	Subtasks    []Subtask  `json:"subtasks,omitempty"`
}

// Subtask represents a subtask under a main task
type Subtask struct {
	ID        string    `json:"id" db:"id"`
	TaskID    string    `json:"task_id" db:"task_id"`
	Title     string    `json:"title" db:"title"`
	Completed bool      `json:"completed" db:"completed"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// PomodoroSession represents a pomodoro timer session
type PomodoroSession struct {
	ID           string     `json:"id" db:"id"`
	UserID       string     `json:"user_id" db:"user_id"`
	TaskID       *string    `json:"task_id" db:"task_id"`
	Type         string     `json:"type" db:"type"` // work, short_break, long_break
	Duration     int        `json:"duration" db:"duration"` // in seconds
	StartedAt    time.Time  `json:"started_at" db:"started_at"`
	CompletedAt  *time.Time `json:"completed_at" db:"completed_at"`
	Status       string     `json:"status" db:"status"` // active, paused, completed, cancelled
	RemainingTime int       `json:"remaining_time" db:"remaining_time"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
}

// UserSettings represents user preferences
type UserSettings struct {
	UserID               string `json:"user_id" db:"user_id"`
	WorkDuration         int    `json:"work_duration" db:"work_duration"`                   // minutes
	ShortBreakDuration   int    `json:"short_break_duration" db:"short_break_duration"`     // minutes
	LongBreakDuration    int    `json:"long_break_duration" db:"long_break_duration"`       // minutes
	LongBreakInterval    int    `json:"long_break_interval" db:"long_break_interval"`       // sessions
	AutoStartBreaks      bool   `json:"auto_start_breaks" db:"auto_start_breaks"`
	AutoStartPomodoros   bool   `json:"auto_start_pomodoros" db:"auto_start_pomodoros"`
	SoundEnabled         bool   `json:"sound_enabled" db:"sound_enabled"`
	NotificationsEnabled bool   `json:"notifications_enabled" db:"notifications_enabled"`
	Theme                string `json:"theme" db:"theme"`
	CreatedAt            time.Time `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time `json:"updated_at" db:"updated_at"`
}

// DailyStats represents daily statistics for analytics
type DailyStats struct {
	UserID           string    `json:"user_id" db:"user_id"`
	Date             time.Time `json:"date" db:"date"`
	SessionsCompleted int       `json:"sessions_completed" db:"sessions_completed"`
	FocusTime        int       `json:"focus_time" db:"focus_time"` // minutes
	TasksCompleted   int       `json:"tasks_completed" db:"tasks_completed"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time `json:"updated_at" db:"updated_at"`
}

// Note represents a note attached to a task or session
type Note struct {
	ID        string    `json:"id" db:"id"`
	UserID    string    `json:"user_id" db:"user_id"`
	TaskID    *string   `json:"task_id" db:"task_id"`
	SessionID *string   `json:"session_id" db:"session_id"`
	Content   string    `json:"content" db:"content"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// Reminder represents a reminder for a task
type Reminder struct {
	ID        string    `json:"id" db:"id"`
	UserID    string    `json:"user_id" db:"user_id"`
	TaskID    string    `json:"task_id" db:"task_id"`
	RemindAt  time.Time `json:"remind_at" db:"remind_at"`
	Message   string    `json:"message" db:"message"`
	Sent      bool      `json:"sent" db:"sent"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// RecurrenceRule represents how a task repeats
type RecurrenceRule struct {
	ID         string `json:"id" db:"id"`
	TaskID     string `json:"task_id" db:"task_id"`
	Pattern    string `json:"pattern" db:"pattern"` // daily, weekly, monthly
	Interval   int    `json:"interval" db:"interval"` // every N days/weeks/months
	DaysOfWeek *JSONB `json:"days_of_week" db:"days_of_week"` // [0,1,2,3,4,5,6] for weekly
	EndDate    *time.Time `json:"end_date" db:"end_date"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
}

// JSONB type for PostgreSQL JSONB columns
type JSONB []interface{}

// Value implements driver.Valuer interface for JSONB
func (j JSONB) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

// Scan implements sql.Scanner interface for JSONB
func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return nil
	}

	return json.Unmarshal(bytes, j)
}

// CreateTaskRequest represents the request to create a new task
type CreateTaskRequest struct {
	Title       string     `json:"title" binding:"required"`
	Description *string    `json:"description"`
	Priority    string     `json:"priority"` // high, medium, low
	DueDate     *time.Time `json:"due_date"`
}

// UpdateTaskRequest represents the request to update a task
type UpdateTaskRequest struct {
	Title       *string    `json:"title"`
	Description *string    `json:"description"`
	Priority    *string    `json:"priority"`
	Status      *string    `json:"status"`
	DueDate     *time.Time `json:"due_date"`
}

// CreateSubtaskRequest represents the request to create a new subtask
type CreateSubtaskRequest struct {
	Title string `json:"title" binding:"required"`
}

// StartSessionRequest represents the request to start a pomodoro session
type StartSessionRequest struct {
	TaskID   *string `json:"task_id"`
	Type     string  `json:"type" binding:"required"` // work, short_break, long_break
	Duration int     `json:"duration" binding:"required"` // in seconds
}

// UpdateSessionRequest represents the request to update a session
type UpdateSessionRequest struct {
	Status        *string `json:"status"` // active, paused, completed, cancelled
	RemainingTime *int    `json:"remaining_time"`
}

// AnalyticsResponse represents analytics data
type AnalyticsResponse struct {
	Today    DailyStatsResponse `json:"today"`
	ThisWeek WeeklyStatsResponse `json:"this_week"`
}

// DailyStatsResponse represents daily statistics response
type DailyStatsResponse struct {
	SessionsCompleted int `json:"sessions_completed"`
	FocusTime         int `json:"focus_time"`
	TasksCompleted    int `json:"tasks_completed"`
}

// WeeklyStatsResponse represents weekly statistics response
type WeeklyStatsResponse struct {
	SessionsCompleted int `json:"sessions_completed"`
	FocusTime         int `json:"focus_time"`
	TasksCompleted    int `json:"tasks_completed"`
}

// SyncData represents data for synchronization
type SyncData struct {
	Tasks    []Task            `json:"tasks"`
	Sessions []PomodoroSession `json:"sessions"`
	Settings *UserSettings     `json:"settings"`
	LastSync time.Time         `json:"last_sync"`
}