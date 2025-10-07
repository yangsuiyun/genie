package validators

import (
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
)

// PomodoroValidators contains validation rules for pomodoro sessions
type PomodoroValidators struct {
	validate *validator.Validate
}

// NewPomodoroValidators creates a new instance of pomodoro validators
func NewPomodoroValidators() *PomodoroValidators {
	validate := validator.New()

	// Register custom validators
	validate.RegisterValidation("valid_session_type", validateSessionType)
	validate.RegisterValidation("valid_session_state", validateSessionState)
	validate.RegisterValidation("valid_duration", validateDuration)
	validate.RegisterValidation("valid_rating", validateRating)

	return &PomodoroValidators{
		validate: validate,
	}
}

// SessionRequest validation struct
type SessionRequest struct {
	TaskID          string `json:"task_id" validate:"omitempty,uuid4"`
	SessionType     string `json:"session_type" validate:"required,valid_session_type"`
	DurationSeconds int    `json:"duration_seconds" validate:"required,valid_duration"`
}

// UpdateSessionRequest validation struct
type UpdateSessionRequest struct {
	State            string     `json:"state" validate:"omitempty,valid_session_state"`
	RemainingSeconds *int       `json:"remaining_seconds" validate:"omitempty,min=0"`
	StartedAt        *time.Time `json:"started_at"`
	PausedAt         *time.Time `json:"paused_at"`
	CompletedAt      *time.Time `json:"completed_at"`
	Rating           *int       `json:"rating" validate:"omitempty,valid_rating"`
	Notes            string     `json:"notes" validate:"omitempty,max=1000"`
}

// SessionListRequest validation struct
type SessionListRequest struct {
	TaskID      string     `json:"task_id" validate:"omitempty,uuid4"`
	Type        string     `json:"type" validate:"omitempty,valid_session_type"`
	State       string     `json:"state" validate:"omitempty,valid_session_state"`
	StartDate   *time.Time `json:"start_date"`
	EndDate     *time.Time `json:"end_date"`
	Page        int        `json:"page" validate:"omitempty,min=1"`
	Limit       int        `json:"limit" validate:"omitempty,min=1,max=100"`
}

// SessionStatsRequest validation struct
type SessionStatsRequest struct {
	StartDate *time.Time `json:"start_date"`
	EndDate   *time.Time `json:"end_date"`
	TaskID    string     `json:"task_id" validate:"omitempty,uuid4"`
	GroupBy   string     `json:"group_by" validate:"omitempty,oneof=day week month"`
}

// PomodoroSettingsRequest validation struct
type PomodoroSettingsRequest struct {
	WorkDurationMinutes      int     `json:"work_duration_minutes" validate:"required,min=1,max=180"`
	ShortBreakDurationMinutes int     `json:"short_break_duration_minutes" validate:"required,min=1,max=60"`
	LongBreakDurationMinutes int     `json:"long_break_duration_minutes" validate:"required,min=1,max=120"`
	LongBreakInterval        int     `json:"long_break_interval" validate:"required,min=2,max=10"`
	AutoStartBreaks          bool    `json:"auto_start_breaks"`
	AutoStartPomodoros       bool    `json:"auto_start_pomodoros"`
	WorkEndSound             string  `json:"work_end_sound" validate:"omitempty,max=100"`
	BreakEndSound            string  `json:"break_end_sound" validate:"omitempty,max=100"`
	SoundVolume              float32 `json:"sound_volume" validate:"omitempty,min=0,max=1"`
	EnableTickingSound       bool    `json:"enable_ticking_sound"`
}

// ValidateSession validates session creation request
func (pv *PomodoroValidators) ValidateSession(req *SessionRequest) error {
	return pv.validate.Struct(req)
}

// ValidateUpdateSession validates session update request
func (pv *PomodoroValidators) ValidateUpdateSession(req *UpdateSessionRequest) error {
	return pv.validate.Struct(req)
}

// ValidateSessionList validates session list request
func (pv *PomodoroValidators) ValidateSessionList(req *SessionListRequest) error {
	err := pv.validate.Struct(req)
	if err != nil {
		return err
	}

	// Additional validation for date range
	if req.StartDate != nil && req.EndDate != nil {
		if req.StartDate.After(*req.EndDate) {
			return validator.ValidationErrors{}
		}
	}

	return nil
}

