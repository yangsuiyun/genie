package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"backend/internal/services"
	"backend/internal/models"
)

// TaskHandler handles task-related HTTP requests
type TaskHandler struct {
	taskService *services.TaskService
	authHandler *AuthHandler
	validator   *validator.Validate
}

// NewTaskHandler creates a new task handler
func NewTaskHandler(taskService *services.TaskService, authHandler *AuthHandler) *TaskHandler {
	return &TaskHandler{
		taskService: taskService,
		authHandler: authHandler,
		validator:   validator.New(),
	}
}

// RegisterRoutes registers task routes
func (h *TaskHandler) RegisterRoutes(router *gin.RouterGroup) {
	tasks := router.Group("/tasks")
	tasks.Use(h.authHandler.RequireAuth()) // All task routes require authentication
	{
		tasks.GET("", h.GetTasks)
		tasks.POST("", h.CreateTask)
		tasks.GET("/:id", h.GetTask)
		tasks.PUT("/:id", h.UpdateTask)
		tasks.DELETE("/:id", h.DeleteTask)
		tasks.POST("/:id/complete", h.CompleteTask)

		// Subtask routes
		tasks.GET("/:id/subtasks", h.GetSubtasks)
		tasks.POST("/:id/subtasks", h.CreateSubtask)

		// Tag routes
		tasks.POST("/:id/tags", h.AddTag)
		tasks.DELETE("/:id/tags/:tag", h.RemoveTag)

		// Bulk operations
		tasks.POST("/bulk-update", h.BulkUpdateTasks)

		// Search and filtering
		tasks.GET("/search", h.SearchTasks)
		tasks.GET("/overdue", h.GetOverdueTasks)
		tasks.GET("/due-today", h.GetTasksDueToday)
		tasks.GET("/due-this-week", h.GetTasksDueThisWeek)

		// Statistics
		tasks.GET("/stats", h.GetTaskStats)
	}
}

// GetTasks retrieves tasks with pagination and filtering
// @Summary Get user tasks
// @Description Retrieve tasks for authenticated user with optional filtering and pagination
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Number of tasks to return" default(20)
// @Param offset query int false "Number of tasks to skip" default(0)
// @Param completed query bool false "Filter by completion status"
// @Param priority query string false "Filter by priority" Enums(low, medium, high, urgent)
// @Param due_before query string false "Filter tasks due before this date (ISO 8601)"
// @Param due_after query string false "Filter tasks due after this date (ISO 8601)"
// @Param tags query string false "Comma-separated list of tags to filter by"
// @Param parent_id query string false "Filter by parent task ID (for subtasks)"
// @Param sort_by query string false "Sort field" default(created_at)
// @Param sort_order query string false "Sort order" default(desc) Enums(asc, desc)
// @Success 200 {object} services.TaskListResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks [get]
func (h *TaskHandler) GetTasks(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	// Parse query parameters
	filter := models.TaskFilter{}

	if limit := c.Query("limit"); limit != "" {
		if l, err := strconv.Atoi(limit); err == nil {
			filter.Limit = l
		}
	}

	if offset := c.Query("offset"); offset != "" {
		if o, err := strconv.Atoi(offset); err == nil {
			filter.Offset = o
		}
	}

	if completed := c.Query("completed"); completed != "" {
		if comp, err := strconv.ParseBool(completed); err == nil {
			filter.IsCompleted = &comp
		}
	}

	if priority := c.Query("priority"); priority != "" {
		p := models.Priority(priority)
		if p.IsValid() {
			filter.Priority = &p
		}
	}

	if dueBefore := c.Query("due_before"); dueBefore != "" {
		if date, err := time.Parse(time.RFC3339, dueBefore); err == nil {
			filter.DueBefore = &date
		}
	}

	if dueAfter := c.Query("due_after"); dueAfter != "" {
		if date, err := time.Parse(time.RFC3339, dueAfter); err == nil {
			filter.DueAfter = &date
		}
	}

	if tags := c.Query("tags"); tags != "" {
		// Parse comma-separated tags
		filter.Tags = parseCommaSeparated(tags)
	}

	if parentID := c.Query("parent_id"); parentID != "" {
		if pid, err := uuid.Parse(parentID); err == nil {
			filter.ParentID = &pid
		}
	}

	filter.SortBy = c.DefaultQuery("sort_by", "created_at")
	filter.SortOrder = c.DefaultQuery("sort_order", "desc")
	filter.Search = c.Query("search")

	// Get tasks
	response, err := h.taskService.List(userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve tasks",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// CreateTask creates a new task
// @Summary Create a new task
// @Description Create a new task for the authenticated user
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body services.CreateTaskRequest true "Task creation request"
// @Success 201 {object} models.Task
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks [post]
func (h *TaskHandler) CreateTask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	var req services.CreateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	task, err := h.taskService.Create(userID, req)
	if err != nil {
		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "validation_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to create task",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, task)
}

// GetTask retrieves a single task by ID
// @Summary Get task by ID
// @Description Retrieve a specific task by its ID
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.Task
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks/{id} [get]
func (h *TaskHandler) GetTask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	task, err := h.taskService.GetByID(userID, taskID)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve task",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, task)
}

