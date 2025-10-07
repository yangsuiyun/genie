package repositories

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"pomodoro-backend/internal/models"
)

// ProjectRepository interface defines project data access methods
type ProjectRepository interface {
	// Basic CRUD operations
	Create(project *models.Project) error
	GetByID(id uuid.UUID) (*models.Project, error)
	GetByIDWithStats(id uuid.UUID) (*models.ProjectWithStats, error)
	Update(project *models.Project) error
	Delete(id uuid.UUID) error

	// Query methods
	ListByUserID(userID uuid.UUID, filter *ProjectFilter) ([]models.Project, *PaginationResult, error)
	ListByUserIDWithStats(userID uuid.UUID, filter *ProjectFilter) ([]models.ProjectWithStats, *PaginationResult, error)
	GetDefaultProject(userID uuid.UUID) (*models.Project, error)
	GetProjectCount(userID uuid.UUID) (int64, error)

	// Specialized methods
	CreateDefaultInboxProject(userID uuid.UUID) (*models.Project, error)
	CheckProjectOwnership(projectID, userID uuid.UUID) (bool, error)
	GetProjectStatistics(projectID uuid.UUID) (*models.ProjectStatistics, error)
	ToggleCompletion(projectID uuid.UUID, isCompleted bool) error

	// Validation methods
	CheckProjectNameExists(userID uuid.UUID, name string, excludeID *uuid.UUID) (bool, error)
	ValidateProjectDeletion(projectID uuid.UUID) error
}

// ProjectFilter represents filters for project queries
type ProjectFilter struct {
	IsCompleted *bool   `json:"is_completed,omitempty"`
	SearchQuery string  `json:"search_query,omitempty"`
	SortBy      string  `json:"sort_by,omitempty"`      // "name", "created_at", "updated_at", "completion_status"
	SortOrder   string  `json:"sort_order,omitempty"`   // "asc", "desc"
	Page        int     `json:"page"`
	Limit       int     `json:"limit"`
}

