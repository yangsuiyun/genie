package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"backend/internal/services"
	"backend/internal/models"
)

// PomodoroHandler handles pomodoro session-related HTTP requests
type PomodoroHandler struct {
	pomodoroService *services.PomodoroService
	validator       *validator.Validate
}

// NewPomodoroHandler creates a new pomodoro handler
func NewPomodoroHandler(pomodoroService *services.PomodoroService) *PomodoroHandler {
	return &PomodoroHandler{
		pomodoroService: pomodoroService,
		validator:       validator.New(),
	}
}

// RegisterRoutes registers pomodoro routes
func (h *PomodoroHandler) RegisterRoutes(router *gin.RouterGroup, authHandler *AuthHandler) {
	pomodoro := router.Group("/pomodoro")
	pomodoro.Use(authHandler.RequireAuth())
	{
		pomodoro.POST("/sessions", h.StartSession)
		pomodoro.GET("/sessions", h.GetSessions)
		pomodoro.GET("/sessions/:sessionId", h.GetSession)
		pomodoro.PUT("/sessions/:sessionId", h.UpdateSession)
		pomodoro.DELETE("/sessions/:sessionId", h.DeleteSession)
		pomodoro.POST("/sessions/:sessionId/pause", h.PauseSession)
		pomodoro.POST("/sessions/:sessionId/resume", h.ResumeSession)
		pomodoro.POST("/sessions/:sessionId/complete", h.CompleteSession)
		pomodoro.GET("/sessions/:sessionId/suggestions", h.GetSessionSuggestions)
		pomodoro.GET("/statistics", h.GetStatistics)
	}
}

// StartSession starts a new pomodoro session
// @Summary Start a new pomodoro session
// @Description Create and start a new pomodoro session for a task
// @Tags Pomodoro
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body services.StartSessionRequest true "Start session request"
// @Success 201 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions [post]
func (h *PomodoroHandler) StartSession(c *gin.Context) {
	var req services.StartSessionRequest

	// Bind JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Validate request
	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Start session
	session, err := h.pomodoroService.StartSession(userID, req)
	if err != nil {
		if models.IsValidationError(err) || models.IsNotFoundError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "session_start_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to start session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, session)
}

// GetSessions retrieves pomodoro sessions for the authenticated user
// @Summary Get pomodoro sessions
// @Description Retrieve pomodoro sessions with filtering and pagination
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param page query int false "Page number (default: 1)"
// @Param limit query int false "Items per page (default: 20, max: 100)"
// @Param status query string false "Filter by session status"
// @Param task_id query string false "Filter by task ID"
// @Param date_from query string false "Filter sessions from date (RFC3339)"
// @Param date_to query string false "Filter sessions to date (RFC3339)"
// @Success 200 {object} PaginatedSessionsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions [get]
func (h *PomodoroHandler) GetSessions(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse query parameters
	var req services.GetSessionsRequest
	req.UserID = userID

	// Parse pagination
	if pageStr := c.Query("page"); pageStr != "" {
		if page, err := strconv.Atoi(pageStr); err == nil && page > 0 {
			req.Page = page
		}
	}
	if req.Page == 0 {
		req.Page = 1
	}

	if limitStr := c.Query("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 && limit <= 100 {
			req.Limit = limit
		}
	}
	if req.Limit == 0 {
		req.Limit = 20
	}

	// Parse filters
	if status := c.Query("status"); status != "" {
		req.Status = status
	}

	if taskIDStr := c.Query("task_id"); taskIDStr != "" {
		if taskID, err := uuid.Parse(taskIDStr); err == nil {
			req.TaskID = &taskID
		}
	}

	if dateFrom := c.Query("date_from"); dateFrom != "" {
		req.DateFrom = dateFrom
	}

	if dateTo := c.Query("date_to"); dateTo != "" {
		req.DateTo = dateTo
	}

	// Get sessions
	response, err := h.pomodoroService.GetSessions(req)
	if err != nil {
		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "invalid_request",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve sessions",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetSession retrieves a specific pomodoro session
// @Summary Get pomodoro session
// @Description Retrieve a specific pomodoro session by ID
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId} [get]
func (h *PomodoroHandler) GetSession(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Get session
	session, err := h.pomodoroService.GetSession(userID, sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, session)
}

// UpdateSession updates a pomodoro session
// @Summary Update pomodoro session
// @Description Update a pomodoro session's properties
// @Tags Pomodoro
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param sessionId path string true "Session ID"
// @Param request body services.UpdateSessionRequest true "Update session request"
// @Success 200 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId} [put]
func (h *PomodoroHandler) UpdateSession(c *gin.Context) {
	var req services.UpdateSessionRequest

	// Bind JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Validate request
	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Update session
	session, err := h.pomodoroService.UpdateSession(userID, sessionID, req)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "session_update_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to update session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, session)
}

// DeleteSession deletes a pomodoro session
// @Summary Delete pomodoro session
// @Description Delete a pomodoro session
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId} [delete]
func (h *PomodoroHandler) DeleteSession(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Delete session
	err = h.pomodoroService.DeleteSession(userID, sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to delete session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Session deleted successfully",
	})
}

