package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Task represents a task in the system
type Task struct {
	ID             uuid.UUID           `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID         uuid.UUID           `json:"user_id" gorm:"type:uuid;not null;index"`
	ProjectID      uuid.UUID           `json:"project_id" gorm:"type:uuid;not null;index"` // Required field
	Title          string              `json:"title" gorm:"type:varchar(200);not null"`
	Description    string              `json:"description" gorm:"type:text"`
	DueDate        *time.Time          `json:"due_date,omitempty"`
	IsCompleted    bool                `json:"is_completed" gorm:"not null;default:false"`
	CompletedAt    *time.Time          `json:"completed_at,omitempty"`
	Priority       TaskPriority        `json:"priority" gorm:"type:varchar(20);not null;default:'medium'"`
	Tags           []string            `json:"tags" gorm:"type:text[]"`
	ParentTaskID   *uuid.UUID          `json:"parent_task_id,omitempty" gorm:"type:uuid;index"`
	EstimatedTime  *int                `json:"estimated_time,omitempty"` // in minutes
	ActualTime     *int                `json:"actual_time,omitempty"`    // in minutes
	Progress       float64             `json:"progress" gorm:"not null;default:0"`  // 0-100%
	RecurrenceRule *RecurrenceRule     `json:"recurrence_rule,omitempty" gorm:"type:jsonb"`
	CreatedAt      time.Time           `json:"created_at" gorm:"not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt      time.Time           `json:"updated_at" gorm:"not null;default:CURRENT_TIMESTAMP"`
	SyncVersion    int64               `json:"sync_version" gorm:"not null;default:1"`
	IsDeleted      bool                `json:"is_deleted" gorm:"not null;default:false"`
	DeletedAt      *time.Time          `json:"deleted_at,omitempty"`

	// Relationships
	User         User              `json:"-" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
	Project      Project           `json:"project,omitempty" gorm:"foreignKey:ProjectID;constraint:OnDelete:CASCADE"`
	ParentTask   *Task             `json:"parent_task,omitempty" gorm:"foreignKey:ParentTaskID;constraint:OnDelete:CASCADE"`
	Subtasks     []Task            `json:"subtasks,omitempty" gorm:"foreignKey:ParentTaskID"`
	Notes        []Note            `json:"notes,omitempty" gorm:"foreignKey:TaskID"`
	Reminders    []Reminder        `json:"reminders,omitempty" gorm:"foreignKey:TaskID"`
	Sessions     []PomodoroSession `json:"sessions,omitempty" gorm:"foreignKey:TaskID"`

	// Computed fields (not stored in DB)
	SubtaskCount      int `json:"subtask_count" gorm:"-"`
	CompletedSubtasks int `json:"completed_subtasks" gorm:"-"`
}

// TaskCreateRequest represents the request to create a new task
type TaskCreateRequest struct {
	ProjectID     uuid.UUID `json:"project_id" binding:"required"`
	Title         string    `json:"title" binding:"required,min=1,max=200"`
	Description   string    `json:"description" binding:"max=2000"`
	DueDate       *time.Time `json:"due_date,omitempty"`
	Priority      *TaskPriority `json:"priority,omitempty"`
	Tags          []string  `json:"tags,omitempty"`
	ParentTaskID  *uuid.UUID `json:"parent_task_id,omitempty"`
	EstimatedTime *int      `json:"estimated_time,omitempty" binding:"omitempty,min=1,max=1440"`
}

// TaskUpdateRequest represents the request to update a task
type TaskUpdateRequest struct {
	Title         *string     `json:"title" binding:"omitempty,min=1,max=200"`
	Description   *string     `json:"description" binding:"omitempty,max=2000"`
	DueDate       *time.Time  `json:"due_date,omitempty"`
	Priority      *TaskPriority `json:"priority,omitempty"`
	Tags          []string    `json:"tags,omitempty"`
	IsCompleted   *bool       `json:"is_completed,omitempty"`
	Progress      *float64    `json:"progress,omitempty" binding:"omitempty,min=0,max=100"`
	EstimatedTime *int        `json:"estimated_time,omitempty" binding:"omitempty,min=1,max=1440"`
}

// BeforeCreate sets the ID if not provided
func (t *Task) BeforeCreate(tx *gorm.DB) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	return nil
}

// TableName returns the table name for Task
func (Task) TableName() string {
	return "tasks"
}

// TaskPriority represents task priority levels
type TaskPriority string

const (
	PriorityLow    TaskPriority = "low"
	PriorityMedium TaskPriority = "medium"
	PriorityHigh   TaskPriority = "high"
	PriorityUrgent TaskPriority = "urgent"
)

// TaskStatus represents different task states
type TaskStatus string

const (
	StatusNotStarted TaskStatus = "not_started"
	StatusInProgress TaskStatus = "in_progress"
	StatusCompleted  TaskStatus = "completed"
	StatusCancelled  TaskStatus = "cancelled"
	StatusOnHold     TaskStatus = "on_hold"
)

// NewTask creates a new task
func NewTask(userID, projectID uuid.UUID, title, description string) *Task {
	now := time.Now()
	return &Task{
		ID:          uuid.New(),
		UserID:      userID,
		ProjectID:   projectID,
		Title:       title,
		Description: description,
		IsCompleted: false,
		Priority:    PriorityMedium,
		Tags:        []string{},
		Progress:    0.0,
		CreatedAt:   now,
		UpdatedAt:   now,
		SyncVersion: 1,
		IsDeleted:   false,
	}
}

// NewSubtask creates a new subtask under a parent task
func NewSubtask(userID, projectID uuid.UUID, parentTaskID uuid.UUID, title, description string) *Task {
	task := NewTask(userID, projectID, title, description)
	task.ParentTaskID = &parentTaskID
	return task
}

// Complete marks the task as completed
func (t *Task) Complete() {
	now := time.Now()
	t.IsCompleted = true
	t.CompletedAt = &now
	t.Progress = 100.0
	t.UpdatedAt = now
	t.SyncVersion++
}

// Uncomplete marks the task as not completed
func (t *Task) Uncomplete() {
	t.IsCompleted = false
	t.CompletedAt = nil
	t.Progress = 0.0
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// UpdateProgress updates the task progress and auto-completes if 100%
func (t *Task) UpdateProgress(progress float64) {
	if progress < 0 {
		progress = 0
	}
	if progress > 100 {
		progress = 100
	}

	t.Progress = progress
	t.UpdatedAt = time.Now()
	t.SyncVersion++

	// Auto-complete if progress reaches 100%
	if progress >= 100 && !t.IsCompleted {
		now := time.Now()
		t.IsCompleted = true
		t.CompletedAt = &now
	}

	// Auto-uncomplete if progress drops below 100%
	if progress < 100 && t.IsCompleted {
		t.IsCompleted = false
		t.CompletedAt = nil
	}
}

// CalculateProgressFromSubtasks calculates progress based on completed subtasks
func (t *Task) CalculateProgressFromSubtasks() {
	if t.SubtaskCount == 0 {
		return
	}

	progress := (float64(t.CompletedSubtasks) / float64(t.SubtaskCount)) * 100
	t.UpdateProgress(progress)
}

// SetDueDate sets the due date for the task
func (t *Task) SetDueDate(dueDate time.Time) {
	t.DueDate = &dueDate
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// ClearDueDate removes the due date from the task
func (t *Task) ClearDueDate() {
	t.DueDate = nil
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// SetPriority sets the task priority
func (t *Task) SetPriority(priority TaskPriority) {
	t.Priority = priority
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// AddTag adds a tag to the task
func (t *Task) AddTag(tag string) {
	// Check if tag already exists
	for _, existingTag := range t.Tags {
		if existingTag == tag {
			return
		}
	}

	t.Tags = append(t.Tags, tag)
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// RemoveTag removes a tag from the task
func (t *Task) RemoveTag(tag string) {
	for i, existingTag := range t.Tags {
		if existingTag == tag {
			t.Tags = append(t.Tags[:i], t.Tags[i+1:]...)
			t.UpdatedAt = time.Now()
			t.SyncVersion++
			return
		}
	}
}

// SetTags replaces all tags with new ones
func (t *Task) SetTags(tags []string) {
	t.Tags = tags
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// Update updates the task fields
func (t *Task) Update(title, description *string, dueDate *time.Time, priority *TaskPriority) {
	if title != nil {
		t.Title = *title
	}
	if description != nil {
		t.Description = *description
	}
	if dueDate != nil {
		t.DueDate = dueDate
	}
	if priority != nil {
		t.Priority = *priority
	}

	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// SoftDelete marks the task as deleted
func (t *Task) SoftDelete() {
	now := time.Now()
	t.IsDeleted = true
	t.DeletedAt = &now
	t.UpdatedAt = now
	t.SyncVersion++
}

// Restore restores a soft-deleted task
func (t *Task) Restore() {
	t.IsDeleted = false
	t.DeletedAt = nil
	t.UpdatedAt = time.Now()
	t.SyncVersion++
}

// IsOverdue checks if the task is overdue
func (t *Task) IsOverdue() bool {
	if t.DueDate == nil || t.IsCompleted {
		return false
	}
	return time.Now().After(*t.DueDate)
}

// DaysUntilDue returns the number of days until the task is due
func (t *Task) DaysUntilDue() *int {
	if t.DueDate == nil {
		return nil
	}

	days := int(time.Until(*t.DueDate).Hours() / 24)
	return &days
}

// GetStatus returns the current status of the task
func (t *Task) GetStatus() TaskStatus {
	if t.IsCompleted {
		return StatusCompleted
	}
	if t.IsDeleted {
		return StatusCancelled
	}
	if t.Progress > 0 {
		return StatusInProgress
	}
	return StatusNotStarted
}

// IsSubtask returns true if this task is a subtask
func (t *Task) IsSubtask() bool {
	return t.ParentTaskID != nil
}

// HasSubtasks returns true if this task has subtasks
func (t *Task) HasSubtasks() bool {
	return t.SubtaskCount > 0
}

// Validate validates the task fields
func (t *Task) Validate() error {
	if t.Title == "" {
		return NewValidationError("title", "title is required")
	}
	if len(t.Title) > 200 {
		return NewValidationError("title", "title must be 200 characters or less")
	}
	if len(t.Description) > 2000 {
		return NewValidationError("description", "description must be 2000 characters or less")
	}
	if t.Progress < 0 || t.Progress > 100 {
		return NewValidationError("progress", "progress must be between 0 and 100")
	}
	if len(t.Tags) > 50 {
		return NewValidationError("tags", "maximum 50 tags allowed")
	}

	// Validate priority
	validPriorities := map[TaskPriority]bool{
		PriorityLow:    true,
		PriorityMedium: true,
		PriorityHigh:   true,
		PriorityUrgent: true,
	}
	if !validPriorities[t.Priority] {
		return NewValidationError("priority", "invalid priority value")
	}

	// Validate estimated time
	if t.EstimatedTime != nil && (*t.EstimatedTime < 1 || *t.EstimatedTime > 1440) {
		return NewValidationError("estimated_time", "estimated time must be between 1 and 1440 minutes")
	}

	return nil
}

// MarshalTagsJSON marshals tags to JSON for database storage
func (t *Task) MarshalTagsJSON() ([]byte, error) {
	return json.Marshal(t.Tags)
}

// UnmarshalTagsJSON unmarshals tags from JSON database storage
func (t *Task) UnmarshalTagsJSON(data []byte) error {
	return json.Unmarshal(data, &t.Tags)
}

// MarshalRecurrenceJSON marshals recurrence rule to JSON for database storage
func (t *Task) MarshalRecurrenceJSON() ([]byte, error) {
	if t.RecurrenceRule == nil {
		return nil, nil
	}
	return json.Marshal(t.RecurrenceRule)
}

// UnmarshalRecurrenceJSON unmarshals recurrence rule from JSON database storage
func (t *Task) UnmarshalRecurrenceJSON(data []byte) error {
	if data == nil {
		return nil
	}
	t.RecurrenceRule = &RecurrenceRule{}
	return json.Unmarshal(data, t.RecurrenceRule)
}

// TaskFilter represents filters for task queries
type TaskFilter struct {
	UserID       string        `json:"user_id"`
	IsCompleted  *bool         `json:"is_completed,omitempty"`
	Priority     *TaskPriority `json:"priority,omitempty"`
	Tags         []string      `json:"tags,omitempty"`
	ParentTaskID *string       `json:"parent_task_id,omitempty"`
	ProjectID    *string       `json:"project_id,omitempty"`
	DueBefore    *time.Time    `json:"due_before,omitempty"`
	DueAfter     *time.Time    `json:"due_after,omitempty"`
	CreatedAfter *time.Time    `json:"created_after,omitempty"`
	CreatedBefore *time.Time   `json:"created_before,omitempty"`
	SearchQuery  string        `json:"search_query,omitempty"`
	IsDeleted    bool          `json:"is_deleted"`
	Limit        int           `json:"limit"`
	Offset       int           `json:"offset"`
	SortBy       string        `json:"sort_by"`
	SortOrder    string        `json:"sort_order"`
}

// TaskSummary represents a summary of tasks for a user
type TaskSummary struct {
	UserID             string    `json:"user_id"`
	TotalTasks         int       `json:"total_tasks"`
	CompletedTasks     int       `json:"completed_tasks"`
	PendingTasks       int       `json:"pending_tasks"`
	OverdueTasks       int       `json:"overdue_tasks"`
	TasksDueToday      int       `json:"tasks_due_today"`
	TasksDueThisWeek   int       `json:"tasks_due_this_week"`
	HighPriorityTasks  int       `json:"high_priority_tasks"`
	UrgentTasks        int       `json:"urgent_tasks"`
	AverageCompletion  float64   `json:"average_completion_time"` // in days
	CompletionRate     float64   `json:"completion_rate"`         // percentage
	LastUpdated        time.Time `json:"last_updated"`
}

// TaskProductivity represents productivity metrics for a specific task
type TaskProductivity struct {
	TaskID               string    `json:"task_id"`
	TaskTitle            string    `json:"task_title"`
	TotalPomodoros       int       `json:"total_pomodoros"`
	CompletedPomodoros   int       `json:"completed_pomodoros"`
	TotalWorkTime        int       `json:"total_work_time"`        // in seconds
	AverageSessionLength float64   `json:"average_session_length"` // in seconds
	InterruptionRate     float64   `json:"interruption_rate"`      // percentage
	FocusScore           float64   `json:"focus_score"`            // 0-100
	CompletionDate       *time.Time `json:"completion_date,omitempty"`
	EstimatedVsActual    *float64  `json:"estimated_vs_actual,omitempty"` // ratio
}