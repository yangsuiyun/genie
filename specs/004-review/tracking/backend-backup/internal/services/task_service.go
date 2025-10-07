package services

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/repositories"
)

// TaskService interface defines task business logic
type TaskService interface {
	// Core operations
	CreateTask(userID uuid.UUID, req *models.TaskCreateRequest) (*models.Task, error)
	GetTask(taskID, userID uuid.UUID) (*models.Task, error)
	UpdateTask(taskID, userID uuid.UUID, req *models.TaskUpdateRequest) (*models.Task, error)
	DeleteTask(taskID, userID uuid.UUID) error

	// Query operations
	ListTasks(userID uuid.UUID, filter *repositories.TaskFilter) ([]models.Task, *repositories.PaginationResult, error)
	ListTasksByProject(projectID, userID uuid.UUID, filter *repositories.TaskFilter) ([]models.Task, *repositories.PaginationResult, error)
	GetTaskStatistics(userID uuid.UUID) (*TaskStatistics, error)

	// Specialized operations
	CompleteTask(taskID, userID uuid.UUID) (*models.Task, error)
	UncompleteTask(taskID, userID uuid.UUID) (*models.Task, error)
	UpdateTaskProgress(taskID, userID uuid.UUID, progress float64) (*models.Task, error)

	// Validation and access control
	ValidateTaskAccess(taskID, userID uuid.UUID) error
	ValidateProjectAccess(projectID, userID uuid.UUID) error

	// Migration support
	MigrateTasksToDefaultProject(userID uuid.UUID) error
}

// TaskStatistics represents task statistics for a user
type TaskStatistics struct {
	TotalTasks         int64 `json:"total_tasks"`
	CompletedTasks     int64 `json:"completed_tasks"`
	PendingTasks       int64 `json:"pending_tasks"`
	OverdueTasks       int   `json:"overdue_tasks"`
	TasksDueToday      int   `json:"tasks_due_today"`
	CompletionRate     float64 `json:"completion_rate"`
	AverageTasksPerDay float64 `json:"average_tasks_per_day"`
}

// taskService implements TaskService
type taskService struct {
	taskRepo    repositories.TaskRepository
	projectRepo repositories.ProjectRepository
}

// NewTaskService creates a new task service
func NewTaskService(taskRepo repositories.TaskRepository, projectRepo repositories.ProjectRepository) TaskService {
	return &taskService{
		taskRepo:    taskRepo,
		projectRepo: projectRepo,
	}
}

// CreateTask creates a new task
func (s *taskService) CreateTask(userID uuid.UUID, req *models.TaskCreateRequest) (*models.Task, error) {
	// Validate input
	if err := s.validateCreateRequest(req); err != nil {
		return nil, err
	}

	// Validate project access
	if err := s.ValidateProjectAccess(req.ProjectID, userID); err != nil {
		return nil, err
	}

	// Validate parent task if specified
	if req.ParentTaskID != nil {
		if err := s.ValidateTaskAccess(*req.ParentTaskID, userID); err != nil {
			return nil, fmt.Errorf("invalid parent task: %w", err)
		}
	}

	// Create task
	priority := models.PriorityMedium
	if req.Priority != nil {
		priority = *req.Priority
	}

	task := &models.Task{
		ID:            uuid.New(),
		UserID:        userID,
		ProjectID:     req.ProjectID,
		Title:         strings.TrimSpace(req.Title),
		Description:   strings.TrimSpace(req.Description),
		DueDate:       req.DueDate,
		Priority:      priority,
		Tags:          req.Tags,
		ParentTaskID:  req.ParentTaskID,
		EstimatedTime: req.EstimatedTime,
		IsCompleted:   false,
		Progress:      0.0,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
		SyncVersion:   1,
		IsDeleted:     false,
	}

	if err := s.taskRepo.Create(task); err != nil {
		return nil, fmt.Errorf("failed to create task: %w", err)
	}

	return task, nil
}

// GetTask gets a task by ID
func (s *taskService) GetTask(taskID, userID uuid.UUID) (*models.Task, error) {
	// Validate access
	if err := s.ValidateTaskAccess(taskID, userID); err != nil {
		return nil, err
	}

	task, err := s.taskRepo.GetByID(taskID)
	if err != nil {
		return nil, fmt.Errorf("failed to get task: %w", err)
	}

	if task == nil {
		return nil, fmt.Errorf("task not found")
	}

	return task, nil
}

