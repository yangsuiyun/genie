package repositories

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"pomodoro-backend/internal/models"
)

// TaskRepository interface defines task data access methods
type TaskRepository interface {
	// Basic CRUD operations
	Create(task *models.Task) error
	GetByID(id uuid.UUID) (*models.Task, error)
	Update(task *models.Task) error
	Delete(id uuid.UUID) error

	// Query methods
	ListByUserID(userID uuid.UUID, filter *TaskFilter) ([]models.Task, *PaginationResult, error)
	ListByProjectID(projectID uuid.UUID, filter *TaskFilter) ([]models.Task, *PaginationResult, error)
	GetTaskCount(userID uuid.UUID) (int64, error)
	GetCompletedTaskCount(userID uuid.UUID) (int64, error)

	// Specialized methods
	CheckTaskOwnership(taskID, userID uuid.UUID) (bool, error)
	ValidateTaskProjectAccess(taskID, userID uuid.UUID) error
	GetTasksRequiringProjectID(userID uuid.UUID) ([]models.Task, error)

	// Statistics methods
	GetTaskStatsByProject(projectID uuid.UUID) (*TaskProjectStats, error)
	GetOverdueTasks(userID uuid.UUID) ([]models.Task, error)
	GetTasksDueToday(userID uuid.UUID) ([]models.Task, error)
}

// TaskFilter represents filters for task queries
type TaskFilter struct {
	ProjectID    *uuid.UUID           `json:"project_id,omitempty"`
	IsCompleted  *bool                `json:"is_completed,omitempty"`
	Priority     *models.TaskPriority `json:"priority,omitempty"`
	SearchQuery  string               `json:"search_query,omitempty"`
	DueBefore    *time.Time           `json:"due_before,omitempty"`
	DueAfter     *time.Time           `json:"due_after,omitempty"`
	Tags         []string             `json:"tags,omitempty"`
	ParentTaskID *uuid.UUID           `json:"parent_task_id,omitempty"`
	SortBy       string               `json:"sort_by,omitempty"`    // "title", "priority", "due_date", "created_at", "updated_at"
	SortOrder    string               `json:"sort_order,omitempty"` // "asc", "desc"
	Page         int                  `json:"page"`
	Limit        int                  `json:"limit"`
}

// TaskProjectStats represents task statistics for a project
type TaskProjectStats struct {
	ProjectID      uuid.UUID `json:"project_id"`
	TotalTasks     int64     `json:"total_tasks"`
	CompletedTasks int64     `json:"completed_tasks"`
	PendingTasks   int64     `json:"pending_tasks"`
	OverdueTasks   int64     `json:"overdue_tasks"`
}

// taskRepository implements TaskRepository using GORM
type taskRepository struct {
	db *gorm.DB
}

// NewTaskRepository creates a new task repository
func NewTaskRepository(db *gorm.DB) TaskRepository {
	return &taskRepository{db: db}
}

// Create creates a new task
func (r *taskRepository) Create(task *models.Task) error {
	if err := task.BeforeCreate(r.db); err != nil {
		return fmt.Errorf("before create hook failed: %w", err)
	}

	if err := r.db.Create(task).Error; err != nil {
		return fmt.Errorf("failed to create task: %w", err)
	}

	return nil
}

// GetByID gets a task by ID with relationships
func (r *taskRepository) GetByID(id uuid.UUID) (*models.Task, error) {
	var task models.Task
	if err := r.db.Preload("Project").Preload("Subtasks").Preload("Sessions").Where("id = ?", id).First(&task).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get task: %w", err)
	}

	return &task, nil
}

// Update updates a task
func (r *taskRepository) Update(task *models.Task) error {
	task.UpdatedAt = time.Now()

	if err := r.db.Save(task).Error; err != nil {
		return fmt.Errorf("failed to update task: %w", err)
	}

	return nil
}

// Delete soft deletes a task (since we're using soft delete in the model)
func (r *taskRepository) Delete(id uuid.UUID) error {
	if err := r.db.Model(&models.Task{}).Where("id = ?", id).Update("is_deleted", true).Error; err != nil {
		return fmt.Errorf("failed to delete task: %w", err)
	}

	return nil
}

