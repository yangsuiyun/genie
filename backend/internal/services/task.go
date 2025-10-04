package services

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"backend/internal/models"
)

// TaskRepository defines the interface for task data access
type TaskRepository interface {
	Create(task *models.Task) (*models.Task, error)
	GetByID(id uuid.UUID) (*models.Task, error)
	GetByUserID(userID uuid.UUID, filter models.TaskFilter) ([]*models.Task, int, error)
	Update(task *models.Task) (*models.Task, error)
	Delete(id uuid.UUID) error
	SoftDelete(id uuid.UUID) error
	GetSubtasks(parentID uuid.UUID) ([]*models.Task, error)
	GetTaskStats(userID uuid.UUID) (*models.TaskStats, error)
	BulkUpdate(tasks []*models.Task) error
	SearchTasks(userID uuid.UUID, query string, limit int) ([]*models.Task, error)
	GetOverdueTasks(userID uuid.UUID) ([]*models.Task, error)
	GetTasksDueToday(userID uuid.UUID) ([]*models.Task, error)
	GetTasksDueThisWeek(userID uuid.UUID) ([]*models.Task, error)
}

// TaskService handles task-related business logic
type TaskService struct {
	repo               TaskRepository
	reminderService    *ReminderService
	notificationService *NotificationService
	syncService        *SyncService
}

// CreateTaskRequest represents a task creation request
type CreateTaskRequest struct {
	Title              string     `json:"title" validate:"required,max=200"`
	Description        string     `json:"description" validate:"max=2000"`
	DueDate            *time.Time `json:"due_date,omitempty"`
	DueTime            *time.Time `json:"due_time,omitempty"`
	Priority           models.Priority `json:"priority" validate:"oneof=low medium high urgent"`
	EstimatedPomodoros int        `json:"estimated_pomodoros" validate:"min=0,max=50"`
	Tags               []string   `json:"tags" validate:"max=20"`
	ParentTaskID       *uuid.UUID `json:"parent_task_id,omitempty"`
	RecurrenceRuleID   *uuid.UUID `json:"recurrence_rule_id,omitempty"`
}

// UpdateTaskRequest represents a task update request
type UpdateTaskRequest struct {
	Title              *string           `json:"title,omitempty" validate:"omitempty,max=200"`
	Description        *string           `json:"description,omitempty" validate:"omitempty,max=2000"`
	DueDate            *time.Time        `json:"due_date,omitempty"`
	DueTime            *time.Time        `json:"due_time,omitempty"`
	Priority           *models.Priority  `json:"priority,omitempty" validate:"omitempty,oneof=low medium high urgent"`
	EstimatedPomodoros *int              `json:"estimated_pomodoros,omitempty" validate:"omitempty,min=0,max=50"`
	Tags               *[]string         `json:"tags,omitempty" validate:"omitempty,max=20"`
	IsCompleted        *bool             `json:"is_completed,omitempty"`
}

// TaskListResponse represents the response for task listing
type TaskListResponse struct {
	Tasks      []*models.Task `json:"tasks"`
	Total      int            `json:"total"`
	Page       int            `json:"page"`
	PerPage    int            `json:"per_page"`
	TotalPages int            `json:"total_pages"`
}

// NewTaskService creates a new task service
func NewTaskService(repo TaskRepository) *TaskService {
	return &TaskService{
		repo: repo,
		// Note: These will be injected later to avoid circular dependencies
		// reminderService: reminderService,
		// notificationService: notificationService,
		// syncService: syncService,
	}
}

// SetDependencies sets the dependent services (to avoid circular dependencies)
func (s *TaskService) SetDependencies(reminderService *ReminderService, notificationService *NotificationService, syncService *SyncService) {
	s.reminderService = reminderService
	s.notificationService = notificationService
	s.syncService = syncService
}