// UpdateTask updates a task
func (s *taskService) UpdateTask(taskID, userID uuid.UUID, req *models.TaskUpdateRequest) (*models.Task, error) {
	// Validate access
	if err := s.ValidateTaskAccess(taskID, userID); err != nil {
		return nil, err
	}

	// Get existing task
	task, err := s.taskRepo.GetByID(taskID)
	if err != nil {
		return nil, fmt.Errorf("failed to get task: %w", err)
	}

	if task == nil {
		return nil, fmt.Errorf("task not found")
	}

	// Validate update request
	if err := s.validateUpdateRequest(req); err != nil {
		return nil, err
	}

	// Update fields
	if req.Title != nil {
		task.Title = strings.TrimSpace(*req.Title)
	}

	if req.Description != nil {
		task.Description = strings.TrimSpace(*req.Description)
	}

	if req.DueDate != nil {
		task.DueDate = req.DueDate
	}

	if req.Priority != nil {
		task.Priority = *req.Priority
	}

	if req.Tags != nil {
		task.Tags = req.Tags
	}

	if req.IsCompleted != nil {
		task.IsCompleted = *req.IsCompleted
		if *req.IsCompleted {
			now := time.Now()
			task.CompletedAt = &now
			task.Progress = 100.0
		} else {
			task.CompletedAt = nil
		}
	}

	if req.Progress != nil {
		task.Progress = *req.Progress
		// Auto-complete/uncomplete based on progress
		if *req.Progress >= 100 && !task.IsCompleted {
			now := time.Now()
			task.IsCompleted = true
			task.CompletedAt = &now
		} else if *req.Progress < 100 && task.IsCompleted {
			task.IsCompleted = false
			task.CompletedAt = nil
		}
	}

	if req.EstimatedTime != nil {
		task.EstimatedTime = req.EstimatedTime
	}

	task.UpdatedAt = time.Now()
	task.SyncVersion++

	// Save changes
	if err := s.taskRepo.Update(task); err != nil {
		return nil, fmt.Errorf("failed to update task: %w", err)
	}

	return task, nil
}

// DeleteTask deletes a task
func (s *taskService) DeleteTask(taskID, userID uuid.UUID) error {
	// Validate access
	if err := s.ValidateTaskAccess(taskID, userID); err != nil {
		return err
	}

	// Soft delete the task
	if err := s.taskRepo.Delete(taskID); err != nil {
		return fmt.Errorf("failed to delete task: %w", err)
	}

	return nil
}

// ListTasks lists tasks for a user with filters and pagination
func (s *taskService) ListTasks(userID uuid.UUID, filter *repositories.TaskFilter) ([]models.Task, *repositories.PaginationResult, error) {
	// Validate and set defaults for filter
	if filter == nil {
		filter = &repositories.TaskFilter{}
	}

	if filter.Page <= 0 {
		filter.Page = 1
	}

	if filter.Limit <= 0 || filter.Limit > 100 {
		filter.Limit = 20
	}

	// Sanitize search query
	if filter.SearchQuery != "" {
		filter.SearchQuery = strings.TrimSpace(filter.SearchQuery)
		if len(filter.SearchQuery) > 100 {
			filter.SearchQuery = filter.SearchQuery[:100]
		}
	}

	// Get tasks
	tasks, pagination, err := s.taskRepo.ListByUserID(userID, filter)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to list tasks: %w", err)
	}

	return tasks, pagination, nil
}

// ListTasksByProject lists tasks for a specific project
func (s *taskService) ListTasksByProject(projectID, userID uuid.UUID, filter *repositories.TaskFilter) ([]models.Task, *repositories.PaginationResult, error) {
	// Validate project access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return nil, nil, err
	}

	// Validate and set defaults for filter
	if filter == nil {
		filter = &repositories.TaskFilter{}
	}

	if filter.Page <= 0 {
		filter.Page = 1
	}

	if filter.Limit <= 0 || filter.Limit > 100 {
		filter.Limit = 20
	}

	// Get tasks
	tasks, pagination, err := s.taskRepo.ListByProjectID(projectID, filter)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to list tasks: %w", err)
	}

	return tasks, pagination, nil
}

// GetTaskStatistics gets task statistics for a user
func (s *taskService) GetTaskStatistics(userID uuid.UUID) (*TaskStatistics, error) {
	totalTasks, err := s.taskRepo.GetTaskCount(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get total task count: %w", err)
	}

	completedTasks, err := s.taskRepo.GetCompletedTaskCount(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get completed task count: %w", err)
	}

	overdueTasks, err := s.taskRepo.GetOverdueTasks(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get overdue tasks: %w", err)
	}

	tasksDueToday, err := s.taskRepo.GetTasksDueToday(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get tasks due today: %w", err)
	}

	pendingTasks := totalTasks - completedTasks

	var completionRate float64
	if totalTasks > 0 {
		completionRate = float64(completedTasks) / float64(totalTasks) * 100
	}

	stats := &TaskStatistics{
		TotalTasks:     totalTasks,
		CompletedTasks: completedTasks,
		PendingTasks:   pendingTasks,
		OverdueTasks:   len(overdueTasks),
		TasksDueToday:  len(tasksDueToday),
		CompletionRate: completionRate,
		// TODO: Calculate average tasks per day based on user's activity period
		AverageTasksPerDay: 0,
	}

	return stats, nil
}

// CompleteTask marks a task as completed
func (s *taskService) CompleteTask(taskID, userID uuid.UUID) (*models.Task, error) {
	isCompleted := true
	req := &models.TaskUpdateRequest{
		IsCompleted: &isCompleted,
	}

	return s.UpdateTask(taskID, userID, req)
}