// ValidateSessionStats validates session stats request
func (pv *PomodoroValidators) ValidateSessionStats(req *SessionStatsRequest) error {
	err := pv.validate.Struct(req)
	if err != nil {
		return err
	}

	// Additional validation for date range
	if req.StartDate != nil && req.EndDate != nil {
		if req.StartDate.After(*req.EndDate) {
			return validator.ValidationErrors{}
		}

		// Limit date range to prevent performance issues
		maxRange := 365 * 24 * time.Hour // 1 year
		if req.EndDate.Sub(*req.StartDate) > maxRange {
			return validator.ValidationErrors{}
		}
	}

	return nil
}

// ValidatePomodoroSettings validates pomodoro settings
func (pv *PomodoroValidators) ValidatePomodoroSettings(req *PomodoroSettingsRequest) error {
	return pv.validate.Struct(req)
}

// Custom validation functions

// validateSessionType validates session type
func validateSessionType(fl validator.FieldLevel) bool {
	sessionType := fl.Field().String()
	validTypes := []string{"work", "short_break", "long_break"}

	for _, valid := range validTypes {
		if sessionType == valid {
			return true
		}
	}
	return false
}

// validateSessionState validates session state
func validateSessionState(fl validator.FieldLevel) bool {
	state := fl.Field().String()
	validStates := []string{"ready", "running", "paused", "completed"}

	for _, valid := range validStates {
		if state == valid {
			return true
		}
	}
	return false
}

// validateDuration validates session duration
func validateDuration(fl validator.FieldLevel) bool {
	duration := fl.Field().Int()

	// Duration should be between 1 minute and 3 hours (in seconds)
	minDuration := 60       // 1 minute
	maxDuration := 3 * 3600 // 3 hours

	return duration >= int64(minDuration) && duration <= int64(maxDuration)
}

// validateRating validates session rating
func validateRating(fl validator.FieldLevel) bool {
	rating := fl.Field().Int()
	return rating >= 1 && rating <= 5
}

// GetValidationErrors returns formatted validation errors for pomodoro
func (pv *PomodoroValidators) GetValidationErrors(err error) map[string]string {
	errors := make(map[string]string)

	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrors {
			fieldName := strings.ToLower(fieldError.Field())

			switch fieldError.Tag() {
			case "required":
				errors[fieldName] = fieldName + " is required"
			case "min":
				errors[fieldName] = fieldName + " must be at least " + fieldError.Param()
			case "max":
				errors[fieldName] = fieldName + " must be at most " + fieldError.Param()
			case "valid_session_type":
				errors[fieldName] = "Session type must be one of: work, short_break, long_break"
			case "valid_session_state":
				errors[fieldName] = "Session state must be one of: ready, running, paused, completed"
			case "valid_duration":
				errors[fieldName] = "Duration must be between 1 minute and 3 hours"
			case "valid_rating":
				errors[fieldName] = "Rating must be between 1 and 5 stars"
			case "uuid4":
				errors[fieldName] = fieldName + " must be a valid UUID"
			case "oneof":
				errors[fieldName] = fieldName + " must be one of the allowed values"
			default:
				errors[fieldName] = fieldName + " is invalid"
			}
		}
	}

	return errors
}

// ValidateSessionTransition validates state transitions
func (pv *PomodoroValidators) ValidateSessionTransition(currentState, newState string) bool {
	validTransitions := map[string][]string{
		"ready":     {"running"},
		"running":   {"paused", "completed"},
		"paused":    {"running", "completed"},
		"completed": {}, // No transitions from completed
	}

	allowedStates, exists := validTransitions[currentState]
	if !exists {
		return false
	}

	for _, allowed := range allowedStates {
		if newState == allowed {
			return true
		}
	}

	return false
}

