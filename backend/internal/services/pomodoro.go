package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
)

// PomodoroRepository defines the interface for Pomodoro session data access
type PomodoroRepository interface {
	Create(session *models.PomodoroSession) (*models.PomodoroSession, error)
	GetByID(id uuid.UUID) (*models.PomodoroSession, error)
	GetByUserID(userID uuid.UUID, filter PomodoroFilter) ([]*models.PomodoroSession, int, error)
	GetActiveSession(userID uuid.UUID) (*models.PomodoroSession, error)
	Update(session *models.PomodoroSession) (*models.PomodoroSession, error)
	Delete(id uuid.UUID) error
	GetSessionsByTaskID(taskID uuid.UUID) ([]*models.PomodoroSession, error)
	GetSessionStats(userID uuid.UUID, startDate, endDate time.Time) (*PomodoroStats, error)
	GetStreakData(userID uuid.UUID) (*StreakData, error)
}

// PomodoroService handles Pomodoro session business logic
type PomodoroService struct {
	repo                PomodoroRepository
	taskService         TaskService
	notificationService *NotificationService
	userService         *UserService
}

// PomodoroFilter represents filters for session queries
type PomodoroFilter struct {
	TaskID      *uuid.UUID                  `json:"task_id,omitempty"`
	SessionType *models.PomodoroSessionType `json:"session_type,omitempty"`
	Status      *models.PomodoroStatus      `json:"status,omitempty"`
	StartDate   *time.Time                  `json:"start_date,omitempty"`
	EndDate     *time.Time                  `json:"end_date,omitempty"`
	Limit       int                         `json:"limit"`
	Offset      int                         `json:"offset"`
	SortBy      string                      `json:"sort_by"`
	SortOrder   string                      `json:"sort_order"`
}

// StartSessionRequest represents a request to start a Pomodoro session
type StartSessionRequest struct {
	TaskID          uuid.UUID                  `json:"task_id" validate:"required"`
	SessionType     models.PomodoroSessionType `json:"session_type" validate:"required,oneof=work short_break long_break"`
	PlannedDuration int                        `json:"planned_duration" validate:"required,min=60,max=7200"` // 1 min to 2 hours
	CustomMessage   string                     `json:"custom_message,omitempty"`
}

// UpdateSessionRequest represents a request to update a session
type UpdateSessionRequest struct {
	Status             *models.PomodoroStatus `json:"status,omitempty" validate:"omitempty,oneof=active paused completed interrupted"`
	ActualDuration     *int                   `json:"actual_duration,omitempty" validate:"omitempty,min=0"`
	InterruptionCount  *int                   `json:"interruption_count,omitempty" validate:"omitempty,min=0"`
	InterruptionReason *string                `json:"interruption_reason,omitempty"`
	Notes              *string                `json:"notes,omitempty" validate:"omitempty,max=1000"`
}

// PomodoroStats represents statistics for Pomodoro sessions
type PomodoroStats struct {
	TotalSessions       int           `json:"total_sessions"`
	CompletedSessions   int           `json:"completed_sessions"`
	InterruptedSessions int           `json:"interrupted_sessions"`
	TotalFocusTime      time.Duration `json:"total_focus_time"`
	AverageSessionTime  time.Duration `json:"average_session_time"`
	CompletionRate      float64       `json:"completion_rate"`
	InterruptionRate    float64       `json:"interruption_rate"`
	TotalBreakTime      time.Duration `json:"total_break_time"`
	ProductivityScore   float64       `json:"productivity_score"`
}

// StreakData represents streak information
type StreakData struct {
	CurrentStreak  int       `json:"current_streak"`
	LongestStreak  int       `json:"longest_streak"`
	LastActiveDate time.Time `json:"last_active_date"`
	StreakGoal     int       `json:"streak_goal"`
}

// SessionTimerInfo represents real-time session information
type SessionTimerInfo struct {
	SessionID       uuid.UUID                  `json:"session_id"`
	TaskID          uuid.UUID                  `json:"task_id"`
	SessionType     models.PomodoroSessionType `json:"session_type"`
	Status          models.PomodoroStatus      `json:"status"`
	PlannedDuration int                        `json:"planned_duration"`
	ElapsedTime     int                        `json:"elapsed_time"`
	RemainingTime   int                        `json:"remaining_time"`
	StartedAt       time.Time                  `json:"started_at"`
	PausedAt        *time.Time                 `json:"paused_at,omitempty"`
	EstimatedEndAt  time.Time                  `json:"estimated_end_at"`
}

// NewPomodoroService creates a new Pomodoro service
func NewPomodoroService(repo PomodoroRepository) *PomodoroService {
	return &PomodoroService{
		repo: repo,
	}
}

