package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Reminder represents a reminder for tasks or events
type Reminder struct {
	ID              string         `json:"id" db:"id"`
	UserID          string         `json:"user_id" db:"user_id"`
	TaskID          *string        `json:"task_id,omitempty" db:"task_id"`
	Title           string         `json:"title" db:"title"`
	Message         string         `json:"message" db:"message"`
	ReminderTime    time.Time      `json:"reminder_time" db:"reminder_time"`
	ReminderType    ReminderType   `json:"reminder_type" db:"reminder_type"`
	DeliveryMethod  DeliveryMethod `json:"delivery_method" db:"delivery_method"`
	IsRecurring     bool           `json:"is_recurring" db:"is_recurring"`
	RecurrenceRule  *RecurrenceRule `json:"recurrence_rule,omitempty" db:"recurrence_rule"`
	Status          ReminderStatus `json:"status" db:"status"`
	SentAt          *time.Time     `json:"sent_at,omitempty" db:"sent_at"`
	AcknowledgedAt  *time.Time     `json:"acknowledged_at,omitempty" db:"acknowledged_at"`
	SnoozeUntil     *time.Time     `json:"snooze_until,omitempty" db:"snooze_until"`
	SnoozeCount     int            `json:"snooze_count" db:"snooze_count"`
	MaxSnoozes      int            `json:"max_snoozes" db:"max_snoozes"`
	Priority        ReminderPriority `json:"priority" db:"priority"`
	Tags            []string       `json:"tags" db:"tags"`
	CreatedAt       time.Time      `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at" db:"updated_at"`
	SyncVersion     int64          `json:"sync_version" db:"sync_version"`
	IsDeleted       bool           `json:"is_deleted" db:"is_deleted"`
	DeletedAt       *time.Time     `json:"deleted_at,omitempty" db:"deleted_at"`

	// Computed fields (not stored in DB)
	TimeTo          string         `json:"time_to" db:"-"`          // Human readable time until reminder
	IsOverdue       bool           `json:"is_overdue" db:"-"`
	CanSnooze       bool           `json:"can_snooze" db:"-"`
	NextOccurrence  *time.Time     `json:"next_occurrence,omitempty" db:"-"`
}

// ReminderType represents different types of reminders
type ReminderType string

const (
	ReminderTypeTaskDue      ReminderType = "task_due"
	ReminderTypeTaskOverdue  ReminderType = "task_overdue"
	ReminderTypeCustom       ReminderType = "custom"
	ReminderTypeSession      ReminderType = "session"
	ReminderTypeBreak        ReminderType = "break"
	ReminderTypeDailyReview  ReminderType = "daily_review"
	ReminderTypeWeeklyReview ReminderType = "weekly_review"
	ReminderTypeGoalCheck    ReminderType = "goal_check"
	ReminderTypeHabit        ReminderType = "habit"
	ReminderTypeMeeting      ReminderType = "meeting"
)

// DeliveryMethod represents how the reminder should be delivered
type DeliveryMethod string

const (
	DeliveryPush        DeliveryMethod = "push"
	DeliveryEmail       DeliveryMethod = "email"
	DeliveryInApp       DeliveryMethod = "in_app"
	DeliveryDesktop     DeliveryMethod = "desktop"
	DeliverySMS         DeliveryMethod = "sms"
	DeliverySlack       DeliveryMethod = "slack"
	DeliveryDiscord     DeliveryMethod = "discord"
	DeliveryWebhook     DeliveryMethod = "webhook"
)

// ReminderStatus represents the current status of a reminder
type ReminderStatus string

const (
	StatusPending      ReminderStatus = "pending"
	StatusSent         ReminderStatus = "sent"
	StatusAcknowledged ReminderStatus = "acknowledged"
	StatusSnoozed      ReminderStatus = "snoozed"
	StatusCancelled    ReminderStatus = "cancelled"
	StatusExpired      ReminderStatus = "expired"
)

// ReminderPriority represents the priority level of a reminder
type ReminderPriority string

const (
	ReminderPriorityLow      ReminderPriority = "low"
	ReminderPriorityMedium   ReminderPriority = "medium"
	ReminderPriorityHigh     ReminderPriority = "high"
	ReminderPriorityCritical ReminderPriority = "critical"
)

