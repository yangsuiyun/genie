package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/repositories"
	"pomodoro-backend/internal/services"
)

// ProjectHandler handles project-related HTTP requests
type ProjectHandler struct {
	projectService services.ProjectService
}

// NewProjectHandler creates a new project handler
func NewProjectHandler(projectService services.ProjectService) *ProjectHandler {
	return &ProjectHandler{
		projectService: projectService,
	}
}

// CreateProject handles POST /v1/projects
func (h *ProjectHandler) CreateProject(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	var req models.ProjectCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": err.Error()})
		return
	}

	project, err := h.projectService.CreateProject(userID, &req)
	if err != nil {
		if isValidationError(err) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "validation_error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to create project"})
		return
	}

	c.JSON(http.StatusCreated, project)
}

// GetProject handles GET /v1/projects/:id
func (h *ProjectHandler) GetProject(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Invalid project ID"})
		return
	}

	project, err := h.projectService.GetProject(projectID, userID)
	if err != nil {
		if isNotFoundError(err) || isAccessDeniedError(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not_found", "message": "Project not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to get project"})
		return
	}

	c.JSON(http.StatusOK, project)
}

// UpdateProject handles PUT /v1/projects/:id
func (h *ProjectHandler) UpdateProject(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Invalid project ID"})
		return
	}

	var req models.ProjectUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": err.Error()})
		return
	}

	project, err := h.projectService.UpdateProject(projectID, userID, &req)
	if err != nil {
		if isNotFoundError(err) || isAccessDeniedError(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not_found", "message": "Project not found"})
			return
		}
		if isValidationError(err) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "validation_error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to update project"})
		return
	}

	c.JSON(http.StatusOK, project)
}

// DeleteProject handles DELETE /v1/projects/:id
func (h *ProjectHandler) DeleteProject(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Invalid project ID"})
		return
	}

	err = h.projectService.DeleteProject(projectID, userID)
	if err != nil {
		if isNotFoundError(err) || isAccessDeniedError(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not_found", "message": "Project not found"})
			return
		}
		if isForbiddenError(err) {
			c.JSON(http.StatusForbidden, gin.H{"error": "forbidden", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to delete project"})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

// ListProjects handles GET /v1/projects
func (h *ProjectHandler) ListProjects(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	// Parse query parameters
	filter := &repositories.ProjectFilter{}

	// Parse pagination
	if pageStr := c.Query("page"); pageStr != "" {
		if page, err := strconv.Atoi(pageStr); err == nil && page > 0 {
			filter.Page = page
		} else {
			filter.Page = 1
		}
	} else {
		filter.Page = 1
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 && limit <= 100 {
			filter.Limit = limit
		} else {
			filter.Limit = 20
		}
	} else {
		filter.Limit = 20
	}

	// Parse filters
	if isCompletedStr := c.Query("is_completed"); isCompletedStr != "" {
		if isCompleted, err := strconv.ParseBool(isCompletedStr); err == nil {
			filter.IsCompleted = &isCompleted
		}
	}

	filter.SearchQuery = c.Query("search")
	filter.SortBy = c.Query("sort_by")
	filter.SortOrder = c.Query("sort_order")

	// Validate query parameters
	if filter.Page <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Page must be greater than 0"})
		return
	}

	if filter.Limit <= 0 || filter.Limit > 100 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Limit must be between 1 and 100"})
		return
	}

	projects, pagination, err := h.projectService.ListProjects(userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to list projects"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":       projects,
		"pagination": pagination,
	})
}

// GetProjectStatistics handles GET /v1/projects/:id/statistics
func (h *ProjectHandler) GetProjectStatistics(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Invalid project ID"})
		return
	}

	stats, err := h.projectService.GetProjectStatistics(projectID, userID)
	if err != nil {
		if isNotFoundError(err) || isAccessDeniedError(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not_found", "message": "Project not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to get project statistics"})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// ToggleProjectCompletion handles POST /v1/projects/:id/complete
func (h *ProjectHandler) ToggleProjectCompletion(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized", "message": "Invalid user context"})
		return
	}

	projectIDStr := c.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": "Invalid project ID"})
		return
	}

	var req models.ProjectCompletionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_request", "message": err.Error()})
		return
	}

	project, err := h.projectService.ToggleProjectCompletion(projectID, userID, &req)
	if err != nil {
		if isNotFoundError(err) || isAccessDeniedError(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "not_found", "message": "Project not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal_error", "message": "Failed to toggle project completion"})
		return
	}

	c.JSON(http.StatusOK, project)
}

// Helper functions for error checking
func getUserIDFromContext(c *gin.Context) (uuid.UUID, error) {
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, fmt.Errorf("user ID not found in context")
	}

	userIDStr, ok := userIDInterface.(string)
	if !ok {
		return uuid.Nil, fmt.Errorf("user ID is not a string")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return uuid.Nil, fmt.Errorf("invalid user ID format")
	}

	return userID, nil
}

func isValidationError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return contains(msg, "validation") ||
		   contains(msg, "required") ||
		   contains(msg, "invalid") ||
		   contains(msg, "must be") ||
		   contains(msg, "cannot be") ||
		   contains(msg, "already exists") ||
		   contains(msg, "reserved")
}

func isNotFoundError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return contains(msg, "not found")
}

func isAccessDeniedError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return contains(msg, "access denied")
}

func isForbiddenError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return contains(msg, "cannot delete") ||
		   contains(msg, "forbidden") ||
		   contains(msg, "not allowed")
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr ||
		(len(s) > len(substr) && s[:len(substr)] == substr) ||
		(len(s) > len(substr) && s[len(s)-len(substr):] == substr) ||
		(len(s) > len(substr) && strings.Contains(s, substr)))
}