// SetDependencies sets dependent services
func (s *PomodoroService) SetDependencies(taskService TaskService, notificationService *NotificationService, userService *UserService) {
	s.taskService = taskService
	s.notificationService = notificationService
	s.userService = userService
}

// StartSession starts a new Pomodoro session
func (s *PomodoroService) StartSession(userID uuid.UUID, req StartSessionRequest) (*models.PomodoroSession, error) {
	// Validate task exists and belongs to user
	if s.taskService != nil {
		task, err := s.taskService.GetTask(req.TaskID, userID)
		if err != nil {
			return nil, fmt.Errorf("invalid task: %w", err)
		}

		// Don't allow sessions on completed tasks
		if task.IsCompleted {
			return nil, models.ErrTaskAlreadyCompleted
		}
	}

	// Check if user already has an active session
	activeSession, err := s.repo.GetActiveSession(userID)
	if err != nil && !models.IsNotFoundError(err) {
		return nil, fmt.Errorf("failed to check active session: %w", err)
	}
	if activeSession != nil {
		return nil, models.ErrUserHasActiveSession
	}

	// Validate session type and duration
	if !req.SessionType.IsValid() {
		return nil, models.ErrInvalidSessionType
	}

	if req.PlannedDuration < 60 || req.PlannedDuration > 7200 {
		return nil, models.ErrInvalidDuration
	}

	// Create session
	session := &models.PomodoroSession{
		ID:              uuid.New(),
		UserID:          userID,
		TaskID:          &req.TaskID,
		SessionType:     req.SessionType,
		Status:          models.PomodoroStatusActive,
		PlannedDuration: req.PlannedDuration,
		StartedAt:       time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// Create session in database
	createdSession, err := s.repo.Create(session)
	if err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	// Schedule completion notification
	if s.notificationService != nil && req.SessionType == models.SessionTypeWork {
		endTime := session.StartedAt.Add(time.Duration(session.PlannedDuration) * time.Second)
		err = s.notificationService.ScheduleSessionCompletion(userID, session.ID, endTime)
		if err != nil {
			fmt.Printf("Warning: failed to schedule completion notification: %v\n", err)
		}
	}

	return createdSession, nil
}

// GetSession retrieves a session by ID
func (s *PomodoroService) GetSession(userID, sessionID uuid.UUID) (*models.PomodoroSession, error) {
	session, err := s.repo.GetByID(sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrSessionNotFound
		}
		return nil, fmt.Errorf("failed to get session: %w", err)
	}

	// Check ownership
	if session.UserID != userID {
		return nil, models.ErrResourceNotOwned
	}

	return session, nil
}

// UpdateSession updates a Pomodoro session
func (s *PomodoroService) UpdateSession(userID, sessionID uuid.UUID, req UpdateSessionRequest) (*models.PomodoroSession, error) {
	// Get existing session
	session, err := s.GetSession(userID, sessionID)
	if err != nil {
		return nil, err
	}

	// Validate state transitions
	if req.Status != nil {
		if !s.isValidStateTransition(session.Status, *req.Status) {
			return nil, models.ErrInvalidStateTransition
		}
	}

	// Apply updates based on status change
	if req.Status != nil {
		switch *req.Status {
		case models.PomodoroStatusCompleted:
			err = s.completeSession(session, req)
			if err != nil {
				return nil, err
			}

		case models.PomodoroStatusPaused:
			if session.Status != models.PomodoroStatusActive {
				return nil, models.ErrInvalidStateTransition
			}
			now := time.Now()
			session.PausedAt = &now
			session.Status = models.PomodoroStatusPaused

		case models.PomodoroStatusActive:
			if session.Status != models.PomodoroStatusPaused {
				return nil, models.ErrInvalidStateTransition
			}
			session.ResumedAt = &time.Time{} // Set to current time
			session.Status = models.PomodoroStatusActive
			session.PausedAt = nil

		case models.PomodoroStatusCancelled:
			err = s.interruptSession(session, req)
			if err != nil {
				return nil, err
			}
		}
	}

	// Apply other updates
	if req.InterruptionCount != nil {
		session.InterruptionCount = *req.InterruptionCount
	}

	if req.InterruptionReason != nil {
		session.InterruptionReason = req.InterruptionReason
	}

	if req.Notes != nil {
		session.Notes = req.Notes
	}

	session.UpdatedAt = time.Now()

	// Update in database
	updatedSession, err := s.repo.Update(session)
	if err != nil {
		return nil, fmt.Errorf("failed to update session: %w", err)
	}

	return updatedSession, nil
}

// GetActiveSession retrieves the user's active session
func (s *PomodoroService) GetActiveSession(userID uuid.UUID) (*models.PomodoroSession, error) {
	session, err := s.repo.GetActiveSession(userID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, nil // No active session
		}
		return nil, fmt.Errorf("failed to get active session: %w", err)
	}

	return session, nil
}