// NewReminder creates a new reminder
func NewReminder(userID, title, message string, reminderTime time.Time, reminderType ReminderType, deliveryMethod DeliveryMethod) *Reminder {
	now := time.Now()
	return &Reminder{
		ID:             uuid.New().String(),
		UserID:         userID,
		Title:          title,
		Message:        message,
		ReminderTime:   reminderTime,
		ReminderType:   reminderType,
		DeliveryMethod: deliveryMethod,
		IsRecurring:    false,
		Status:         StatusPending,
		SnoozeCount:    0,
		MaxSnoozes:     3, // Default max snoozes
		Priority:       ReminderPriorityMedium,
		Tags:           []string{},
		CreatedAt:      now,
		UpdatedAt:      now,
		SyncVersion:    1,
		IsDeleted:      false,
	}
}

// NewTaskReminder creates a new reminder for a task
func NewTaskReminder(userID, taskID, title, message string, reminderTime time.Time, deliveryMethod DeliveryMethod) *Reminder {
	reminder := NewReminder(userID, title, message, reminderTime, ReminderTypeTaskDue, deliveryMethod)
	reminder.TaskID = &taskID
	return reminder
}

// NewRecurringReminder creates a new recurring reminder
func NewRecurringReminder(userID, title, message string, reminderTime time.Time, reminderType ReminderType, deliveryMethod DeliveryMethod, recurrenceRule *RecurrenceRule) *Reminder {
	reminder := NewReminder(userID, title, message, reminderTime, reminderType, deliveryMethod)
	reminder.IsRecurring = true
	reminder.RecurrenceRule = recurrenceRule
	return reminder
}

// Send marks the reminder as sent
func (r *Reminder) Send() error {
	if r.Status != StatusPending && r.Status != StatusSnoozed {
		return NewValidationError("status", "can only send pending or snoozed reminders")
	}

	now := time.Now()
	r.Status = StatusSent
	r.SentAt = &now
	r.UpdatedAt = now
	r.SyncVersion++

	return nil
}

// Acknowledge marks the reminder as acknowledged
func (r *Reminder) Acknowledge() error {
	if r.Status != StatusSent {
		return NewValidationError("status", "can only acknowledge sent reminders")
	}

	now := time.Now()
	r.Status = StatusAcknowledged
	r.AcknowledgedAt = &now
	r.UpdatedAt = now
	r.SyncVersion++

	return nil
}

// Snooze snoozes the reminder for a specified duration
func (r *Reminder) Snooze(duration time.Duration) error {
	if r.Status != StatusSent {
		return NewValidationError("status", "can only snooze sent reminders")
	}

	if r.SnoozeCount >= r.MaxSnoozes {
		return NewValidationError("snooze", "maximum number of snoozes reached")
	}

	now := time.Now()
	snoozeUntil := now.Add(duration)

	r.Status = StatusSnoozed
	r.SnoozeUntil = &snoozeUntil
	r.SnoozeCount++
	r.UpdatedAt = now
	r.SyncVersion++

	return nil
}

// Cancel cancels the reminder
func (r *Reminder) Cancel() {
	now := time.Now()
	r.Status = StatusCancelled
	r.UpdatedAt = now
	r.SyncVersion++
}

// Expire marks the reminder as expired
func (r *Reminder) Expire() {
	now := time.Now()
	r.Status = StatusExpired
	r.UpdatedAt = now
	r.SyncVersion++
}

// Reschedule reschedules the reminder to a new time
func (r *Reminder) Reschedule(newTime time.Time) {
	r.ReminderTime = newTime
	r.Status = StatusPending
	r.SnoozeUntil = nil
	r.SnoozeCount = 0
	r.UpdatedAt = time.Now()
	r.SyncVersion++
}

// UpdatePriority updates the reminder priority
func (r *Reminder) UpdatePriority(priority ReminderPriority) {
	r.Priority = priority
	r.UpdatedAt = time.Now()
	r.SyncVersion++
}

// AddTag adds a tag to the reminder
func (r *Reminder) AddTag(tag string) {
	for _, existingTag := range r.Tags {
		if existingTag == tag {
			return
		}
	}

	r.Tags = append(r.Tags, tag)
	r.UpdatedAt = time.Now()
	r.SyncVersion++
}

// RemoveTag removes a tag from the reminder
func (r *Reminder) RemoveTag(tag string) {
	for i, existingTag := range r.Tags {
		if existingTag == tag {
			r.Tags = append(r.Tags[:i], r.Tags[i+1:]...)
			r.UpdatedAt = time.Now()
			r.SyncVersion++
			return
		}
	}
}

// SoftDelete marks the reminder as deleted
func (r *Reminder) SoftDelete() {
	now := time.Now()
	r.IsDeleted = true
	r.DeletedAt = &now
	r.UpdatedAt = now
	r.SyncVersion++
}

