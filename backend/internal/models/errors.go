package models

import "errors"

// User validation errors
var (
	ErrEmailRequired         = errors.New("email is required")
	ErrInvalidEmailFormat    = errors.New("invalid email format")
	ErrPasswordRequired      = errors.New("password is required")
	ErrInvalidWorkDuration   = errors.New("work duration must be between 1 minute and 2 hours")
	ErrInvalidBreakDuration  = errors.New("break duration must be between 30 seconds and 30 minutes")
	ErrInvalidBreakInterval  = errors.New("break interval must be between 1 and 10 sessions")
	ErrInvalidReminderTiming = errors.New("reminder timing must be between 0 and 24 hours")
	ErrInvalidThemeMode      = errors.New("theme mode must be 'light', 'dark', or 'system'")
	ErrInvalidFontSize       = errors.New("font size must be 'small', 'medium', or 'large'")
)

// Task validation errors
var (
	ErrTaskTitleRequired     = errors.New("task title is required")
	ErrTaskTitleTooLong      = errors.New("task title must not exceed 200 characters")
	ErrTaskDescriptionTooLong = errors.New("task description must not exceed 2000 characters")
	ErrInvalidDueDate        = errors.New("due date cannot be in the past")
	ErrInvalidPriority       = errors.New("priority must be 'low', 'medium', 'high', or 'urgent'")
	ErrSubtaskDepthLimit     = errors.New("subtasks cannot have their own subtasks (max 2 levels)")
	ErrTaskNotFound          = errors.New("task not found")
	ErrTaskAlreadyCompleted  = errors.New("task is already completed")
)

// PomodoroSession validation errors
var (
	ErrInvalidSessionType     = errors.New("session type must be 'work', 'short_break', or 'long_break'")
	ErrInvalidSessionStatus   = errors.New("session status must be 'active', 'paused', 'completed', or 'interrupted'")
	ErrInvalidDuration        = errors.New("duration must be positive")
	ErrSessionNotActive       = errors.New("session is not active")
	ErrSessionAlreadyCompleted = errors.New("session is already completed")
	ErrInvalidStateTransition = errors.New("invalid session state transition")
	ErrUserHasActiveSession   = errors.New("user already has an active session")
	ErrSessionNotFound        = errors.New("session not found")
)

// Reminder validation errors
var (
	ErrInvalidReminderTime   = errors.New("reminder time must be before task due date")
	ErrReminderInPast        = errors.New("reminder time cannot be in the past")
	ErrInvalidNotificationType = errors.New("notification type must be 'push', 'email', or 'both'")
	ErrReminderAlreadySent   = errors.New("reminder has already been sent")
	ErrReminderNotFound      = errors.New("reminder not found")
)

// RecurrenceRule validation errors
var (
	ErrInvalidFrequency      = errors.New("frequency must be 'daily', 'weekly', 'monthly', or 'custom'")
	ErrInvalidInterval       = errors.New("interval must be positive for custom frequency")
	ErrInvalidDaysOfWeek     = errors.New("days of week must be between 0-6 for weekly frequency")
	ErrInvalidDayOfMonth     = errors.New("day of month must be between 1-31 for monthly frequency")
	ErrInvalidEndCondition   = errors.New("either end_date or max_occurrences can be set, not both")
	ErrRecurrenceRuleNotFound = errors.New("recurrence rule not found")
)

// Note validation errors
var (
	ErrNoteContentRequired = errors.New("note content is required")
	ErrNoteContentTooLong  = errors.New("note content must not exceed 1000 characters")
	ErrNoteNotFound        = errors.New("note not found")
)

// Report validation errors
var (
	ErrInvalidReportPeriod   = errors.New("report period must be 'daily', 'weekly', 'monthly', or 'custom'")
	ErrInvalidDateRange      = errors.New("end date must be after start date")
	ErrDateRangeTooLarge     = errors.New("date range cannot exceed 1 year")
	ErrFutureDateRange       = errors.New("date range cannot be in the future")
	ErrReportNotFound        = errors.New("report not found")
)