// Create creates a new task
func (s *TaskService) Create(userID uuid.UUID, req CreateTaskRequest) (*models.Task, error) {
	// Validate input
	if req.Title == "" {
		return nil, models.ErrTaskTitleRequired
	}

	if len(req.Title) > 200 {
		return nil, models.ErrTaskTitleTooLong
	}

	if len(req.Description) > 2000 {
		return nil, models.ErrTaskDescriptionTooLong
	}

	// Validate due date is in the future
	if req.DueDate != nil && req.DueDate.Before(time.Now()) {
		return nil, models.ErrInvalidDueDate
	}

	// Validate priority
	if req.Priority != "" && !req.Priority.IsValid() {
		return nil, models.ErrInvalidPriority
	}

	// If parent task is specified, validate it exists and user owns it
	if req.ParentTaskID != nil {
		parentTask, err := s.repo.GetByID(*req.ParentTaskID)
		if err != nil {
			if models.IsNotFoundError(err) {
				return nil, models.ErrTaskNotFound
			}
			return nil, fmt.Errorf("failed to get parent task: %w", err)
		}

		// Check ownership
		if parentTask.UserID != userID {
			return nil, models.ErrResourceNotOwned
		}

		// Check depth limit (max 2 levels)
		if parentTask.ParentTaskID != nil {
			return nil, models.ErrSubtaskDepthLimit
		}
	}

	// Create task
	task := models.NewTask(userID, req.Title)
	task.Description = req.Description
	task.DueDate = req.DueDate
	task.DueTime = req.DueTime
	task.ParentTaskID = req.ParentTaskID
	task.RecurrenceRuleID = req.RecurrenceRuleID
	task.EstimatedPomodoros = req.EstimatedPomodoros

	if req.Priority != "" {
		task.Priority = req.Priority
	}

	if req.Tags != nil {
		task.Tags = req.Tags
	}

	// Set recurring flag
	if req.RecurrenceRuleID != nil {
		task.IsRecurring = true
	}

	// Create task in database
	createdTask, err := s.repo.Create(task)
	if err != nil {
		return nil, fmt.Errorf("failed to create task: %w", err)
	}

	// Create automatic reminders if due date is set
	if createdTask.DueDate != nil && s.reminderService != nil {
		err = s.createAutomaticReminders(createdTask)
		if err != nil {
			// Log error but don't fail task creation
			fmt.Printf("Warning: failed to create automatic reminders: %v\n", err)
		}
	}

	// Trigger sync if sync service is available
	if s.syncService != nil {
		s.syncService.NotifyTaskChange(createdTask.ID, "created")
	}

	return createdTask, nil
}

// GetByID retrieves a task by ID
func (s *TaskService) GetByID(userID, taskID uuid.UUID) (*models.Task, error) {
	task, err := s.repo.GetByID(taskID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrTaskNotFound
		}
		return nil, fmt.Errorf("failed to get task: %w", err)
	}

	// Check ownership
	if task.UserID != userID {
		return nil, models.ErrResourceNotOwned
	}

	return task, nil
}

// List retrieves tasks for a user with filtering and pagination
func (s *TaskService) List(userID uuid.UUID, filter models.TaskFilter) (*TaskListResponse, error) {
	// Set default values
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100 // Max limit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	if filter.SortBy == "" {
		filter.SortBy = "created_at"
	}
	if filter.SortOrder == "" {
		filter.SortOrder = "desc"
	}

	tasks, total, err := s.repo.GetByUserID(userID, filter)
	if err != nil {
		return nil, fmt.Errorf("failed to list tasks: %w", err)
	}

	// Calculate pagination
	page := (filter.Offset / filter.Limit) + 1
	totalPages := (total + filter.Limit - 1) / filter.Limit

	return &TaskListResponse{
		Tasks:      tasks,
		Total:      total,
		Page:       page,
		PerPage:    filter.Limit,
		TotalPages: totalPages,
	}, nil
}