// UncompleteTask marks a task as not completed
func (s *taskService) UncompleteTask(taskID, userID uuid.UUID) (*models.Task, error) {
	isCompleted := false
	req := &models.TaskUpdateRequest{
		IsCompleted: &isCompleted,
	}

	return s.UpdateTask(taskID, userID, req)
}

// UpdateTaskProgress updates the progress of a task
func (s *taskService) UpdateTaskProgress(taskID, userID uuid.UUID, progress float64) (*models.Task, error) {
	req := &models.TaskUpdateRequest{
		Progress: &progress,
	}

	return s.UpdateTask(taskID, userID, req)
}

// ValidateTaskAccess validates that a user has access to a task
func (s *taskService) ValidateTaskAccess(taskID, userID uuid.UUID) error {
	hasAccess, err := s.taskRepo.CheckTaskOwnership(taskID, userID)
	if err != nil {
		return fmt.Errorf("failed to check task access: %w", err)
	}

	if !hasAccess {
		return fmt.Errorf("task not found or access denied")
	}

	return nil
}

// ValidateProjectAccess validates that a user has access to a project
func (s *taskService) ValidateProjectAccess(projectID, userID uuid.UUID) error {
	hasAccess, err := s.projectRepo.CheckProjectOwnership(projectID, userID)
	if err != nil {
		return fmt.Errorf("failed to check project access: %w", err)
	}

	if !hasAccess {
		return fmt.Errorf("project not found or access denied")
	}

	return nil
}

// MigrateTasksToDefaultProject migrates tasks without project_id to user's default project
func (s *taskService) MigrateTasksToDefaultProject(userID uuid.UUID) error {
	// Get or create default project
	defaultProject, err := s.projectRepo.GetDefaultProject(userID)
	if err != nil {
		return fmt.Errorf("failed to get default project: %w", err)
	}

	if defaultProject == nil {
		defaultProject, err = s.projectRepo.CreateDefaultInboxProject(userID)
		if err != nil {
			return fmt.Errorf("failed to create default project: %w", err)
		}
	}

	// Get tasks without project_id
	tasks, err := s.taskRepo.GetTasksRequiringProjectID(userID)
	if err != nil {
		return fmt.Errorf("failed to get tasks requiring project assignment: %w", err)
	}

	// Update tasks to assign them to default project
	for _, task := range tasks {
		task.ProjectID = defaultProject.ID
		if err := s.taskRepo.Update(&task); err != nil {
			return fmt.Errorf("failed to migrate task %s to default project: %w", task.ID, err)
		}
	}

	return nil
}

// Validation methods

func (s *taskService) validateCreateRequest(req *models.TaskCreateRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}

	title := strings.TrimSpace(req.Title)
	if title == "" {
		return fmt.Errorf("task title is required")
	}

	if len(title) > 200 {
		return fmt.Errorf("task title must be 200 characters or less")
	}

	if len(req.Description) > 2000 {
		return fmt.Errorf("task description must be 2000 characters or less")
	}

	if req.EstimatedTime != nil && (*req.EstimatedTime < 1 || *req.EstimatedTime > 1440) {
		return fmt.Errorf("estimated time must be between 1 and 1440 minutes")
	}

	if len(req.Tags) > 50 {
		return fmt.Errorf("maximum 50 tags allowed")
	}

	// Validate priority
	if req.Priority != nil {
		validPriorities := map[models.TaskPriority]bool{
			models.PriorityLow:    true,
			models.PriorityMedium: true,
			models.PriorityHigh:   true,
			models.PriorityUrgent: true,
		}
		if !validPriorities[*req.Priority] {
			return fmt.Errorf("invalid priority value")
		}
	}

	return nil
}

func (s *taskService) validateUpdateRequest(req *models.TaskUpdateRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}

	if req.Title != nil {
		title := strings.TrimSpace(*req.Title)
		if title == "" {
			return fmt.Errorf("task title cannot be empty")
		}

		if len(title) > 200 {
			return fmt.Errorf("task title must be 200 characters or less")
		}
	}

	if req.Description != nil && len(*req.Description) > 2000 {
		return fmt.Errorf("task description must be 2000 characters or less")
	}

	if req.Progress != nil && (*req.Progress < 0 || *req.Progress > 100) {
		return fmt.Errorf("progress must be between 0 and 100")
	}

	if req.EstimatedTime != nil && (*req.EstimatedTime < 1 || *req.EstimatedTime > 1440) {
		return fmt.Errorf("estimated time must be between 1 and 1440 minutes")
	}

	if req.Tags != nil && len(req.Tags) > 50 {
		return fmt.Errorf("maximum 50 tags allowed")
	}

	// Validate priority
	if req.Priority != nil {
		validPriorities := map[models.TaskPriority]bool{
			models.PriorityLow:    true,
			models.PriorityMedium: true,
			models.PriorityHigh:   true,
			models.PriorityUrgent: true,
		}
		if !validPriorities[*req.Priority] {
			return fmt.Errorf("invalid priority value")
		}
	}

	return nil
}