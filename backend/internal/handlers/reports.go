package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"pomodoro-backend/internal/services"
	"pomodoro-backend/internal/models"
)

// ReportsHandler handles reports and analytics-related HTTP requests
type ReportsHandler struct {
	reportService *services.ReportService
	validator     *validator.Validate
}

// NewReportsHandler creates a new reports handler
func NewReportsHandler(reportService *services.ReportService) *ReportsHandler {
	return &ReportsHandler{
		reportService: reportService,
		validator:     validator.New(),
	}
}

// RegisterRoutes registers reports routes
func (h *ReportsHandler) RegisterRoutes(router *gin.RouterGroup, authHandler *AuthHandler) {
	reports := router.Group("/reports")
	reports.Use(authHandler.RequireAuth())
	{
		reports.GET("", h.GetReports)
		reports.POST("", h.GenerateReport)
		reports.GET("/:reportId", h.GetReport)
		reports.PUT("/:reportId", h.UpdateReport)
		reports.DELETE("/:reportId", h.DeleteReport)
		reports.POST("/:reportId/export", h.ExportReport)
		reports.GET("/analytics/productivity", h.GetProductivityAnalytics)
		reports.GET("/analytics/trends", h.GetTrendAnalytics)
		reports.GET("/analytics/summary", h.GetSummaryAnalytics)
		reports.GET("/analytics/comparison", h.GetComparisonAnalytics)
	}
}

// GetReports retrieves reports for the authenticated user
// @Summary Get reports
// @Description Retrieve reports with filtering and pagination
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param page query int false "Page number (default: 1)"
// @Param limit query int false "Items per page (default: 20, max: 100)"
// @Param type query string false "Filter by report type"
// @Param period query string false "Filter by report period"
// @Param date_from query string false "Filter reports from date (RFC3339)"
// @Param date_to query string false "Filter reports to date (RFC3339)"
// @Success 200 {object} PaginatedReportsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports [get]
func (h *ReportsHandler) GetReports(c *gin.Context) {
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
	var req services.GetReportsRequest
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
	if reportType := c.Query("type"); reportType != "" {
		req.Type = reportType
	}

	if period := c.Query("period"); period != "" {
		req.Period = period
	}

	if dateFrom := c.Query("date_from"); dateFrom != "" {
		req.DateFrom = dateFrom
	}

	if dateTo := c.Query("date_to"); dateTo != "" {
		req.DateTo = dateTo
	}

	// Get reports
	response, err := h.reportService.GetReports(req)
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
			Message: "Failed to retrieve reports",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GenerateReport generates a new report
// @Summary Generate a new report
// @Description Generate a new analytics report for the user
// @Tags Reports
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body services.GenerateReportRequest true "Generate report request"
// @Success 201 {object} models.Report
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports [post]
func (h *ReportsHandler) GenerateReport(c *gin.Context) {
	var req services.GenerateReportRequest

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

	// Generate report
	report, err := h.reportService.GenerateReport(userID, req)
	if err != nil {
		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "report_generation_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to generate report",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, report)
}

// GetReport retrieves a specific report
// @Summary Get report
// @Description Retrieve a specific report by ID
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param reportId path string true "Report ID"
// @Success 200 {object} models.Report
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/{reportId} [get]
func (h *ReportsHandler) GetReport(c *gin.Context) {
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

	// Parse report ID
	reportIDStr := c.Param("reportId")
	reportID, err := uuid.Parse(reportIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_report_id",
			Message: "Invalid report ID format",
		})
		return
	}

	// Get report
	report, err := h.reportService.GetReport(userID, reportID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "report_not_found",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to retrieve report",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, report)
}

// UpdateReport updates a report
// @Summary Update report
// @Description Update a report's properties
// @Tags Reports
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param reportId path string true "Report ID"
// @Param request body services.UpdateReportRequest true "Update report request"
// @Success 200 {object} models.Report
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/{reportId} [put]
func (h *ReportsHandler) UpdateReport(c *gin.Context) {
	var req services.UpdateReportRequest

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

	// Parse report ID
	reportIDStr := c.Param("reportId")
	reportID, err := uuid.Parse(reportIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_report_id",
			Message: "Invalid report ID format",
		})
		return
	}

	// Update report
	report, err := h.reportService.UpdateReport(userID, reportID, req)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "report_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "report_update_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to update report",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, report)
}

// DeleteReport deletes a report
// @Summary Delete report
// @Description Delete a report
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param reportId path string true "Report ID"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/{reportId} [delete]
func (h *ReportsHandler) DeleteReport(c *gin.Context) {
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

	// Parse report ID
	reportIDStr := c.Param("reportId")
	reportID, err := uuid.Parse(reportIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_report_id",
			Message: "Invalid report ID format",
		})
		return
	}

	// Delete report
	err = h.reportService.DeleteReport(userID, reportID)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "report_not_found",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to delete report",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Report deleted successfully",
	})
}