// Update updates a task
func (s *TaskService) Update(userID, taskID uuid.UUID, req UpdateTaskRequest) (*models.Task, error) {
	// Get existing task
	task, err := s.GetByID(userID, taskID)
	if err != nil {
		return nil, err
	}

	// Check if task is already completed and being modified
	if task.IsCompleted && req.IsCompleted != nil && !*req.IsCompleted {
		// Allow uncompleting
	} else if task.IsCompleted && req.IsCompleted == nil {
		return nil, models.ErrTaskAlreadyCompleted
	}

	// Apply updates
	if req.Title != nil {
		if *req.Title == "" {
			return nil, models.ErrTaskTitleRequired
		}
		if len(*req.Title) > 200 {
			return nil, models.ErrTaskTitleTooLong
		}
		task.Title = *req.Title
	}

	if req.Description != nil {
		if len(*req.Description) > 2000 {
			return nil, models.ErrTaskDescriptionTooLong
		}
		task.Description = *req.Description
	}

	if req.DueDate != nil {
		if req.DueDate.Before(time.Now()) && !task.IsCompleted {
			return nil, models.ErrInvalidDueDate
		}
		task.DueDate = req.DueDate
	}

	if req.DueTime != nil {
		task.DueTime = req.DueTime
	}

	if req.Priority != nil {
		if !req.Priority.IsValid() {
			return nil, models.ErrInvalidPriority
		}
		task.Priority = *req.Priority
	}

	if req.EstimatedPomodoros != nil {
		if *req.EstimatedPomodoros < 0 {
			return nil, models.ErrInvalidDuration
		}
		task.EstimatedPomodoros = *req.EstimatedPomodoros
	}

	if req.Tags != nil {
		task.Tags = *req.Tags
	}

	if req.IsCompleted != nil {
		if *req.IsCompleted {
			task.Complete()
		} else {
			task.Uncomplete()
		}
	}

	// Update sync version
	task.UpdateSyncVersion("api") // TODO: Get actual device ID

	// Update task in database
	updatedTask, err := s.repo.Update(task)
	if err != nil {
		return nil, fmt.Errorf("failed to update task: %w", err)
	}

	// Handle reminders if due date changed
	if req.DueDate != nil && s.reminderService != nil {
		err = s.updateTaskReminders(updatedTask)
		if err != nil {
			fmt.Printf("Warning: failed to update reminders: %v\n", err)
		}
	}

	// Trigger sync
	if s.syncService != nil {
		s.syncService.NotifyTaskChange(updatedTask.ID, "updated")
	}

	return updatedTask, nil
}

// Delete deletes a task (soft delete)
func (s *TaskService) Delete(userID, taskID uuid.UUID) error {
	// Get task to verify ownership
	task, err := s.GetByID(userID, taskID)
	if err != nil {
		return err
	}

	// Soft delete the task
	err = s.repo.SoftDelete(taskID)
	if err != nil {
		return fmt.Errorf("failed to delete task: %w", err)
	}

	// Delete associated reminders
	if s.reminderService != nil {
		err = s.reminderService.DeleteByTaskID(taskID)
		if err != nil {
			fmt.Printf("Warning: failed to delete task reminders: %v\n", err)
		}
	}

	// Trigger sync
	if s.syncService != nil {
		s.syncService.NotifyTaskChange(task.ID, "deleted")
	}

	return nil
}

// GetSubtasks retrieves subtasks for a parent task
func (s *TaskService) GetSubtasks(userID, parentTaskID uuid.UUID) ([]*models.Task, error) {
	// Verify parent task ownership
	_, err := s.GetByID(userID, parentTaskID)
	if err != nil {
		return nil, err
	}

	subtasks, err := s.repo.GetSubtasks(parentTaskID)
	if err != nil {
		return nil, fmt.Errorf("failed to get subtasks: %w", err)
	}

	return subtasks, nil
}