// PaginationResult represents pagination metadata
type PaginationResult struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"total_pages"`
}

// projectRepository implements ProjectRepository using GORM
type projectRepository struct {
	db *gorm.DB
}

// NewProjectRepository creates a new project repository
func NewProjectRepository(db *gorm.DB) ProjectRepository {
	return &projectRepository{db: db}
}

// Create creates a new project
func (r *projectRepository) Create(project *models.Project) error {
	if err := project.BeforeCreate(r.db); err != nil {
		return fmt.Errorf("before create hook failed: %w", err)
	}

	if err := r.db.Create(project).Error; err != nil {
		return fmt.Errorf("failed to create project: %w", err)
	}

	return nil
}

// GetByID gets a project by ID
func (r *projectRepository) GetByID(id uuid.UUID) (*models.Project, error) {
	var project models.Project
	if err := r.db.Where("id = ?", id).First(&project).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get project: %w", err)
	}

	return &project, nil
}

// GetByIDWithStats gets a project by ID with calculated statistics
func (r *projectRepository) GetByIDWithStats(id uuid.UUID) (*models.ProjectWithStats, error) {
	project, err := r.GetByID(id)
	if err != nil {
		return nil, err
	}
	if project == nil {
		return nil, nil
	}

	stats, err := r.GetProjectStatistics(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get project statistics: %w", err)
	}

	return &models.ProjectWithStats{
		Project:    *project,
		Statistics: *stats,
	}, nil
}

// Update updates a project
func (r *projectRepository) Update(project *models.Project) error {
	project.UpdatedAt = time.Now()

	if err := r.db.Save(project).Error; err != nil {
		return fmt.Errorf("failed to update project: %w", err)
	}

	return nil
}

// Delete deletes a project and all associated data
func (r *projectRepository) Delete(id uuid.UUID) error {
	// First check if this is a default project
	var project models.Project
	if err := r.db.Where("id = ?", id).First(&project).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("project not found")
		}
		return fmt.Errorf("failed to get project: %w", err)
	}

	if project.IsDefault {
		return fmt.Errorf("cannot delete default project")
	}

	// Start transaction for cascade deletion
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Delete associated pomodoro sessions
		if err := tx.Where("project_id = ?", id).Delete(&models.PomodoroSession{}).Error; err != nil {
			return fmt.Errorf("failed to delete project sessions: %w", err)
		}

		// Delete associated tasks
		if err := tx.Where("project_id = ?", id).Delete(&models.Task{}).Error; err != nil {
			return fmt.Errorf("failed to delete project tasks: %w", err)
		}

		// Delete the project itself
		if err := tx.Delete(&project).Error; err != nil {
			return fmt.Errorf("failed to delete project: %w", err)
		}

		return nil
	})
}

// ListByUserID lists projects for a user with filters and pagination
func (r *projectRepository) ListByUserID(userID uuid.UUID, filter *ProjectFilter) ([]models.Project, *PaginationResult, error) {
	var projects []models.Project
	var total int64

	query := r.db.Model(&models.Project{}).Where("user_id = ?", userID)

	// Apply filters
	if filter.IsCompleted != nil {
		query = query.Where("is_completed = ?", *filter.IsCompleted)
	}

	if filter.SearchQuery != "" {
		searchPattern := "%" + filter.SearchQuery + "%"
		query = query.Where("(name ILIKE ? OR description ILIKE ?)", searchPattern, searchPattern)
	}

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to count projects: %w", err)
	}

	// Apply sorting
	orderBy := "created_at DESC" // default sorting
	if filter.SortBy != "" && filter.SortOrder != "" {
		validSorts := map[string]bool{
			"name": true, "created_at": true, "updated_at": true, "completion_status": true,
		}
		validOrders := map[string]bool{"asc": true, "desc": true}

		if validSorts[filter.SortBy] && validOrders[filter.SortOrder] {
			if filter.SortBy == "completion_status" {
				orderBy = fmt.Sprintf("is_completed %s, name asc", filter.SortOrder)
			} else {
				orderBy = fmt.Sprintf("%s %s", filter.SortBy, filter.SortOrder)
			}
		}
	}
	query = query.Order(orderBy)

	// Apply pagination
	offset := (filter.Page - 1) * filter.Limit
	if err := query.Offset(offset).Limit(filter.Limit).Find(&projects).Error; err != nil {
		return nil, nil, fmt.Errorf("failed to get projects: %w", err)
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

	return projects, pagination, nil
}

// ListByUserIDWithStats lists projects for a user with statistics
func (r *projectRepository) ListByUserIDWithStats(userID uuid.UUID, filter *ProjectFilter) ([]models.ProjectWithStats, *PaginationResult, error) {
	projects, pagination, err := r.ListByUserID(userID, filter)
	if err != nil {
		return nil, nil, err
	}

	var projectsWithStats []models.ProjectWithStats
	for _, project := range projects {
		stats, err := r.GetProjectStatistics(project.ID)
		if err != nil {
			return nil, nil, fmt.Errorf("failed to get statistics for project %s: %w", project.ID, err)
		}

		projectsWithStats = append(projectsWithStats, models.ProjectWithStats{
			Project:    project,
			Statistics: *stats,
		})
	}

	return projectsWithStats, pagination, nil
}

// GetDefaultProject gets the default "Inbox" project for a user
func (r *projectRepository) GetDefaultProject(userID uuid.UUID) (*models.Project, error) {
	var project models.Project
	if err := r.db.Where("user_id = ? AND is_default = true", userID).First(&project).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get default project: %w", err)
	}

	return &project, nil
}

// GetProjectCount gets the total number of projects for a user
func (r *projectRepository) GetProjectCount(userID uuid.UUID) (int64, error) {
	var count int64
	if err := r.db.Model(&models.Project{}).Where("user_id = ?", userID).Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to count projects: %w", err)
	}

	return count, nil
}

// CreateDefaultInboxProject creates the default "Inbox" project for a new user
func (r *projectRepository) CreateDefaultInboxProject(userID uuid.UUID) (*models.Project, error) {
	project := &models.Project{
		ID:          uuid.New(),
		UserID:      userID,
		Name:        "Inbox",
		Description: "Default project for tasks",
		IsDefault:   true,
		IsCompleted: false,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := r.Create(project); err != nil {
		return nil, fmt.Errorf("failed to create default inbox project: %w", err)
	}

	return project, nil
}

// CheckProjectOwnership checks if a project belongs to a user
func (r *projectRepository) CheckProjectOwnership(projectID, userID uuid.UUID) (bool, error) {
	var count int64
	if err := r.db.Model(&models.Project{}).Where("id = ? AND user_id = ?", projectID, userID).Count(&count).Error; err != nil {
		return false, fmt.Errorf("failed to check project ownership: %w", err)
	}

	return count > 0, nil
}

// GetProjectStatistics calculates and returns project statistics
func (r *projectRepository) GetProjectStatistics(projectID uuid.UUID) (*models.ProjectStatistics, error) {
	var stats models.ProjectStatistics

	// Task statistics
	var taskStats struct {
		TotalTasks     int64
		CompletedTasks int64
	}

	if err := r.db.Model(&models.Task{}).
		Select("COUNT(*) as total_tasks, COUNT(CASE WHEN is_completed = true THEN 1 END) as completed_tasks").
		Where("project_id = ?", projectID).
		Scan(&taskStats).Error; err != nil {
		return nil, fmt.Errorf("failed to get task statistics: %w", err)
	}

	stats.TotalTasks = int(taskStats.TotalTasks)
	stats.CompletedTasks = int(taskStats.CompletedTasks)
	stats.PendingTasks = stats.TotalTasks - stats.CompletedTasks

	// Calculate completion percentage
	if stats.TotalTasks > 0 {
		stats.CompletionPercent = float64(stats.CompletedTasks) / float64(stats.TotalTasks) * 100
	}

	// Pomodoro statistics
	var pomodoroStats struct {
		TotalPomodoros   int64
		TotalTimeSeconds int64
		AvgDurationSec   float64
	}

	if err := r.db.Model(&models.PomodoroSession{}).
		Select("COUNT(*) as total_pomodoros, COALESCE(SUM(COALESCE(actual_duration, planned_duration)), 0) as total_time_seconds, COALESCE(AVG(COALESCE(actual_duration, planned_duration)), 0) as avg_duration_sec").
		Where("project_id = ? AND status = 'completed'", projectID).
		Scan(&pomodoroStats).Error; err != nil {
		return nil, fmt.Errorf("failed to get pomodoro statistics: %w", err)
	}

	stats.TotalPomodoros = int(pomodoroStats.TotalPomodoros)
	stats.TotalTimeSeconds = int(pomodoroStats.TotalTimeSeconds)
	stats.AvgPomodoroSec = int(pomodoroStats.AvgDurationSec)

	// Format total time
	hours := stats.TotalTimeSeconds / 3600
	minutes := (stats.TotalTimeSeconds % 3600) / 60
	if hours > 0 {
		stats.TotalTimeFormatted = fmt.Sprintf("%dh %dm", hours, minutes)
	} else {
		stats.TotalTimeFormatted = fmt.Sprintf("%dm", minutes)
	}

	// Get last activity time
	var lastActivity time.Time
	if err := r.db.Model(&models.PomodoroSession{}).
		Select("MAX(started_at)").
		Where("project_id = ?", projectID).
		Scan(&lastActivity).Error; err == nil && !lastActivity.IsZero() {
		stats.LastActivityAt = &lastActivity
	}

	return &stats, nil
}

// ToggleCompletion toggles the completion status of a project
func (r *projectRepository) ToggleCompletion(projectID uuid.UUID, isCompleted bool) error {
	if err := r.db.Model(&models.Project{}).
		Where("id = ?", projectID).
		Updates(map[string]interface{}{
			"is_completed": isCompleted,
			"updated_at":   time.Now(),
		}).Error; err != nil {
		return fmt.Errorf("failed to toggle project completion: %w", err)
	}

	return nil
}

// CheckProjectNameExists checks if a project name already exists for a user
func (r *projectRepository) CheckProjectNameExists(userID uuid.UUID, name string, excludeID *uuid.UUID) (bool, error) {
	query := r.db.Model(&models.Project{}).Where("user_id = ? AND name = ?", userID, name)

	if excludeID != nil {
		query = query.Where("id != ?", *excludeID)
	}

	var count int64
	if err := query.Count(&count).Error; err != nil {
		return false, fmt.Errorf("failed to check project name existence: %w", err)
	}

	return count > 0, nil
}

// ValidateProjectDeletion validates if a project can be deleted
func (r *projectRepository) ValidateProjectDeletion(projectID uuid.UUID) error {
	var project models.Project
	if err := r.db.Where("id = ?", projectID).First(&project).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("project not found")
		}
		return fmt.Errorf("failed to get project: %w", err)
	}

	if project.IsDefault {
		return fmt.Errorf("cannot delete default project")
	}

	return nil
}