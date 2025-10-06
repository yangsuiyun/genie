package services

import (
	"fmt"
	"strings"

	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/repositories"
)

// ProjectService interface defines project business logic
type ProjectService interface {
	// Core operations
	CreateProject(userID uuid.UUID, req *models.ProjectCreateRequest) (*models.Project, error)
	GetProject(projectID, userID uuid.UUID) (*models.ProjectWithStats, error)
	UpdateProject(projectID, userID uuid.UUID, req *models.ProjectUpdateRequest) (*models.Project, error)
	DeleteProject(projectID, userID uuid.UUID) error
	ToggleProjectCompletion(projectID, userID uuid.UUID, req *models.ProjectCompletionRequest) (*models.Project, error)

	// Query operations
	ListProjects(userID uuid.UUID, filter *repositories.ProjectFilter) ([]models.ProjectWithStats, *repositories.PaginationResult, error)
	GetProjectStatistics(projectID, userID uuid.UUID) (*models.ProjectStatistics, error)

	// User management
	EnsureDefaultProject(userID uuid.UUID) (*models.Project, error)
	GetOrCreateDefaultProject(userID uuid.UUID) (*models.Project, error)

	// Validation
	ValidateProjectAccess(projectID, userID uuid.UUID) error
	ValidateProjectName(userID uuid.UUID, name string, excludeID *uuid.UUID) error
}

// projectService implements ProjectService
type projectService struct {
	projectRepo repositories.ProjectRepository
}

// NewProjectService creates a new project service
func NewProjectService(projectRepo repositories.ProjectRepository) ProjectService {
	return &projectService{
		projectRepo: projectRepo,
	}
}

// CreateProject creates a new project
func (s *projectService) CreateProject(userID uuid.UUID, req *models.ProjectCreateRequest) (*models.Project, error) {
	// Validate input
	if err := s.validateCreateRequest(req); err != nil {
		return nil, err
	}

	// Check for duplicate names
	if err := s.ValidateProjectName(userID, req.Name, nil); err != nil {
		return nil, err
	}

	// Create project
	project := &models.Project{
		ID:          uuid.New(),
		UserID:      userID,
		Name:        strings.TrimSpace(req.Name),
		Description: strings.TrimSpace(req.Description),
		IsDefault:   false,
		IsCompleted: false,
	}

	if err := s.projectRepo.Create(project); err != nil {
		return nil, fmt.Errorf("failed to create project: %w", err)
	}

	return project, nil
}

// GetProject gets a project with statistics
func (s *projectService) GetProject(projectID, userID uuid.UUID) (*models.ProjectWithStats, error) {
	// Validate access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return nil, err
	}

	project, err := s.projectRepo.GetByIDWithStats(projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get project: %w", err)
	}

	if project == nil {
		return nil, fmt.Errorf("project not found")
	}

	return project, nil
}

// UpdateProject updates a project
func (s *projectService) UpdateProject(projectID, userID uuid.UUID, req *models.ProjectUpdateRequest) (*models.Project, error) {
	// Validate access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return nil, err
	}

	// Get existing project
	project, err := s.projectRepo.GetByID(projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get project: %w", err)
	}

	if project == nil {
		return nil, fmt.Errorf("project not found")
	}

	// Validate update request
	if err := s.validateUpdateRequest(req); err != nil {
		return nil, err
	}

	// Check for duplicate names if name is being changed
	if req.Name != nil && *req.Name != project.Name {
		if err := s.ValidateProjectName(userID, *req.Name, &projectID); err != nil {
			return nil, err
		}
		project.Name = strings.TrimSpace(*req.Name)
	}

	// Update fields
	if req.Description != nil {
		project.Description = strings.TrimSpace(*req.Description)
	}

	if req.IsCompleted != nil {
		project.IsCompleted = *req.IsCompleted
	}

	// Save changes
	if err := s.projectRepo.Update(project); err != nil {
		return nil, fmt.Errorf("failed to update project: %w", err)
	}

	return project, nil
}

// DeleteProject deletes a project
func (s *projectService) DeleteProject(projectID, userID uuid.UUID) error {
	// Validate access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return err
	}

	// Validate deletion
	if err := s.projectRepo.ValidateProjectDeletion(projectID); err != nil {
		return err
	}

	// Delete project
	if err := s.projectRepo.Delete(projectID); err != nil {
		return fmt.Errorf("failed to delete project: %w", err)
	}

	return nil
}