// ListByUserID lists tasks for a user with filters and pagination
func (r *taskRepository) ListByUserID(userID uuid.UUID, filter *TaskFilter) ([]models.Task, *PaginationResult, error) {
	var tasks []models.Task
	var total int64

	query := r.db.Model(&models.Task{}).Where("user_id = ? AND is_deleted = false", userID)

	// Apply filters
	query = r.applyFilters(query, filter)

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to count tasks: %w", err)
	}

	// Apply sorting
	query = r.applySorting(query, filter)

	// Apply pagination
	offset := (filter.Page - 1) * filter.Limit
	if err := query.Preload("Project").Preload("Subtasks").Offset(offset).Limit(filter.Limit).Find(&tasks).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to get tasks: %w", err)
	}

	totalPages := int(total) / filter.Limit
	if int(total)%filter.Limit > 0 {
		totalPages++
	}

	pagination := &PaginationResult{
		Page:       filter.Page,
		Limit:      filter.Limit,
		Total:      total,
		TotalPages: totalPages,
	}

	return tasks, pagination, nil
}

// ListByProjectID lists tasks for a specific project
func (r *taskRepository) ListByProjectID(projectID uuid.UUID, filter *TaskFilter) ([]models.Task, *PaginationResult, error) {
	var tasks []models.Task
	var total int64

	query := r.db.Model(&models.Task{}).Where("project_id = ? AND is_deleted = false", projectID)

	// Apply filters (excluding project_id since it's already set)
	query = r.applyFilters(query, filter)

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to count tasks: %w", err)
	}

	// Apply sorting
	query = r.applySorting(query, filter)

	// Apply pagination
	offset := (filter.Page - 1) * filter.Limit
	if err := query.Preload("Project").Preload("Subtasks").Offset(offset).Limit(filter.Limit).Find(&tasks).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to get tasks: %w", err)
	}

	totalPages := int(total) / filter.Limit
	if int(total)%filter.Limit > 0 {
		totalPages++
	}

	pagination := &PaginationResult{
		Page:       filter.Page,
		Limit:      filter.Limit,
		Total:      total,
		TotalPages: totalPages,
	}

	return tasks, pagination, nil
}

// GetTaskCount gets the total number of tasks for a user
func (r *taskRepository) GetTaskCount(userID uuid.UUID) (int64, error) {
	var count int64
	if err := r.db.Model(&models.Task{}).Where("user_id = ? AND is_deleted = false", userID).Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to count tasks: %w", err)
	}

	return count, nil
}

// GetCompletedTaskCount gets the number of completed tasks for a user
func (r *taskRepository) GetCompletedTaskCount(userID uuid.UUID) (int64, error) {
	var count int64
	if err := r.db.Model(&models.Task{}).Where("user_id = ? AND is_completed = true AND is_deleted = false", userID).Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to count completed tasks: %w", err)
	}

	return count, nil
}

// CheckTaskOwnership checks if a task belongs to a user
func (r *taskRepository) CheckTaskOwnership(taskID, userID uuid.UUID) (bool, error) {
	var count int64
	if err := r.db.Model(&models.Task{}).Where("id = ? AND user_id = ?", taskID, userID).Count(&count).Error; err != nil {
		return false, fmt.Errorf("failed to check task ownership: %w", err)
	}

	return count > 0, nil
}

// ValidateTaskProjectAccess validates that a user has access to a task's project
func (r *taskRepository) ValidateTaskProjectAccess(taskID, userID uuid.UUID) error {
	var task models.Task
	if err := r.db.Select("project_id").Where("id = ?", taskID).First(&task).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("task not found")
		}
		return fmt.Errorf("failed to get task: %w", err)
	}

	// Check if user owns the project
	var count int64
	if err := r.db.Model(&models.Project{}).Where("id = ? AND user_id = ?", task.ProjectID, userID).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to check project access: %w", err)
	}

	if count == 0 {
		return fmt.Errorf("access denied: project not found or not owned by user")
	}

	return nil
}

// GetTasksRequiringProjectID gets tasks that don't have a project_id (for migration)
func (r *taskRepository) GetTasksRequiringProjectID(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	// This query would only be relevant during migration - in our new system all tasks require project_id
	if err := r.db.Where("user_id = ? AND project_id IS NULL", userID).Find(&tasks).Error; err != nil {
		return nil, fmt.Errorf("failed to get tasks without project: %w", err)
	}

	return tasks, nil
}