// Restore restores a soft-deleted reminder
func (r *Reminder) Restore() {
	r.IsDeleted = false
	r.DeletedAt = nil
	r.UpdatedAt = time.Now()
	r.SyncVersion++
}

// IsDue returns true if the reminder is due
func (r *Reminder) IsDue() bool {
	if r.Status != StatusPending {
		return false
	}

	now := time.Now()

	// Check if snoozed and snooze time has passed
	if r.Status == StatusSnoozed && r.SnoozeUntil != nil {
		return now.After(*r.SnoozeUntil)
	}

	return now.After(r.ReminderTime) || now.Equal(r.ReminderTime)
}

// IsOverdueComputed checks if the reminder is overdue
func (r *Reminder) IsOverdueComputed() bool {
	if r.Status != StatusPending && r.Status != StatusSent {
		return false
	}

	now := time.Now()
	return now.After(r.ReminderTime.Add(24 * time.Hour)) // Overdue after 24 hours
}

// CanSnoozeComputed checks if the reminder can be snoozed
func (r *Reminder) CanSnoozeComputed() bool {
	return r.Status == StatusSent && r.SnoozeCount < r.MaxSnoozes
}

// GetTimeTo returns a human-readable string for time until reminder
func (r *Reminder) GetTimeTo() string {
	now := time.Now()

	if r.ReminderTime.Before(now) {
		duration := now.Sub(r.ReminderTime)
		return formatDurationPast(duration)
	}

	duration := r.ReminderTime.Sub(now)
	return formatDurationFuture(duration)
}

// UpdateComputedFields updates computed fields
func (r *Reminder) UpdateComputedFields() {
	r.TimeTo = r.GetTimeTo()
	r.IsOverdue = r.IsOverdueComputed()
	r.CanSnooze = r.CanSnoozeComputed()

	if r.IsRecurring && r.RecurrenceRule != nil {
		// Calculate next occurrence for recurring reminders
		// This would use the RecurrenceRule logic
		nextOccurrence := r.calculateNextOccurrence()
		r.NextOccurrence = nextOccurrence
	}
}

// calculateNextOccurrence calculates the next occurrence for recurring reminders
func (r *Reminder) calculateNextOccurrence() *time.Time {
	if !r.IsRecurring || r.RecurrenceRule == nil {
		return nil
	}

	// This would implement the recurrence calculation logic
	// For now, we'll return a placeholder
	next := r.ReminderTime.Add(24 * time.Hour) // Daily recurrence example
	return &next
}

// Validate validates the reminder fields
func (r *Reminder) Validate() error {
	if r.Title == "" {
		return NewValidationError("title", "title is required")
	}
	if len(r.Title) > 200 {
		return NewValidationError("title", "title must be 200 characters or less")
	}
	if len(r.Message) > 1000 {
		return NewValidationError("message", "message must be 1000 characters or less")
	}
	if len(r.Tags) > 10 {
		return NewValidationError("tags", "maximum 10 tags allowed")
	}

	// Validate reminder type
	validTypes := map[ReminderType]bool{
		ReminderTypeTaskDue:      true,
		ReminderTypeTaskOverdue:  true,
		ReminderTypeCustom:       true,
		ReminderTypeSession:      true,
		ReminderTypeBreak:        true,
		ReminderTypeDailyReview:  true,
		ReminderTypeWeeklyReview: true,
		ReminderTypeGoalCheck:    true,
		ReminderTypeHabit:        true,
		ReminderTypeMeeting:      true,
	}
	if !validTypes[r.ReminderType] {
		return NewValidationError("reminder_type", "invalid reminder type")
	}

	// Validate delivery method
	validMethods := map[DeliveryMethod]bool{
		DeliveryPush:    true,
		DeliveryEmail:   true,
		DeliveryInApp:   true,
		DeliveryDesktop: true,
		DeliverySMS:     true,
		DeliverySlack:   true,
		DeliveryDiscord: true,
		DeliveryWebhook: true,
	}
	if !validMethods[r.DeliveryMethod] {
		return NewValidationError("delivery_method", "invalid delivery method")
	}

	// Validate priority
	validPriorities := map[ReminderPriority]bool{
		ReminderPriorityLow:      true,
		ReminderPriorityMedium:   true,
		ReminderPriorityHigh:     true,
		ReminderPriorityCritical: true,
	}
	if !validPriorities[r.Priority] {
		return NewValidationError("priority", "invalid priority")
	}

	// Validate max snoozes
	if r.MaxSnoozes < 0 || r.MaxSnoozes > 10 {
		return NewValidationError("max_snoozes", "max snoozes must be between 0 and 10")
	}

	// Validate reminder time is not too far in the past
	if r.ReminderTime.Before(time.Now().Add(-30 * 24 * time.Hour)) {
		return NewValidationError("reminder_time", "reminder time cannot be more than 30 days in the past")
	}

	return nil
}