// ToggleProjectCompletion toggles the completion status of a project
func (s *projectService) ToggleProjectCompletion(projectID, userID uuid.UUID, req *models.ProjectCompletionRequest) (*models.Project, error) {
	// Validate access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return nil, err
	}

	// Toggle completion
	if err := s.projectRepo.ToggleCompletion(projectID, req.IsCompleted); err != nil {
		return nil, fmt.Errorf("failed to toggle project completion: %w", err)
	}

	// Return updated project
	project, err := s.projectRepo.GetByID(projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated project: %w", err)
	}

	return project, nil
}

// ListProjects lists projects for a user with filters and pagination
func (s *projectService) ListProjects(userID uuid.UUID, filter *repositories.ProjectFilter) ([]models.ProjectWithStats, *repositories.PaginationResult, error) {
	// Validate and set defaults for filter
	if filter == nil {
		filter = &repositories.ProjectFilter{}
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

	// Get projects with statistics
	projects, pagination, err := s.projectRepo.ListByUserIDWithStats(userID, filter)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to list projects: %w", err)
	}

	return projects, pagination, nil
}

// GetProjectStatistics gets detailed statistics for a project
func (s *projectService) GetProjectStatistics(projectID, userID uuid.UUID) (*models.ProjectStatistics, error) {
	// Validate access
	if err := s.ValidateProjectAccess(projectID, userID); err != nil {
		return nil, err
	}

	stats, err := s.projectRepo.GetProjectStatistics(projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to get project statistics: %w", err)
	}

	return stats, nil
}

// EnsureDefaultProject ensures a user has a default "Inbox" project
func (s *projectService) EnsureDefaultProject(userID uuid.UUID) (*models.Project, error) {
	// Check if default project exists
	defaultProject, err := s.projectRepo.GetDefaultProject(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check for default project: %w", err)
	}

	if defaultProject != nil {
		return defaultProject, nil
	}

	// Create default project
	defaultProject, err = s.projectRepo.CreateDefaultInboxProject(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to create default project: %w", err)
	}

	return defaultProject, nil
}

// GetOrCreateDefaultProject gets the default project or creates it if it doesn't exist
func (s *projectService) GetOrCreateDefaultProject(userID uuid.UUID) (*models.Project, error) {
	return s.EnsureDefaultProject(userID)
}

// ValidateProjectAccess validates that a user has access to a project
func (s *projectService) ValidateProjectAccess(projectID, userID uuid.UUID) error {
	hasAccess, err := s.projectRepo.CheckProjectOwnership(projectID, userID)
	if err != nil {
		return fmt.Errorf("failed to check project access: %w", err)
	}

	if !hasAccess {
		return fmt.Errorf("project not found or access denied")
	}

	return nil
}

// ValidateProjectName validates that a project name is unique for a user
func (s *projectService) ValidateProjectName(userID uuid.UUID, name string, excludeID *uuid.UUID) error {
	name = strings.TrimSpace(name)
	if name == "" {
		return fmt.Errorf("project name cannot be empty")
	}

	exists, err := s.projectRepo.CheckProjectNameExists(userID, name, excludeID)
	if err != nil {
		return fmt.Errorf("failed to check project name: %w", err)
	}

	if exists {
		return fmt.Errorf("project name already exists")
	}

	return nil
}

// validateCreateRequest validates a create project request
func (s *projectService) validateCreateRequest(req *models.ProjectCreateRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		return fmt.Errorf("project name is required")
	}

	if len(name) > 255 {
		return fmt.Errorf("project name must be 255 characters or less")
	}

	if len(req.Description) > 1000 {
		return fmt.Errorf("project description must be 1000 characters or less")
	}

	// Reserved names
	reservedNames := map[string]bool{
		"inbox":   true,
		"default": true,
		"archive": true,
		"trash":   true,
	}

	if reservedNames[strings.ToLower(name)] {
		return fmt.Errorf("project name '%s' is reserved", name)
	}

	return nil
}

// validateUpdateRequest validates an update project request
func (s *projectService) validateUpdateRequest(req *models.ProjectUpdateRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}

	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			return fmt.Errorf("project name cannot be empty")
		}

		if len(name) > 255 {
			return fmt.Errorf("project name must be 255 characters or less")
		}

		// Reserved names
		reservedNames := map[string]bool{
			"inbox":   true,
			"default": true,
			"archive": true,
			"trash":   true,
		}

		if reservedNames[strings.ToLower(name)] {
			return fmt.Errorf("project name '%s' is reserved", name)
		}
	}

	if req.Description != nil && len(*req.Description) > 1000 {
		return fmt.Errorf("project description must be 1000 characters or less")
	}

	return nil
}