// Authentication errors
var (
	ErrInvalidCredentials    = errors.New("invalid email or password")
	ErrEmailAlreadyExists    = errors.New("email already exists")
	ErrUserNotFound          = errors.New("user not found")
	ErrUserNotVerified       = errors.New("user email not verified")
	ErrUserInactive          = errors.New("user account is inactive")
	ErrInvalidToken          = errors.New("invalid or expired token")
	ErrTokenExpired          = errors.New("token has expired")
)

// Authorization errors
var (
	ErrUnauthorized      = errors.New("unauthorized access")
	ErrForbidden         = errors.New("forbidden: insufficient permissions")
	ErrResourceNotOwned  = errors.New("resource does not belong to user")
)

// Database errors
var (
	ErrDatabaseConnection = errors.New("database connection failed")
	ErrTransactionFailed  = errors.New("database transaction failed")
	ErrRecordNotFound     = errors.New("record not found")
	ErrDuplicateKey       = errors.New("duplicate key violation")
	ErrForeignKeyViolation = errors.New("foreign key constraint violation")
)

// Sync errors
var (
	ErrSyncConflict       = errors.New("sync conflict detected")
	ErrInvalidSyncVersion = errors.New("invalid sync version")
	ErrSyncInProgress     = errors.New("sync operation already in progress")
	ErrOfflineMode        = errors.New("operation not allowed in offline mode")
)

// Notification errors
var (
	ErrNotificationFailed   = errors.New("failed to send notification")
	ErrInvalidPushToken     = errors.New("invalid push notification token")
	ErrNotificationDisabled = errors.New("notifications are disabled for this user")
)

// Validation error helper functions

// IsValidationError checks if an error is a validation error
func IsValidationError(err error) bool {
	switch err {
	case ErrEmailRequired, ErrInvalidEmailFormat, ErrPasswordRequired,
		 ErrInvalidWorkDuration, ErrInvalidBreakDuration, ErrInvalidBreakInterval,
		 ErrInvalidReminderTiming, ErrInvalidThemeMode, ErrInvalidFontSize,
		 ErrTaskTitleRequired, ErrTaskTitleTooLong, ErrTaskDescriptionTooLong,
		 ErrInvalidDueDate, ErrInvalidPriority, ErrSubtaskDepthLimit,
		 ErrInvalidSessionType, ErrInvalidSessionStatus, ErrInvalidDuration,
		 ErrInvalidReminderTime, ErrReminderInPast, ErrInvalidNotificationType,
		 ErrInvalidFrequency, ErrInvalidInterval, ErrInvalidDaysOfWeek,
		 ErrInvalidDayOfMonth, ErrInvalidEndCondition, ErrNoteContentRequired,
		 ErrNoteContentTooLong, ErrInvalidReportPeriod, ErrInvalidDateRange,
		 ErrDateRangeTooLarge, ErrFutureDateRange:
		return true
	default:
		return false
	}
}

// IsNotFoundError checks if an error is a "not found" error
func IsNotFoundError(err error) bool {
	switch err {
	case ErrTaskNotFound, ErrSessionNotFound, ErrReminderNotFound,
		 ErrRecurrenceRuleNotFound, ErrNoteNotFound, ErrReportNotFound,
		 ErrUserNotFound, ErrRecordNotFound:
		return true
	default:
		return false
	}
}

// IsAuthenticationError checks if an error is an authentication error
func IsAuthenticationError(err error) bool {
	switch err {
	case ErrInvalidCredentials, ErrUserNotVerified, ErrUserInactive,
		 ErrInvalidToken, ErrTokenExpired:
		return true
	default:
		return false
	}
}

// IsAuthorizationError checks if an error is an authorization error
func IsAuthorizationError(err error) bool {
	switch err {
	case ErrUnauthorized, ErrForbidden, ErrResourceNotOwned:
		return true
	default:
		return false
	}
}

// IsDatabaseError checks if an error is a database error
func IsDatabaseError(err error) bool {
	switch err {
	case ErrDatabaseConnection, ErrTransactionFailed, ErrRecordNotFound,
		 ErrDuplicateKey, ErrForeignKeyViolation:
		return true
	default:
		return false
	}
}