// GetSessionTimer retrieves real-time timer information for an active session
func (s *PomodoroService) GetSessionTimer(userID, sessionID uuid.UUID) (*SessionTimerInfo, error) {
	session, err := s.GetSession(userID, sessionID)
	if err != nil {
		return nil, err
	}

	if session.Status != models.PomodoroStatusActive && session.Status != models.PomodoroStatusPaused {
		return nil, fmt.Errorf("session is not active")
	}

	now := time.Now()
	var elapsedTime time.Duration

	if session.Status == models.PomodoroStatusActive {
		elapsedTime = now.Sub(session.StartedAt)
		// Subtract any paused time if there was a pause
		if session.PausedAt != nil && session.ResumedAt != nil {
			pauseDuration := session.ResumedAt.Sub(*session.PausedAt)
			elapsedTime -= pauseDuration
		}
	} else if session.Status == models.PomodoroStatusPaused && session.PausedAt != nil {
		elapsedTime = session.PausedAt.Sub(session.StartedAt)
		// Subtract any previous paused time
		if session.PausedAt != nil && session.ResumedAt != nil {
			pauseDuration := session.ResumedAt.Sub(*session.PausedAt)
			elapsedTime -= pauseDuration
		}
	}

	plannedDuration := time.Duration(session.PlannedDuration) * time.Second
	remainingTime := plannedDuration - elapsedTime
	if remainingTime < 0 {
		remainingTime = 0
	}

	estimatedEndAt := session.StartedAt.Add(plannedDuration)
	if session.PausedAt != nil && session.ResumedAt != nil {
		pauseDuration := session.ResumedAt.Sub(*session.PausedAt)
		estimatedEndAt = estimatedEndAt.Add(pauseDuration)
	}

	return &SessionTimerInfo{
		SessionID:       session.ID,
		TaskID:          *session.TaskID,
		SessionType:     session.SessionType,
		Status:          session.Status,
		PlannedDuration: session.PlannedDuration,
		ElapsedTime:     int(elapsedTime.Seconds()),
		RemainingTime:   int(remainingTime.Seconds()),
		StartedAt:       session.StartedAt,
		PausedAt:        session.PausedAt,
		EstimatedEndAt:  estimatedEndAt,
	}, nil
}

// ListSessions retrieves sessions for a user with filtering
func (s *PomodoroService) ListSessions(userID uuid.UUID, filter PomodoroFilter) ([]*models.PomodoroSession, int, error) {
	// Set defaults
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.SortBy == "" {
		filter.SortBy = "started_at"
	}
	if filter.SortOrder == "" {
		filter.SortOrder = "desc"
	}

	sessions, total, err := s.repo.GetByUserID(userID, filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list sessions: %w", err)
	}

	return sessions, total, nil
}

// GetSessionsByTask retrieves all sessions for a specific task
func (s *PomodoroService) GetSessionsByTask(userID, taskID uuid.UUID) ([]*models.PomodoroSession, error) {
	// Verify task ownership
	if s.taskService != nil {
		_, err := s.taskService.GetTask(taskID, userID)
		if err != nil {
			return nil, err
		}
	}

	sessions, err := s.repo.GetSessionsByTaskID(taskID)
	if err != nil {
		return nil, fmt.Errorf("failed to get sessions by task: %w", err)
	}

	return sessions, nil
}

// GetStats retrieves Pomodoro statistics for a user
func (s *PomodoroService) GetStats(userID uuid.UUID, startDate, endDate time.Time) (*PomodoroStats, error) {
	stats, err := s.repo.GetSessionStats(userID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get session stats: %w", err)
	}

	return stats, nil
}

// GetStreak retrieves streak information for a user
func (s *PomodoroService) GetStreak(userID uuid.UUID) (*StreakData, error) {
	streak, err := s.repo.GetStreakData(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get streak data: %w", err)
	}

	return streak, nil
}