// ValidateSessionTiming validates session timing constraints
func (pv *PomodoroValidators) ValidateSessionTiming(startedAt, pausedAt, completedAt *time.Time) []string {
	var issues []string

	if startedAt != nil {
		// Started at should not be in the future
		if startedAt.After(time.Now()) {
			issues = append(issues, "Start time cannot be in the future")
		}

		// Started at should not be too far in the past (24 hours)
		if startedAt.Before(time.Now().Add(-24 * time.Hour)) {
			issues = append(issues, "Start time cannot be more than 24 hours ago")
		}
	}

	if pausedAt != nil && startedAt != nil {
		// Paused at should be after started at
		if pausedAt.Before(*startedAt) {
			issues = append(issues, "Pause time must be after start time")
		}
	}

	if completedAt != nil && startedAt != nil {
		// Completed at should be after started at
		if completedAt.Before(*startedAt) {
			issues = append(issues, "Completion time must be after start time")
		}

		// Session duration should be reasonable (not more than 4 hours)
		if completedAt.Sub(*startedAt) > 4*time.Hour {
			issues = append(issues, "Session duration cannot exceed 4 hours")
		}
	}

	return issues
}

// ValidateSessionNotes validates and sanitizes session notes
func (pv *PomodoroValidators) ValidateSessionNotes(notes string) (string, error) {
	// Trim whitespace
	notes = strings.TrimSpace(notes)

	// Check length
	if len(notes) > 1000 {
		return "", validator.ValidationErrors{}
	}

	// Remove control characters except newlines and tabs
	var sanitized strings.Builder
	for _, r := range notes {
		if r >= 32 || r == '\t' || r == '\n' || r == '\r' {
			sanitized.WriteRune(r)
		}
	}

	return sanitized.String(), nil
}

// ValidateDurationSettings validates pomodoro duration settings
func (pv *PomodoroValidators) ValidateDurationSettings(workMinutes, shortBreakMinutes, longBreakMinutes int) []string {
	var issues []string

	// Work duration validation
	if workMinutes < 5 || workMinutes > 180 {
		issues = append(issues, "Work duration must be between 5 and 180 minutes")
	}

	// Short break validation
	if shortBreakMinutes < 1 || shortBreakMinutes > 60 {
		issues = append(issues, "Short break duration must be between 1 and 60 minutes")
	}

	// Long break validation
	if longBreakMinutes < 5 || longBreakMinutes > 120 {
		issues = append(issues, "Long break duration must be between 5 and 120 minutes")
	}

	// Logical validation
	if shortBreakMinutes >= workMinutes {
		issues = append(issues, "Short break should be shorter than work duration")
	}

	if longBreakMinutes <= shortBreakMinutes {
		issues = append(issues, "Long break should be longer than short break")
	}

	return issues
}

// ValidateSessionCount validates session count constraints
func (pv *PomodoroValidators) ValidateSessionCount(dailyCount, weeklyCount int) []string {
	var issues []string

	// Daily session limits (reasonable productivity constraints)
	if dailyCount > 20 {
		issues = append(issues, "Daily session count cannot exceed 20 sessions")
	}

	// Weekly session limits
	if weeklyCount > 100 {
		issues = append(issues, "Weekly session count cannot exceed 100 sessions")
	}

	return issues
}

// ValidateBreakInterval validates long break interval
func (pv *PomodoroValidators) ValidateBreakInterval(interval int) bool {
	return interval >= 2 && interval <= 10
}

// ValidateSoundSettings validates sound configuration
func (pv *PomodoroValidators) ValidateSoundSettings(workSound, breakSound string, volume float32) []string {
	var issues []string

	// Sound name validation
	validSounds := []string{"bell", "chime", "ding", "notification", "gentle", "none"}

	workSoundValid := false
	for _, valid := range validSounds {
		if workSound == valid {
			workSoundValid = true
			break
		}
	}
	if !workSoundValid {
		issues = append(issues, "Invalid work end sound")
	}

	breakSoundValid := false
	for _, valid := range validSounds {
		if breakSound == valid {
			breakSoundValid = true
			break
		}
	}
	if !breakSoundValid {
		issues = append(issues, "Invalid break end sound")
	}

	// Volume validation
	if volume < 0 || volume > 1 {
		issues = append(issues, "Volume must be between 0 and 1")
	}

	return issues
}