// CreateSubtask creates a subtask under a parent task
func (s *TaskService) CreateSubtask(userID, parentTaskID uuid.UUID, req CreateTaskRequest) (*models.Task, error) {
	// Set parent task ID
	req.ParentTaskID = &parentTaskID

	// Create the subtask
	subtask, err := s.Create(userID, req)
	if err != nil {
		return nil, err
	}

	// Update parent task progress if needed
	err = s.updateParentTaskProgress(parentTaskID)
	if err != nil {
		fmt.Printf("Warning: failed to update parent task progress: %v\n", err)
	}

	return subtask, nil
}

// CompleteTask marks a task as completed
func (s *TaskService) CompleteTask(userID, taskID uuid.UUID) (*models.Task, error) {
	task, err := s.GetByID(userID, taskID)
	if err != nil {
		return nil, err
	}

	if task.IsCompleted {
		return task, nil // Already completed
	}

	// Complete the task
	task.Complete()
	task.UpdateSyncVersion("api")

	// Update in database
	updatedTask, err := s.repo.Update(task)
	if err != nil {
		return nil, fmt.Errorf("failed to complete task: %w", err)
	}

	// Send completion notification
	if s.notificationService != nil {
		err = s.notificationService.SendTaskCompletionNotification(userID, updatedTask)
		if err != nil {
			fmt.Printf("Warning: failed to send completion notification: %v\n", err)
		}
	}

	// Update parent task progress if this is a subtask
	if updatedTask.ParentTaskID != nil {
		err = s.updateParentTaskProgress(*updatedTask.ParentTaskID)
		if err != nil {
			fmt.Printf("Warning: failed to update parent task progress: %v\n", err)
		}
	}

	// Trigger sync
	if s.syncService != nil {
		s.syncService.NotifyTaskChange(updatedTask.ID, "completed")
	}

	return updatedTask, nil
}

// GetTaskStats retrieves task statistics for a user
func (s *TaskService) GetTaskStats(userID uuid.UUID) (*models.TaskStats, error) {
	stats, err := s.repo.GetTaskStats(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get task stats: %w", err)
	}

	return stats, nil
}

// SearchTasks searches for tasks by title or description
func (s *TaskService) SearchTasks(userID uuid.UUID, query string, limit int) ([]*models.Task, error) {
	if query == "" {
		return []*models.Task{}, nil
	}

	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	tasks, err := s.repo.SearchTasks(userID, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search tasks: %w", err)
	}

	return tasks, nil
}

// GetOverdueTasks retrieves overdue tasks for a user
func (s *TaskService) GetOverdueTasks(userID uuid.UUID) ([]*models.Task, error) {
	tasks, err := s.repo.GetOverdueTasks(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get overdue tasks: %w", err)
	}

	return tasks, nil
}

// GetTasksDueToday retrieves tasks due today for a user
func (s *TaskService) GetTasksDueToday(userID uuid.UUID) ([]*models.Task, error) {
	tasks, err := s.repo.GetTasksDueToday(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get tasks due today: %w", err)
	}

	return tasks, nil
}

// GetTasksDueThisWeek retrieves tasks due this week for a user
func (s *TaskService) GetTasksDueThisWeek(userID uuid.UUID) ([]*models.Task, error) {
	tasks, err := s.repo.GetTasksDueThisWeek(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get tasks due this week: %w", err)
	}

	return tasks, nil
}

// BulkUpdateTasks updates multiple tasks at once
func (s *TaskService) BulkUpdateTasks(userID uuid.UUID, updates []struct {
	TaskID uuid.UUID         `json:"task_id"`
	Update UpdateTaskRequest `json:"update"`
}) error {
	var tasksToUpdate []*models.Task

	// Process each update
	for _, update := range updates {
		task, err := s.GetByID(userID, update.TaskID)
		if err != nil {
			return fmt.Errorf("failed to get task %s: %w", update.TaskID, err)
		}

		// Apply updates (simplified - you might want to reuse the Update logic)
		if update.Update.IsCompleted != nil {
			if *update.Update.IsCompleted {
				task.Complete()
			} else {
				task.Uncomplete()
			}
		}

		if update.Update.Priority != nil {
			task.Priority = *update.Update.Priority
		}

		task.UpdateSyncVersion("api")
		tasksToUpdate = append(tasksToUpdate, task)
	}

	// Bulk update in database
	err := s.repo.BulkUpdate(tasksToUpdate)
	if err != nil {
		return fmt.Errorf("failed to bulk update tasks: %w", err)
	}

	return nil
}