// UpdateTask updates an existing task
// @Summary Update a task
// @Description Update an existing task
// @Tags Tasks
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Param request body services.UpdateTaskRequest true "Task update request"
// @Success 200 {object} models.Task
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks/{id} [put]
func (h *TaskHandler) UpdateTask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	var req services.UpdateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	task, err := h.taskService.Update(userID, taskID, req)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "validation_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to update task",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, task)
}

// DeleteTask deletes a task
// @Summary Delete a task
// @Description Delete a task (soft delete)
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param id path string true "Task ID"
// @Success 204 "No Content"
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks/{id} [delete]
func (h *TaskHandler) DeleteTask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	err = h.taskService.Delete(userID, taskID)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to delete task",
			Details: err.Error(),
		})
		return
	}

	c.Status(http.StatusNoContent)
}

// CompleteTask marks a task as completed
// @Summary Complete a task
// @Description Mark a task as completed
// @Tags Tasks
// @Security BearerAuth
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.Task
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /tasks/{id}/complete [post]
func (h *TaskHandler) CompleteTask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	task, err := h.taskService.CompleteTask(userID, taskID)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to complete task",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, task)
}

// GetSubtasks retrieves subtasks for a parent task
func (h *TaskHandler) GetSubtasks(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	parentTaskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	subtasks, err := h.taskService.GetSubtasks(userID, parentTaskID)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Parent task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve subtasks",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"subtasks": subtasks,
		"count":    len(subtasks),
	})
}

// CreateSubtask creates a subtask under a parent task
func (h *TaskHandler) CreateSubtask(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	parentTaskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	var req services.CreateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	subtask, err := h.taskService.CreateSubtask(userID, parentTaskID, req)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Parent task not found",
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "validation_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to create subtask",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, subtask)
}

// AddTag adds a tag to a task
func (h *TaskHandler) AddTag(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	var req struct {
		Tag string `json:"tag" validate:"required,max=50"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	task, err := h.taskService.AddTagToTask(userID, taskID, req.Tag)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to add tag",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, task)
}

// RemoveTag removes a tag from a task
func (h *TaskHandler) RemoveTag(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	taskID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_task_id",
			Message: "Invalid task ID format",
		})
		return
	}

	tag := c.Param("tag")
	if tag == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_tag",
			Message: "Tag cannot be empty",
		})
		return
	}

	task, err := h.taskService.RemoveTagFromTask(userID, taskID, tag)
	if err != nil {
		if models.IsNotFoundError(err) || models.IsAuthorizationError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "task_not_found",
				Message: "Task not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to remove tag",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, task)
}

// BulkUpdateTasks updates multiple tasks at once
func (h *TaskHandler) BulkUpdateTasks(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	var req struct {
		Updates []struct {
			TaskID uuid.UUID                    `json:"task_id" validate:"required"`
			Update services.UpdateTaskRequest `json:"update" validate:"required"`
		} `json:"updates" validate:"required,min=1,max=100"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	err = h.taskService.BulkUpdateTasks(userID, req.Updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to bulk update tasks",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Tasks updated successfully",
	})
}

// SearchTasks searches for tasks
func (h *TaskHandler) SearchTasks(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "missing_query",
			Message: "Search query is required",
		})
		return
	}

	limit := 10
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 50 {
			limit = parsed
		}
	}

	tasks, err := h.taskService.SearchTasks(userID, query, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to search tasks",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"tasks": tasks,
		"count": len(tasks),
		"query": query,
	})
}

// GetOverdueTasks retrieves overdue tasks
func (h *TaskHandler) GetOverdueTasks(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	tasks, err := h.taskService.GetOverdueTasks(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve overdue tasks",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"tasks": tasks,
		"count": len(tasks),
	})
}

// GetTasksDueToday retrieves tasks due today
func (h *TaskHandler) GetTasksDueToday(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	tasks, err := h.taskService.GetTasksDueToday(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve tasks due today",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"tasks": tasks,
		"count": len(tasks),
	})
}

// GetTasksDueThisWeek retrieves tasks due this week
func (h *TaskHandler) GetTasksDueThisWeek(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	tasks, err := h.taskService.GetTasksDueThisWeek(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve tasks due this week",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, map[string]interface{}{
		"tasks": tasks,
		"count": len(tasks),
	})
}

// GetTaskStats retrieves task statistics
func (h *TaskHandler) GetTaskStats(c *gin.Context) {
	userID, err := h.getUserUUID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "Invalid user ID",
		})
		return
	}

	stats, err := h.taskService.GetTaskStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve task statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// Helper methods

func (h *TaskHandler) getUserUUID(c *gin.Context) (uuid.UUID, error) {
	userIDStr := h.authHandler.GetUserIDFromContext(c)
	return uuid.Parse(userIDStr)
}

func parseCommaSeparated(s string) []string {
	if s == "" {
		return []string{}
	}

	tags := []string{}
	for _, tag := range strings.Split(s, ",") {
		if trimmed := strings.TrimSpace(tag); trimmed != "" {
			tags = append(tags, trimmed)
		}
	}
	return tags
}