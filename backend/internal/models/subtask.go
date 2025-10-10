package models

import (
	"time"

	"github.com/google/uuid"
)

// Subtask represents a subtask within a parent task
// Note: Subtasks are implemented as regular Tasks with ParentTaskID set
// This file provides convenience functions and additional subtask-specific logic

// SubtaskService provides subtask-specific operations
type SubtaskService struct{}

// CreateSubtask creates a new subtask under a parent task
func (s *SubtaskService) CreateSubtask(userID, parentTaskID uuid.UUID, title, description string) *Task {
	subtask := NewTask(userID, parentTaskID, title, description)
	subtask.ParentTaskID = &parentTaskID
	return subtask
}

// ValidateSubtaskCreation validates that a subtask can be created under the parent
func (s *SubtaskService) ValidateSubtaskCreation(parentTask *Task, userID uuid.UUID) error {
	// Check if user owns the parent task
	if parentTask.UserID != userID {
		return NewValidationError("parent_task", "cannot create subtask under task you don't own")
	}

	// Check if parent task is not deleted
	if parentTask.IsDeleted {
		return NewValidationError("parent_task", "cannot create subtask under deleted task")
	}

	// Check if parent task is itself a subtask (prevent deep nesting)
	if parentTask.IsSubtask() {
		return NewValidationError("parent_task", "cannot create subtask under another subtask")
	}

	// Check if parent task is completed
	if parentTask.IsCompleted {
		return NewValidationError("parent_task", "cannot create subtask under completed task")
	}

	return nil
}

// UpdateParentProgress updates the parent task's progress based on subtask completion
func (s *SubtaskService) UpdateParentProgress(parentTask *Task, subtasks []Task) {
	if len(subtasks) == 0 {
		parentTask.Progress = 0
		return
	}

	completedCount := 0
	totalProgress := 0.0

	for _, subtask := range subtasks {
		if !subtask.IsDeleted {
			if subtask.IsCompleted {
				completedCount++
				totalProgress += 100.0
			} else {
				totalProgress += subtask.Progress
			}
		}
	}

	// Calculate weighted progress
	averageProgress := totalProgress / float64(len(subtasks))
	parentTask.UpdateProgress(averageProgress)

	// Update subtask counts
	parentTask.SubtaskCount = len(subtasks)
	parentTask.CompletedSubtasks = completedCount
}

// CompleteSubtask completes a subtask and updates parent progress
func (s *SubtaskService) CompleteSubtask(subtask *Task, parentTask *Task, allSubtasks []Task) error {
	if !subtask.IsSubtask() {
		return NewValidationError("subtask", "task is not a subtask")
	}

	// Complete the subtask
	subtask.Complete()

	// Update parent progress
	s.UpdateParentProgress(parentTask, allSubtasks)

	return nil
}

// UncompleteSubtask uncompletes a subtask and updates parent progress
func (s *SubtaskService) UncompleteSubtask(subtask *Task, parentTask *Task, allSubtasks []Task) error {
	if !subtask.IsSubtask() {
		return NewValidationError("subtask", "task is not a subtask")
	}

	// Uncomplete the subtask
	subtask.Uncomplete()

	// Update parent progress
	s.UpdateParentProgress(parentTask, allSubtasks)

	return nil
}

// DeleteSubtask soft deletes a subtask and updates parent progress
func (s *SubtaskService) DeleteSubtask(subtask *Task, parentTask *Task, allSubtasks []Task) error {
	if !subtask.IsSubtask() {
		return NewValidationError("subtask", "task is not a subtask")
	}

	// Soft delete the subtask
	subtask.SoftDelete()

	// Filter out deleted subtasks for progress calculation
	activeSubtasks := make([]Task, 0)
	for _, st := range allSubtasks {
		if !st.IsDeleted {
			activeSubtasks = append(activeSubtasks, st)
		}
	}

	// Update parent progress
	s.UpdateParentProgress(parentTask, activeSubtasks)

	return nil
}

// ReorderSubtasks reorders subtasks within a parent task
func (s *SubtaskService) ReorderSubtasks(subtaskIDs []string, userID string) error {
	// Validate that all subtasks belong to the same parent and user
	// This would typically involve database queries to validate ownership
	// For now, we'll define the interface

	if len(subtaskIDs) == 0 {
		return NewValidationError("subtasks", "no subtasks to reorder")
	}

	// In a real implementation, this would:
	// 1. Validate all subtasks exist and belong to user
	// 2. Validate all subtasks belong to same parent
	// 3. Update sort_order field in database

	return nil
}

// SubtaskSummary represents a summary of subtasks for a parent task
type SubtaskSummary struct {
	ParentTaskID      string    `json:"parent_task_id"`
	TotalSubtasks     int       `json:"total_subtasks"`
	CompletedSubtasks int       `json:"completed_subtasks"`
	PendingSubtasks   int       `json:"pending_subtasks"`
	DeletedSubtasks   int       `json:"deleted_subtasks"`
	CompletionRate    float64   `json:"completion_rate"`  // percentage
	AverageProgress   float64   `json:"average_progress"` // 0-100
	LastUpdated       time.Time `json:"last_updated"`
}