// formatDurationPast formats a duration for past times
func formatDurationPast(d time.Duration) string {
	if d < time.Minute {
		return "just now"
	}
	if d < time.Hour {
		minutes := int(d.Minutes())
		if minutes == 1 {
			return "1 minute ago"
		}
		return fmt.Sprintf("%d minutes ago", minutes)
	}
	if d < 24*time.Hour {
		hours := int(d.Hours())
		if hours == 1 {
			return "1 hour ago"
		}
		return fmt.Sprintf("%d hours ago", hours)
	}
	days := int(d.Hours() / 24)
	if days == 1 {
		return "1 day ago"
	}
	return fmt.Sprintf("%d days ago", days)
}

// formatDurationFuture formats a duration for future times
func formatDurationFuture(d time.Duration) string {
	if d < time.Minute {
		return "in less than a minute"
	}
	if d < time.Hour {
		minutes := int(d.Minutes())
		if minutes == 1 {
			return "in 1 minute"
		}
		return fmt.Sprintf("in %d minutes", minutes)
	}
	if d < 24*time.Hour {
		hours := int(d.Hours())
		if hours == 1 {
			return "in 1 hour"
		}
		return fmt.Sprintf("in %d hours", hours)
	}
	days := int(d.Hours() / 24)
	if days == 1 {
		return "in 1 day"
	}
	return fmt.Sprintf("in %d days", days)
}

// ReminderFilter represents filters for reminder queries
type ReminderFilter struct {
	UserID         string           `json:"user_id"`
	TaskID         *string          `json:"task_id,omitempty"`
	ReminderType   *ReminderType    `json:"reminder_type,omitempty"`
	DeliveryMethod *DeliveryMethod  `json:"delivery_method,omitempty"`
	Status         *ReminderStatus  `json:"status,omitempty"`
	Priority       *ReminderPriority `json:"priority,omitempty"`
	IsRecurring    *bool            `json:"is_recurring,omitempty"`
	DueBefore      *time.Time       `json:"due_before,omitempty"`
	DueAfter       *time.Time       `json:"due_after,omitempty"`
	Tags           []string         `json:"tags,omitempty"`
	IsDeleted      bool             `json:"is_deleted"`
	Limit          int              `json:"limit"`
	Offset         int              `json:"offset"`
	SortBy         string           `json:"sort_by"`
	SortOrder      string           `json:"sort_order"`
}

// ReminderSummary represents a summary of reminders for a user
type ReminderSummary struct {
	UserID            string                      `json:"user_id"`
	TotalReminders    int                         `json:"total_reminders"`
	PendingReminders  int                         `json:"pending_reminders"`
	OverdueReminders  int                         `json:"overdue_reminders"`
	SnoozedReminders  int                         `json:"snoozed_reminders"`
	TodaysReminders   int                         `json:"todays_reminders"`
	ThisWeekReminders int                         `json:"this_week_reminders"`
	RemindersByType   map[ReminderType]int        `json:"reminders_by_type"`
	RemindersByPriority map[ReminderPriority]int  `json:"reminders_by_priority"`
	DeliveryStats     map[DeliveryMethod]int      `json:"delivery_stats"`
	AcknowledgmentRate float64                   `json:"acknowledgment_rate"`
	SnoozeRate        float64                    `json:"snooze_rate"`
	LastUpdated       time.Time                  `json:"last_updated"`
}

// ReminderDeliveryLog represents a log of reminder delivery attempts
type ReminderDeliveryLog struct {
	ID          string         `json:"id" db:"id"`
	ReminderID  string         `json:"reminder_id" db:"reminder_id"`
	DeliveryMethod DeliveryMethod `json:"delivery_method" db:"delivery_method"`
	Status      string         `json:"status" db:"status"` // "sent", "failed", "pending"
	AttemptedAt time.Time      `json:"attempted_at" db:"attempted_at"`
	DeliveredAt *time.Time     `json:"delivered_at,omitempty" db:"delivered_at"`
	ErrorMessage *string       `json:"error_message,omitempty" db:"error_message"`
	RetryCount  int            `json:"retry_count" db:"retry_count"`
	MaxRetries  int            `json:"max_retries" db:"max_retries"`
	NextRetryAt *time.Time     `json:"next_retry_at,omitempty" db:"next_retry_at"`
	Metadata    map[string]interface{} `json:"metadata" db:"metadata"` // Platform-specific delivery data
}