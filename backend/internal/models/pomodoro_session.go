package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// PomodoroSession represents a Pomodoro session
type PomodoroSession struct {
	ID                string             `json:"id" db:"id"`
	UserID            string             `json:"user_id" db:"user_id"`
	TaskID            string             `json:"task_id" db:"task_id"`
	SessionType       PomodoroSessionType `json:"session_type" db:"session_type"`
	Status            PomodoroStatus     `json:"status" db:"status"`
	PlannedDuration   int                `json:"planned_duration" db:"planned_duration"`     // in seconds
	ActualDuration    *int               `json:"actual_duration,omitempty" db:"actual_duration"` // in seconds
	StartedAt         time.Time          `json:"started_at" db:"started_at"`
	PausedAt          *time.Time         `json:"paused_at,omitempty" db:"paused_at"`
	ResumedAt         *time.Time         `json:"resumed_at,omitempty" db:"resumed_at"`
	CompletedAt       *time.Time         `json:"completed_at,omitempty" db:"completed_at"`
	CancelledAt       *time.Time         `json:"cancelled_at,omitempty" db:"cancelled_at"`
	InterruptionCount int                `json:"interruption_count" db:"interruption_count"`
	InterruptionReason *string           `json:"interruption_reason,omitempty" db:"interruption_reason"`
	Notes             *string            `json:"notes,omitempty" db:"notes"`
	CreatedAt         time.Time          `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time          `json:"updated_at" db:"updated_at"`
	SyncVersion       int64              `json:"sync_version" db:"sync_version"`

	// Computed fields (not stored in DB)
	ElapsedTime       int                `json:"elapsed_time" db:"-"`       // in seconds
	RemainingTime     int                `json:"remaining_time" db:"-"`     // in seconds
	ProgressPercent   float64            `json:"progress_percent" db:"-"`   // 0-100
	PauseCount        int                `json:"pause_count" db:"-"`
	TotalPauseTime    int                `json:"total_pause_time" db:"-"`   // in seconds
	EfficiencyScore   float64            `json:"efficiency_score" db:"-"`   // 0-100
}

// PomodoroSessionType represents the type of Pomodoro session
type PomodoroSessionType string

const (
	SessionTypeWork      PomodoroSessionType = "work"
	SessionTypeShortBreak PomodoroSessionType = "short_break"
	SessionTypeLongBreak PomodoroSessionType = "long_break"
)

// PomodoroStatus represents the current status of a Pomodoro session
type PomodoroStatus string

const (
	StatusActive    PomodoroStatus = "active"
	StatusPaused    PomodoroStatus = "paused"
	StatusCompleted PomodoroStatus = "completed"
	StatusCancelled PomodoroStatus = "cancelled"
)

// NewPomodoroSession creates a new Pomodoro session
func NewPomodoroSession(userID, taskID string, sessionType PomodoroSessionType, plannedDuration int) *PomodoroSession {
	now := time.Now()
	return &PomodoroSession{
		ID:                uuid.New().String(),
		UserID:            userID,
		TaskID:            taskID,
		SessionType:       sessionType,
		Status:            StatusActive,
		PlannedDuration:   plannedDuration,
		StartedAt:         now,
		InterruptionCount: 0,
		CreatedAt:         now,
		UpdatedAt:         now,
		SyncVersion:       1,
	}
}

// StateMachine defines valid state transitions for Pomodoro sessions
type StateMachine struct {
	validTransitions map[PomodoroStatus][]PomodoroStatus
}

// NewStateMachine creates a new state machine for Pomodoro sessions
func NewStateMachine() *StateMachine {
	return &StateMachine{
		validTransitions: map[PomodoroStatus][]PomodoroStatus{
			StatusActive:    {StatusPaused, StatusCompleted, StatusCancelled},
			StatusPaused:    {StatusActive, StatusCompleted, StatusCancelled},
			StatusCompleted: {}, // Terminal state
			StatusCancelled: {}, // Terminal state
		},
	}
}

// CanTransition checks if a status transition is valid
func (sm *StateMachine) CanTransition(from, to PomodoroStatus) bool {
	allowedStates, exists := sm.validTransitions[from]
	if !exists {
		return false
	}

	for _, allowedState := range allowedStates {
		if allowedState == to {
			return true
		}
	}
	return false
}

// Pause pauses the session
func (ps *PomodoroSession) Pause() error {
	sm := NewStateMachine()
	if !sm.CanTransition(ps.Status, StatusPaused) {
		return NewValidationError("status", "cannot pause session in current state: "+string(ps.Status))
	}

	now := time.Now()
	ps.Status = StatusPaused
	ps.PausedAt = &now
	ps.UpdatedAt = now
	ps.SyncVersion++

	return nil
}

// Resume resumes a paused session
func (ps *PomodoroSession) Resume() error {
	sm := NewStateMachine()
	if !sm.CanTransition(ps.Status, StatusActive) {
		return NewValidationError("status", "cannot resume session in current state: "+string(ps.Status))
	}

	now := time.Now()
	ps.Status = StatusActive
	ps.ResumedAt = &now
	ps.UpdatedAt = now
	ps.SyncVersion++

	return nil
}

// Complete completes the session
func (ps *PomodoroSession) Complete(actualDuration *int) error {
	sm := NewStateMachine()
	if !sm.CanTransition(ps.Status, StatusCompleted) {
		return NewValidationError("status", "cannot complete session in current state: "+string(ps.Status))
	}

	now := time.Now()
	ps.Status = StatusCompleted
	ps.CompletedAt = &now
	ps.UpdatedAt = now
	ps.SyncVersion++

	if actualDuration != nil {
		ps.ActualDuration = actualDuration
	} else {
		// Calculate actual duration based on start time and current time
		elapsed := int(now.Sub(ps.StartedAt).Seconds())
		ps.ActualDuration = &elapsed
	}

	return nil
}

// Cancel cancels the session
func (ps *PomodoroSession) Cancel() error {
	sm := NewStateMachine()
	if !sm.CanTransition(ps.Status, StatusCancelled) {
		return NewValidationError("status", "cannot cancel session in current state: "+string(ps.Status))
	}

	now := time.Now()
	ps.Status = StatusCancelled
	ps.CancelledAt = &now
	ps.UpdatedAt = now
	ps.SyncVersion++

	return nil
}

// AddInterruption records an interruption
func (ps *PomodoroSession) AddInterruption(reason string) {
	ps.InterruptionCount++
	if reason != "" {
		ps.InterruptionReason = &reason
	}
	ps.UpdatedAt = time.Now()
	ps.SyncVersion++
}

// AddNote adds a note to the session
func (ps *PomodoroSession) AddNote(note string) {
	ps.Notes = &note
	ps.UpdatedAt = time.Now()
	ps.SyncVersion++
}

// UpdateDuration updates the actual duration
func (ps *PomodoroSession) UpdateDuration(duration int) {
	ps.ActualDuration = &duration
	ps.UpdatedAt = time.Now()
	ps.SyncVersion++
}

// CalculateElapsedTime calculates the elapsed time since session start
func (ps *PomodoroSession) CalculateElapsedTime() int {
	if ps.Status == StatusCompleted && ps.ActualDuration != nil {
		return *ps.ActualDuration
	}

	if ps.Status == StatusCancelled {
		if ps.CancelledAt != nil {
			return int(ps.CancelledAt.Sub(ps.StartedAt).Seconds())
		}
		return 0
	}

	now := time.Now()
	if ps.Status == StatusPaused && ps.PausedAt != nil {
		return int(ps.PausedAt.Sub(ps.StartedAt).Seconds())
	}

	return int(now.Sub(ps.StartedAt).Seconds())
}

// CalculateRemainingTime calculates the remaining time in the session
func (ps *PomodoroSession) CalculateRemainingTime() int {
	elapsed := ps.CalculateElapsedTime()
	remaining := ps.PlannedDuration - elapsed
	if remaining < 0 {
		return 0
	}
	return remaining
}

// CalculateProgressPercent calculates the progress percentage
func (ps *PomodoroSession) CalculateProgressPercent() float64 {
	if ps.PlannedDuration == 0 {
		return 0
	}

	elapsed := ps.CalculateElapsedTime()
	progress := (float64(elapsed) / float64(ps.PlannedDuration)) * 100
	if progress > 100 {
		return 100
	}
	return progress
}

// CalculateEfficiencyScore calculates the efficiency score based on completion and interruptions
func (ps *PomodoroSession) CalculateEfficiencyScore() float64 {
	baseScore := 100.0

	// Deduct points for interruptions
	interruptionPenalty := float64(ps.InterruptionCount) * 10.0
	if interruptionPenalty > 50 {
		interruptionPenalty = 50 // Max 50% penalty for interruptions
	}

	// Deduct points for not completing
	completionBonus := 0.0
	if ps.Status == StatusCompleted {
		completionBonus = 20.0
	}

	// Bonus for completing close to planned duration
	durationBonus := 0.0
	if ps.ActualDuration != nil && ps.Status == StatusCompleted {
		ratio := float64(*ps.ActualDuration) / float64(ps.PlannedDuration)
		if ratio >= 0.8 && ratio <= 1.2 { // Within 20% of planned duration
			durationBonus = 10.0
		}
	}

	score := baseScore - interruptionPenalty + completionBonus + durationBonus
	if score < 0 {
		return 0
	}
	if score > 100 {
		return 100
	}
	return score
}

// IsActive returns true if the session is currently active
func (ps *PomodoroSession) IsActive() bool {
	return ps.Status == StatusActive
}

// IsPaused returns true if the session is paused
func (ps *PomodoroSession) IsPaused() bool {
	return ps.Status == StatusPaused
}

// IsCompleted returns true if the session is completed
func (ps *PomodoroSession) IsCompleted() bool {
	return ps.Status == StatusCompleted
}

// IsCancelled returns true if the session is cancelled
func (ps *PomodoroSession) IsCancelled() bool {
	return ps.Status == StatusCancelled
}

// IsFinished returns true if the session is completed or cancelled
func (ps *PomodoroSession) IsFinished() bool {
	return ps.IsCompleted() || ps.IsCancelled()
}

// GetDurationText returns a human-readable duration string
func (ps *PomodoroSession) GetDurationText() string {
	duration := ps.PlannedDuration
	if ps.ActualDuration != nil {
		duration = *ps.ActualDuration
	}

	minutes := duration / 60
	seconds := duration % 60
	return fmt.Sprintf("%d:%02d", minutes, seconds)
}

// Validate validates the session fields
func (ps *PomodoroSession) Validate() error {
	// Validate session type
	validTypes := map[PomodoroSessionType]bool{
		SessionTypeWork:      true,
		SessionTypeShortBreak: true,
		SessionTypeLongBreak: true,
	}
	if !validTypes[ps.SessionType] {
		return NewValidationError("session_type", "invalid session type")
	}

	// Validate planned duration
	if ps.PlannedDuration < 60 || ps.PlannedDuration > 3600 {
		return NewValidationError("planned_duration", "planned duration must be between 60 and 3600 seconds")
	}

	// Validate actual duration if set
	if ps.ActualDuration != nil && (*ps.ActualDuration < 0 || *ps.ActualDuration > 7200) {
		return NewValidationError("actual_duration", "actual duration must be between 0 and 7200 seconds")
	}

	// Validate interruption count
	if ps.InterruptionCount < 0 || ps.InterruptionCount > 100 {
		return NewValidationError("interruption_count", "interruption count must be between 0 and 100")
	}

	// Validate notes length
	if ps.Notes != nil && len(*ps.Notes) > 1000 {
		return NewValidationError("notes", "notes must be 1000 characters or less")
	}

	return nil
}

// PomodoroSessionFilter represents filters for session queries
type PomodoroSessionFilter struct {
	UserID      string              `json:"user_id"`
	TaskID      *string             `json:"task_id,omitempty"`
	SessionType *PomodoroSessionType `json:"session_type,omitempty"`
	Status      *PomodoroStatus     `json:"status,omitempty"`
	StartedAfter *time.Time         `json:"started_after,omitempty"`
	StartedBefore *time.Time        `json:"started_before,omitempty"`
	CompletedAfter *time.Time       `json:"completed_after,omitempty"`
	CompletedBefore *time.Time      `json:"completed_before,omitempty"`
	MinDuration *int               `json:"min_duration,omitempty"`
	MaxDuration *int               `json:"max_duration,omitempty"`
	Limit       int                `json:"limit"`
	Offset      int                `json:"offset"`
	SortBy      string             `json:"sort_by"`
	SortOrder   string             `json:"sort_order"`
}

// PomodoroStats represents Pomodoro session statistics
type PomodoroStats struct {
	UserID               string    `json:"user_id"`
	TotalSessions        int       `json:"total_sessions"`
	CompletedSessions    int       `json:"completed_sessions"`
	CancelledSessions    int       `json:"cancelled_sessions"`
	TotalWorkTime        int       `json:"total_work_time"`        // in seconds
	TotalBreakTime       int       `json:"total_break_time"`       // in seconds
	AverageSessionLength float64   `json:"average_session_length"` // in seconds
	CompletionRate       float64   `json:"completion_rate"`        // percentage
	AverageInterruptions float64   `json:"average_interruptions"`
	TotalInterruptions   int       `json:"total_interruptions"`
	CurrentStreak        int       `json:"current_streak"`         // consecutive days with sessions
	LongestStreak        int       `json:"longest_streak"`
	BestFocusScore       float64   `json:"best_focus_score"`
	AverageFocusScore    float64   `json:"average_focus_score"`
	ProductivityScore    float64   `json:"productivity_score"`     // overall score 0-100
	LastSessionAt        *time.Time `json:"last_session_at,omitempty"`
	LastUpdated          time.Time `json:"last_updated"`
}

// PomodoroPattern represents patterns in Pomodoro usage
type PomodoroPattern struct {
	UserID           string `json:"user_id"`
	BestTimeOfDay    string `json:"best_time_of_day"`    // "morning", "afternoon", "evening"
	MostProductiveDay string `json:"most_productive_day"` // day of week
	AverageSessionsPerDay float64 `json:"average_sessions_per_day"`
	PreferredBreakLength  int     `json:"preferred_break_length"` // in seconds
	OptimalWorkLength     int     `json:"optimal_work_length"`    // in seconds
	InterruptionTrends    map[string]int `json:"interruption_trends"` // reason -> count
	SessionDistribution   struct {
		Morning   int `json:"morning"`   // 6-12
		Afternoon int `json:"afternoon"` // 12-18
		Evening   int `json:"evening"`   // 18-22
		Night     int `json:"night"`     // 22-6
	} `json:"session_distribution"`
	LastAnalyzed time.Time `json:"last_analyzed"`
}