// SubtaskStats represents detailed statistics for subtasks
type SubtaskStats struct {
	ParentTaskID        string        `json:"parent_task_id"`
	SubtaskBreakdown    []TaskSummary `json:"subtask_breakdown"`
	ProductivityMetrics struct {
		AverageCompletionTime float64 `json:"average_completion_time"` // in days
		FastestCompletion     float64 `json:"fastest_completion"`      // in days
		SlowestCompletion     float64 `json:"slowest_completion"`      // in days
		CompletionPattern     string  `json:"completion_pattern"`      // "sequential", "parallel", "mixed"
	} `json:"productivity_metrics"`
	TimeDistribution struct {
		MorningCompletions   int `json:"morning_completions"`   // 6-12
		AfternoonCompletions int `json:"afternoon_completions"` // 12-18
		EveningCompletions   int `json:"evening_completions"`   // 18-22
		NightCompletions     int `json:"night_completions"`     // 22-6
	} `json:"time_distribution"`
	LastAnalyzed time.Time `json:"last_analyzed"`
}

// SubtaskTemplate represents a template for creating subtasks
type SubtaskTemplate struct {
	ID               string `json:"id" db:"id"`
	UserID           string `json:"user_id" db:"user_id"`
	Name             string `json:"name" db:"name"`
	Description      string `json:"description" db:"description"`
	SubtaskTemplates []struct {
		Title         string       `json:"title"`
		Description   string       `json:"description"`
		Priority      TaskPriority `json:"priority"`
		EstimatedTime *int         `json:"estimated_time,omitempty"`
	} `json:"subtask_templates" db:"subtask_templates"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
	UsageCount int       `json:"usage_count" db:"usage_count"`
}

// NewSubtaskTemplate creates a new subtask template
func NewSubtaskTemplate(userID, name, description string) *SubtaskTemplate {
	now := time.Now()
	return &SubtaskTemplate{
		ID:          uuid.New().String(),
		UserID:      userID,
		Name:        name,
		Description: description,
		CreatedAt:   now,
		UpdatedAt:   now,
		UsageCount:  0,
	}
}

// ApplyTemplate applies a subtask template to create subtasks under a parent task
func (s *SubtaskService) ApplyTemplate(template *SubtaskTemplate, parentTaskID, userID uuid.UUID) ([]Task, error) {
	var subtasks []Task

	for _, subtaskTemplate := range template.SubtaskTemplates {
		subtask := s.CreateSubtask(userID, parentTaskID, subtaskTemplate.Title, subtaskTemplate.Description)
		subtask.Priority = subtaskTemplate.Priority
		subtask.EstimatedTime = subtaskTemplate.EstimatedTime
		subtasks = append(subtasks, *subtask)
	}

	// Increment template usage count
	template.UsageCount++
	template.UpdatedAt = time.Now()

	return subtasks, nil
}

// SubtaskFilter represents filters for subtask queries
type SubtaskFilter struct {
	ParentTaskID string        `json:"parent_task_id"`
	UserID       string        `json:"user_id"`
	IsCompleted  *bool         `json:"is_completed,omitempty"`
	Priority     *TaskPriority `json:"priority,omitempty"`
	IsDeleted    bool          `json:"is_deleted"`
	Limit        int           `json:"limit"`
	Offset       int           `json:"offset"`
	SortBy       string        `json:"sort_by"`
	SortOrder    string        `json:"sort_order"`
}

// SubtaskProgress represents progress tracking for subtasks
type SubtaskProgress struct {
	SubtaskID     string     `json:"subtask_id"`
	ParentTaskID  string     `json:"parent_task_id"`
	Progress      float64    `json:"progress"`
	StartedAt     *time.Time `json:"started_at,omitempty"`
	CompletedAt   *time.Time `json:"completed_at,omitempty"`
	EstimatedTime *int       `json:"estimated_time,omitempty"` // in minutes
	ActualTime    *int       `json:"actual_time,omitempty"`    // in minutes
	Blockers      []string   `json:"blockers,omitempty"`       // list of blocking issues
	Notes         string     `json:"notes,omitempty"`
	LastUpdated   time.Time  `json:"last_updated"`
}

// SubtaskDependency represents dependencies between subtasks
type SubtaskDependency struct {
	ID              string                `json:"id" db:"id"`
	DependentTaskID string                `json:"dependent_task_id" db:"dependent_task_id"`   // subtask that depends
	DependsOnTaskID string                `json:"depends_on_task_id" db:"depends_on_task_id"` // subtask being depended on
	DependencyType  SubtaskDependencyType `json:"dependency_type" db:"dependency_type"`
	CreatedAt       time.Time             `json:"created_at" db:"created_at"`
	CreatedBy       string                `json:"created_by" db:"created_by"`
}

// SubtaskDependencyType represents the type of dependency between subtasks
type SubtaskDependencyType string

const (
	DependencyFinishToStart  SubtaskDependencyType = "finish_to_start"  // Must finish before dependent can start
	DependencyStartToStart   SubtaskDependencyType = "start_to_start"   // Must start before dependent can start
	DependencyFinishToFinish SubtaskDependencyType = "finish_to_finish" // Must finish before dependent can finish
	DependencyStartToFinish  SubtaskDependencyType = "start_to_finish"  // Must start before dependent can finish
)

// ValidateDependency validates that a dependency can be created
func (s *SubtaskService) ValidateDependency(dependentTask, dependsOnTask *Task) error {
	// Both tasks must be subtasks of the same parent
	if dependentTask.ParentTaskID == nil || dependsOnTask.ParentTaskID == nil {
		return NewValidationError("dependency", "dependencies can only be created between subtasks")
	}

	if *dependentTask.ParentTaskID != *dependsOnTask.ParentTaskID {
		return NewValidationError("dependency", "dependencies can only be created between subtasks of the same parent")
	}

	// Cannot depend on itself
	if dependentTask.ID == dependsOnTask.ID {
		return NewValidationError("dependency", "subtask cannot depend on itself")
	}

	// Cannot create circular dependencies (this would require cycle detection)
	// For now, we'll just validate the basic cases

	return nil
}
