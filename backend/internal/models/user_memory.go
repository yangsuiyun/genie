package models

import (
	"time"
	"golang.org/x/crypto/bcrypt"
)

// User represents a user in the in-memory storage
type User struct {
	ID          string          `json:"id"`
	Email       string          `json:"email"`
	Name        string          `json:"name"`
	PasswordHash string         `json:"-"`
	Preferences UserPreferences `json:"preferences"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

// UserPreferences holds user settings
type UserPreferences struct {
	WorkDuration         int    `json:"work_duration"`         // minutes
	ShortBreak          int    `json:"short_break"`           // minutes
	LongBreak           int    `json:"long_break"`            // minutes
	LongBreakInterval   int    `json:"long_break_interval"`   // sessions
	AutoStartBreaks     bool   `json:"auto_start_breaks"`
	AutoStartPomodoros  bool   `json:"auto_start_pomodoros"`
	SoundEnabled        bool   `json:"sound_enabled"`
	NotificationsEnabled bool   `json:"notifications_enabled"`
	ReminderTiming      int    `json:"reminder_timing"`       // minutes
	Theme               string `json:"theme"`
	Language            string `json:"language"`
}

// UserCreateRequest for registration
type UserCreateRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
	Name     string `json:"name" binding:"required,min=2"`
}

// UserLoginRequest for login
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

// NewUser creates a new user with default preferences
func NewUser(id, email, name, password string) (*User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	return &User{
		ID:           id,
		Email:        email,
		Name:         name,
		PasswordHash: string(hashedPassword),
		Preferences: UserPreferences{
			WorkDuration:         25,
			ShortBreak:          5,
			LongBreak:           15,
			LongBreakInterval:   4,
			AutoStartBreaks:     false,
			AutoStartPomodoros:  false,
			SoundEnabled:        true,
			NotificationsEnabled: true,
			ReminderTiming:      15,
			Theme:               "red",
			Language:            "zh",
		},
		CreatedAt: now,
		UpdatedAt: now,
	}, nil
}

// CheckPassword verifies password
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
	return err == nil
}

// ToResponse converts to response format
func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:          u.ID,
		Email:       u.Email,
		Name:        u.Name,
		Preferences: u.Preferences,
		CreatedAt:   u.CreatedAt,
		UpdatedAt:   u.UpdatedAt,
	}
}

// Task represents a task in memory
type Task struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Priority    string    `json:"priority"`    // high, medium, low
	Status      string    `json:"status"`      // pending, in_progress, completed
	DueDate     *time.Time `json:"due_date,omitempty"`
	Tags        []string  `json:"tags"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	Subtasks    []Subtask `json:"subtasks,omitempty"`
}

// Subtask represents a subtask
type Subtask struct {
	ID        string    `json:"id"`
	TaskID    string    `json:"task_id"`
	Title     string    `json:"title"`
	Completed bool      `json:"completed"`
	CreatedAt time.Time `json:"created_at"`
}

// TaskCreateRequest for creating tasks
type TaskCreateRequest struct {
	Title       string     `json:"title" binding:"required"`
	Description string     `json:"description"`
	Priority    string     `json:"priority"`
	DueDate     *time.Time `json:"due_date,omitempty"`
	Tags        []string   `json:"tags"`
}

// TaskUpdateRequest for updating tasks
type TaskUpdateRequest struct {
	Title       *string    `json:"title,omitempty"`
	Description *string    `json:"description,omitempty"`
	Priority    *string    `json:"priority,omitempty"`
	Status      *string    `json:"status,omitempty"`
	DueDate     *time.Time `json:"due_date,omitempty"`
	Tags        []string   `json:"tags,omitempty"`
}

// PomodoroSession represents a pomodoro session
type PomodoroSession struct {
	ID              string    `json:"id"`
	UserID          string    `json:"user_id"`
	TaskID          *string   `json:"task_id,omitempty"`
	Type            string    `json:"type"`            // work, short_break, long_break
	PlannedDuration int       `json:"planned_duration"` // seconds
	ActualDuration  *int      `json:"actual_duration,omitempty"` // seconds
	Status          string    `json:"status"`          // active, completed, cancelled
	StartedAt       time.Time `json:"started_at"`
	CompletedAt     *time.Time `json:"completed_at,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

// SessionCreateRequest for starting sessions
type SessionCreateRequest struct {
	TaskID   *string `json:"task_id,omitempty"`
	Type     string  `json:"type" binding:"required"`     // work, short_break, long_break
	Duration int     `json:"duration" binding:"required"` // seconds
}

// SessionUpdateRequest for updating sessions
type SessionUpdateRequest struct {
	Status          *string `json:"status,omitempty"`           // completed, cancelled
	ActualDuration  *int    `json:"actual_duration,omitempty"`
}