// GetTaskStatsByProject gets task statistics for a project
func (r *taskRepository) GetTaskStatsByProject(projectID uuid.UUID) (*TaskProjectStats, error) {
	var stats TaskProjectStats
	stats.ProjectID = projectID

	// Get total tasks count
	if err := r.db.Model(&models.Task{}).Where("project_id = ? AND is_deleted = false", projectID).Count(&stats.TotalTasks).Error; err != nil {
		return nil, fmt.Errorf("failed to count total tasks: %w", err)
	}

	// Get completed tasks count
	if err := r.db.Model(&models.Task{}).Where("project_id = ? AND is_completed = true AND is_deleted = false", projectID).Count(&stats.CompletedTasks).Error; err != nil {
		return nil, fmt.Errorf("failed to count completed tasks: %w", err)
	}

	// Calculate pending tasks
	stats.PendingTasks = stats.TotalTasks - stats.CompletedTasks

	// Get overdue tasks count
	now := time.Now()
	if err := r.db.Model(&models.Task{}).Where("project_id = ? AND due_date < ? AND is_completed = false AND is_deleted = false", projectID, now).Count(&stats.OverdueTasks).Error; err != nil {
		return nil, fmt.Errorf("failed to count overdue tasks: %w", err)
	}

	return &stats, nil
}

// GetOverdueTasks gets all overdue tasks for a user
func (r *taskRepository) GetOverdueTasks(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	now := time.Now()

	if err := r.db.Preload("Project").Where("user_id = ? AND due_date < ? AND is_completed = false AND is_deleted = false", userID, now).Find(&tasks).Error; err != nil {
		return nil, fmt.Errorf("failed to get overdue tasks: %w", err)
	}

	return tasks, nil
}

// GetTasksDueToday gets all tasks due today for a user
func (r *taskRepository) GetTasksDueToday(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	if err := r.db.Preload("Project").Where("user_id = ? AND due_date >= ? AND due_date < ? AND is_deleted = false", userID, startOfDay, endOfDay).Find(&tasks).Error; err != nil {
		return nil, fmt.Errorf("failed to get tasks due today: %w", err)
	}

	return tasks, nil
}

// Helper methods for building queries

func (r *taskRepository) applyFilters(query *gorm.DB, filter *TaskFilter) *gorm.DB {
	if filter == nil {
		return query
	}

	if filter.ProjectID != nil {
		query = query.Where("project_id = ?", *filter.ProjectID)
	}

	if filter.IsCompleted != nil {
		query = query.Where("is_completed = ?", *filter.IsCompleted)
	}

	if filter.Priority != nil {
		query = query.Where("priority = ?", *filter.Priority)
	}

	if filter.SearchQuery != "" {
		searchPattern := "%" + filter.SearchQuery + "%"
		query = query.Where("(title ILIKE ? OR description ILIKE ?)", searchPattern, searchPattern)
	}

	if filter.DueBefore != nil {
		query = query.Where("due_date <= ?", *filter.DueBefore)
	}

	if filter.DueAfter != nil {
		query = query.Where("due_date >= ?", *filter.DueAfter)
	}

	if filter.ParentTaskID != nil {
		query = query.Where("parent_task_id = ?", *filter.ParentTaskID)
	}

	if len(filter.Tags) > 0 {
		// PostgreSQL array contains query
		query = query.Where("tags && ?", filter.Tags)
	}

	return query
}

func (r *taskRepository) applySorting(query *gorm.DB, filter *TaskFilter) *gorm.DB {
	orderBy := "created_at DESC" // default sorting

	if filter != nil && filter.SortBy != "" && filter.SortOrder != "" {
		validSorts := map[string]bool{
			"title": true, "priority": true, "due_date": true, "created_at": true, "updated_at": true,
		}
		validOrders := map[string]bool{"asc": true, "desc": true}

		if validSorts[filter.SortBy] && validOrders[filter.SortOrder] {
			orderBy = fmt.Sprintf("%s %s", filter.SortBy, filter.SortOrder)
		}
	}

	return query.Order(orderBy)
}