// PauseSession pauses a running pomodoro session
// @Summary Pause pomodoro session
// @Description Pause a currently running pomodoro session
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId}/pause [post]
func (h *PomodoroHandler) PauseSession(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Pause session
	session, err := h.pomodoroService.PauseSession(userID, sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "session_pause_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to pause session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, session)
}

// ResumeSession resumes a paused pomodoro session
// @Summary Resume pomodoro session
// @Description Resume a paused pomodoro session
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId}/resume [post]
func (h *PomodoroHandler) ResumeSession(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Resume session
	session, err := h.pomodoroService.ResumeSession(userID, sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "session_resume_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to resume session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, session)
}

// CompleteSession completes a pomodoro session
// @Summary Complete pomodoro session
// @Description Mark a pomodoro session as completed
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} models.PomodoroSession
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId}/complete [post]
func (h *PomodoroHandler) CompleteSession(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse session ID
	sessionIDStr := c.Param("sessionId")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_session_id",
			Message: "Invalid session ID format",
		})
		return
	}

	// Complete session
	session, err := h.pomodoroService.CompleteSession(userID, sessionID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "session_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "session_complete_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to complete session",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, session)
}

// GetSessionSuggestions gets session suggestions for a user
// @Summary Get session suggestions
// @Description Get suggested session configurations based on user patterns
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param sessionId path string true "Session ID"
// @Success 200 {object} services.SessionSuggestionsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/sessions/{sessionId}/suggestions [get]
func (h *PomodoroHandler) GetSessionSuggestions(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Get suggestions
	suggestions, err := h.pomodoroService.GetSessionSuggestions(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to get session suggestions",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, suggestions)
}

// GetStatistics gets pomodoro statistics for a user
// @Summary Get pomodoro statistics
// @Description Get pomodoro session statistics and analytics
// @Tags Pomodoro
// @Security BearerAuth
// @Produce json
// @Param period query string false "Statistics period (day, week, month, year)"
// @Param date_from query string false "Statistics from date (RFC3339)"
// @Param date_to query string false "Statistics to date (RFC3339)"
// @Success 200 {object} services.StatisticsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /pomodoro/statistics [get]
func (h *PomodoroHandler) GetStatistics(c *gin.Context) {
	// Get user ID from context
	userIDStr := h.GetUserIDFromContext(c)
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	// Parse query parameters
	var req services.GetStatisticsRequest
	req.UserID = userID

	if period := c.Query("period"); period != "" {
		req.Period = period
	}

	if dateFrom := c.Query("date_from"); dateFrom != "" {
		req.DateFrom = dateFrom
	}

	if dateTo := c.Query("date_to"); dateTo != "" {
		req.DateTo = dateTo
	}

	// Get statistics
	statistics, err := h.pomodoroService.GetStatistics(req)
	if err != nil {
		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "invalid_request",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to get statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, statistics)
}

// Helper methods from AuthHandler
func (h *PomodoroHandler) GetUserIDFromContext(c *gin.Context) string {
	userID, exists := c.Get("user_id")
	if !exists {
		return ""
	}
	return userID.(string)
}

// Response types

type PaginatedSessionsResponse struct {
	Sessions   []*models.PomodoroSession `json:"sessions"`
	Pagination PaginationInfo            `json:"pagination"`
}

type PaginationInfo struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	TotalCount int64 `json:"total_count"`
	TotalPages int   `json:"total_pages"`
}