// AddTagToTask adds a tag to a task
func (s *TaskService) AddTagToTask(userID, taskID uuid.UUID, tag string) (*models.Task, error) {
	task, err := s.GetByID(userID, taskID)
	if err != nil {
		return nil, err
	}

	tag = strings.TrimSpace(tag)
	if tag == "" {
		return task, nil
	}

	task.AddTag(tag)
	task.UpdateSyncVersion("api")

	updatedTask, err := s.repo.Update(task)
	if err != nil {
		return nil, fmt.Errorf("failed to add tag: %w", err)
	}

	return updatedTask, nil
}

// RemoveTagFromTask removes a tag from a task
func (s *TaskService) RemoveTagFromTask(userID, taskID uuid.UUID, tag string) (*models.Task, error) {
	task, err := s.GetByID(userID, taskID)
	if err != nil {
		return nil, err
	}

	task.RemoveTag(tag)
	task.UpdateSyncVersion("api")

	updatedTask, err := s.repo.Update(task)
	if err != nil {
		return nil, fmt.Errorf("failed to remove tag: %w", err)
	}

	return updatedTask, nil
}

// Helper methods

// createAutomaticReminders creates default reminders for a task with due date
func (s *TaskService) createAutomaticReminders(task *models.Task) error {
	if task.DueDate == nil || s.reminderService == nil {
		return nil
	}

	// Create reminder 1 day before due date
	oneDayBefore := task.DueDate.Add(-24 * time.Hour)
	if oneDayBefore.After(time.Now()) {
		_, err := s.reminderService.Create(task.UserID, task.ID, oneDayBefore, "push", "Task due tomorrow: "+task.Title)
		if err != nil {
			return err
		}
	}

	// Create reminder 1 hour before due date
	oneHourBefore := task.DueDate.Add(-1 * time.Hour)
	if oneHourBefore.After(time.Now()) {
		_, err := s.reminderService.Create(task.UserID, task.ID, oneHourBefore, "push", "Task due in 1 hour: "+task.Title)
		if err != nil {
			return err
		}
	}

	return nil
}

// updateTaskReminders updates reminders when task due date changes
func (s *TaskService) updateTaskReminders(task *models.Task) error {
	if s.reminderService == nil {
		return nil
	}

	// Delete existing automatic reminders
	err := s.reminderService.DeleteAutomaticByTaskID(task.ID)
	if err != nil {
		return err
	}

	// Create new reminders if due date is set
	if task.DueDate != nil {
		return s.createAutomaticReminders(task)
	}

	return nil
}

// updateParentTaskProgress updates the progress of a parent task based on subtask completion
func (s *TaskService) updateParentTaskProgress(parentTaskID uuid.UUID) error {
	subtasks, err := s.repo.GetSubtasks(parentTaskID)
	if err != nil {
		return err
	}

	if len(subtasks) == 0 {
		return nil
	}

	// Calculate completion percentage
	completedCount := 0
	for _, subtask := range subtasks {
		if subtask.IsCompleted {
			completedCount++
		}
	}

	// Get parent task
	parentTask, err := s.repo.GetByID(parentTaskID)
	if err != nil {
		return err
	}

	// Update progress and auto-complete if all subtasks are done
	progress := float64(completedCount) / float64(len(subtasks)) * 100
	if progress >= 100 && !parentTask.IsCompleted {
		parentTask.Complete()
	} else if progress < 100 && parentTask.IsCompleted {
		parentTask.Uncomplete()
	}

	parentTask.UpdateSyncVersion("system")

	_, err = s.repo.Update(parentTask)
	return err
}