// SuggestNextSession suggests the next session type based on user's session history
func (s *PomodoroService) SuggestNextSession(userID uuid.UUID) (models.PomodoroSessionType, int, error) {
	// Get user preferences
	var workDuration, shortBreakDuration, longBreakDuration, longBreakInterval int
	if s.userService != nil {
		user, err := s.userService.GetByID(userID.String())
		if err == nil {
			workDuration = user.Preferences.WorkDuration
			shortBreakDuration = user.Preferences.ShortBreakDuration
			longBreakDuration = user.Preferences.LongBreakDuration
			longBreakInterval = user.Preferences.SessionsUntilLongBreak
		}
	}

	// Set defaults if not found
	if workDuration == 0 {
		workDuration = 1500 // 25 minutes
	}
	if shortBreakDuration == 0 {
		shortBreakDuration = 300 // 5 minutes
	}
	if longBreakDuration == 0 {
		longBreakDuration = 900 // 15 minutes
	}
	if longBreakInterval == 0 {
		longBreakInterval = 4
	}

	// Get recent completed work sessions to determine pattern
	filter := PomodoroFilter{
		SessionType: &[]models.PomodoroSessionType{models.SessionTypeWork}[0],
		Status:      &[]models.PomodoroStatus{models.PomodoroStatusCompleted}[0],
		Limit:       longBreakInterval,
		SortBy:      "started_at",
		SortOrder:   "desc",
	}

	recentSessions, _, err := s.repo.GetByUserID(userID, filter)
	if err != nil {
		// Default to work session if can't determine pattern
		return models.SessionTypeWork, workDuration, nil
	}

	// Count recent completed work sessions
	workSessionCount := len(recentSessions)

	// If we've completed the required number of work sessions, suggest long break
	if workSessionCount >= longBreakInterval {
		return models.SessionTypeLongBreak, longBreakDuration, nil
	}

	// Check the last session to determine what to suggest
	if len(recentSessions) > 0 {
		lastSession := recentSessions[0]

		// If last session was work, suggest a break
		if lastSession.SessionType == models.SessionTypeWork {
			if workSessionCount == longBreakInterval-1 {
				return models.SessionTypeLongBreak, longBreakDuration, nil
			}
			return models.SessionTypeShortBreak, shortBreakDuration, nil
		}
	}

	// Default to work session
	return models.SessionTypeWork, workDuration, nil
}

// Helper methods

// completeSession handles session completion logic
func (s *PomodoroService) completeSession(session *models.PomodoroSession, req UpdateSessionRequest) error {
	now := time.Now()
	session.Status = models.PomodoroStatusCompleted
	session.CompletedAt = &now

	// Set actual duration
	if req.ActualDuration != nil {
		session.ActualDuration = req.ActualDuration
	} else {
		// Calculate from start time
		elapsed := now.Sub(session.StartedAt)
		if session.PausedAt != nil && session.ResumedAt != nil {
			pauseDuration := session.ResumedAt.Sub(*session.PausedAt)
			elapsed -= pauseDuration
		}
		actualDuration := int(elapsed.Seconds())
		session.ActualDuration = &actualDuration
	}

	// Update task's completed Pomodoros count if this was a work session
	if session.SessionType == models.SessionTypeWork && s.taskService != nil && session.TaskID != nil {
		task, err := s.taskService.GetTask(*session.TaskID, session.UserID)
		if err == nil {
			// Update task progress to reflect completed pomodoro
			newProgress := task.Progress + 25.0 // Assuming each pomodoro represents 25% progress
			if newProgress > 100.0 {
				newProgress = 100.0
			}
			_, updateErr := s.taskService.UpdateTask(task.ID, session.UserID, &models.TaskUpdateRequest{
				Progress: &newProgress,
			})
			if updateErr != nil {
				fmt.Printf("Warning: failed to update task progress: %v\n", updateErr)
			}
		}
	}

	// Send completion notification
	if s.notificationService != nil {
		err := s.notificationService.SendSessionCompletionNotification(session.UserID, session)
		if err != nil {
			fmt.Printf("Warning: failed to send session completion notification: %v\n", err)
		}
	}

	return nil
}

// interruptSession handles session interruption logic
func (s *PomodoroService) interruptSession(session *models.PomodoroSession, req UpdateSessionRequest) error {
	now := time.Now()
	session.Status = models.PomodoroStatusCancelled
	session.CancelledAt = &now

	// Calculate actual duration up to interruption
	elapsed := now.Sub(session.StartedAt)
	if session.PausedAt != nil && session.ResumedAt != nil {
		pauseDuration := session.ResumedAt.Sub(*session.PausedAt)
		elapsed -= pauseDuration
	}
	actualDuration := int(elapsed.Seconds())
	session.ActualDuration = &actualDuration

	// Increment interruption count if not provided
	if req.InterruptionCount == nil {
		session.InterruptionCount++
	}

	return nil
}

// isValidStateTransition checks if a state transition is valid
func (s *PomodoroService) isValidStateTransition(from, to models.PomodoroStatus) bool {
	validTransitions := map[models.PomodoroStatus][]models.PomodoroStatus{
		models.PomodoroStatusActive: {
			models.PomodoroStatusPaused,
			models.PomodoroStatusCompleted,
			models.PomodoroStatusCancelled,
		},
		models.PomodoroStatusPaused: {
			models.PomodoroStatusActive,
			models.PomodoroStatusCompleted,
			models.PomodoroStatusCancelled,
		},
		models.PomodoroStatusCompleted: {}, // Terminal state
		models.PomodoroStatusCancelled: {}, // Terminal state
	}

	allowedStates, exists := validTransitions[from]
	if !exists {
		return false
	}

	for _, allowed := range allowedStates {
		if allowed == to {
			return true
		}
	}

	return false
}