// ExportReport exports a report in various formats
// @Summary Export report
// @Description Export a report to different formats (PDF, CSV, JSON)
// @Tags Reports
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param reportId path string true "Report ID"
// @Param request body services.ExportReportRequest true "Export report request"
// @Success 200 {object} services.ExportReportResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/{reportId}/export [post]
func (h *ReportsHandler) ExportReport(c *gin.Context) {
	var req services.ExportReportRequest

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

	// Parse report ID
	reportIDStr := c.Param("reportId")
	reportID, err := uuid.Parse(reportIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_report_id",
			Message: "Invalid report ID format",
		})
		return
	}

	// Export report
	response, err := h.reportService.ExportReport(userID, reportID, req)
	if err != nil {
		if models.IsNotFoundError(err) {
			c.JSON(http.StatusNotFound, ErrorResponse{
				Error:   "report_not_found",
				Message: err.Error(),
			})
			return
		}

		if models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "export_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to export report",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetProductivityAnalytics retrieves productivity analytics
// @Summary Get productivity analytics
// @Description Get detailed productivity analytics and metrics
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param period query string false "Analytics period (day, week, month, year)"
// @Param date_from query string false "Analytics from date (RFC3339)"
// @Param date_to query string false "Analytics to date (RFC3339)"
// @Param include_trends query bool false "Include trend analysis"
// @Success 200 {object} services.ProductivityAnalyticsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/analytics/productivity [get]
func (h *ReportsHandler) GetProductivityAnalytics(c *gin.Context) {
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
	var req services.GetProductivityAnalyticsRequest
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

	if includeTrendsStr := c.Query("include_trends"); includeTrendsStr != "" {
		if includeTrends, err := strconv.ParseBool(includeTrendsStr); err == nil {
			req.IncludeTrends = includeTrends
		}
	}

	// Get analytics
	analytics, err := h.reportService.GetProductivityAnalytics(req)
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
			Message: "Failed to get productivity analytics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, analytics)
}

// GetTrendAnalytics retrieves trend analytics
// @Summary Get trend analytics
// @Description Get trend analysis and historical data patterns
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param metric query string false "Specific metric for trend analysis"
// @Param period query string false "Analytics period (day, week, month, year)"
// @Param date_from query string false "Analytics from date (RFC3339)"
// @Param date_to query string false "Analytics to date (RFC3339)"
// @Success 200 {object} services.TrendAnalyticsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/analytics/trends [get]
func (h *ReportsHandler) GetTrendAnalytics(c *gin.Context) {
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
	var req services.GetTrendAnalyticsRequest
	req.UserID = userID

	if metric := c.Query("metric"); metric != "" {
		req.Metric = metric
	}

	if period := c.Query("period"); period != "" {
		req.Period = period
	}

	if dateFrom := c.Query("date_from"); dateFrom != "" {
		req.DateFrom = dateFrom
	}

	if dateTo := c.Query("date_to"); dateTo != "" {
		req.DateTo = dateTo
	}

	// Get trend analytics
	trends, err := h.reportService.GetTrendAnalytics(req)
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
			Message: "Failed to get trend analytics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, trends)
}

// GetSummaryAnalytics retrieves summary analytics
// @Summary Get summary analytics
// @Description Get high-level summary analytics and key metrics
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param period query string false "Analytics period (day, week, month, year)"
// @Success 200 {object} services.SummaryAnalyticsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/analytics/summary [get]
func (h *ReportsHandler) GetSummaryAnalytics(c *gin.Context) {
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
	var req services.GetSummaryAnalyticsRequest
	req.UserID = userID

	if period := c.Query("period"); period != "" {
		req.Period = period
	}

	// Get summary analytics
	summary, err := h.reportService.GetSummaryAnalytics(req)
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
			Message: "Failed to get summary analytics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, summary)
}

// GetComparisonAnalytics retrieves comparison analytics
// @Summary Get comparison analytics
// @Description Get comparative analytics between different periods or metrics
// @Tags Reports
// @Security BearerAuth
// @Produce json
// @Param base_period query string true "Base period for comparison"
// @Param compare_period query string true "Period to compare against base"
// @Param metrics query string false "Comma-separated list of metrics to compare"
// @Success 200 {object} services.ComparisonAnalyticsResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /reports/analytics/comparison [get]
func (h *ReportsHandler) GetComparisonAnalytics(c *gin.Context) {
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
	var req services.GetComparisonAnalyticsRequest
	req.UserID = userID

	if basePeriod := c.Query("base_period"); basePeriod != "" {
		req.BasePeriod = basePeriod
	}

	if comparePeriod := c.Query("compare_period"); comparePeriod != "" {
		req.ComparePeriod = comparePeriod
	}

	if metricsStr := c.Query("metrics"); metricsStr != "" {
		req.Metrics = strings.Split(metricsStr, ",")
		// Trim whitespace from each metric
		for i, metric := range req.Metrics {
			req.Metrics[i] = strings.TrimSpace(metric)
		}
	}

	// Get comparison analytics
	comparison, err := h.reportService.GetComparisonAnalytics(req)
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
			Message: "Failed to get comparison analytics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, comparison)
}

// Helper methods from AuthHandler
func (h *ReportsHandler) GetUserIDFromContext(c *gin.Context) string {
	userID, exists := c.Get("user_id")
	if !exists {
		return ""
	}
	return userID.(string)
}

// Response types

type PaginatedReportsResponse struct {
	Reports    []*models.Report `json:"reports"`
	Pagination PaginationInfo   `json:"pagination"`
}