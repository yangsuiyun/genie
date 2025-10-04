package integration

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestReportsGenerationWorkflow tests comprehensive report generation and analytics
// This covers the quickstart scenario: Create tasks → Complete Pomodoros → Generate reports
func TestReportsGenerationWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Complete Reports Generation Workflow", func(t *testing.T) {
		authToken := "test-token"

		// Step 1: Create multiple tasks for analysis
		tasks := []map[string]interface{}{
			{
				"title":       "Frontend development",
				"description": "Build user interface components",
				"tags":        []string{"development", "frontend"},
			},
			{
				"title":       "Backend API development",
				"description": "Implement REST API endpoints",
				"tags":        []string{"development", "backend"},
			},
			{
				"title":       "Database optimization",
				"description": "Optimize database queries and indexes",
				"tags":        []string{"database", "performance"},
			},
			{
				"title":       "Testing and QA",
				"description": "Write unit and integration tests",
				"tags":        []string{"testing", "quality"},
			},
		}

		var taskIDs []string
		for _, taskReq := range tasks {
			taskBody, _ := json.Marshal(taskReq)

			req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// This will fail until implemented - expected in TDD
			assert.Equal(t, http.StatusCreated, w.Code, "Task creation should succeed")

			var taskResp map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &taskResp)
			require.NoError(t, err, "Task response should be valid JSON")

			taskID, exists := taskResp["id"].(string)
			require.True(t, exists, "Task should have ID")
			taskIDs = append(taskIDs, taskID)
		}

		// Step 2: Complete multiple Pomodoro sessions for different tasks
		sessionData := []struct {
			taskIndex       int
			sessionType     string
			plannedDuration int
			actualDuration  int
			interruptions   int
		}{
			{0, "work", 1500, 1500, 0},      // Frontend: 25min, completed
			{0, "short_break", 300, 300, 0}, // Break after frontend
			{1, "work", 1500, 1200, 1},      // Backend: 20min, interrupted
			{1, "work", 1500, 1500, 0},      // Backend: 25min, completed
			{2, "work", 1500, 900, 2},       // Database: 15min, heavily interrupted
			{3, "work", 1500, 1500, 0},      // Testing: 25min, completed
		}

		var sessionIDs []string
		for _, session := range sessionData {
			// Start session
			sessionReq := map[string]interface{}{
				"task_id":          taskIDs[session.taskIndex],
				"session_type":     session.sessionType,
				"planned_duration": session.plannedDuration,
			}
			sessionBody, _ := json.Marshal(sessionReq)

			req, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(sessionBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusCreated, w.Code, "Pomodoro session should start")

			var sessionResp map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &sessionResp)
			require.NoError(t, err, "Session response should be valid JSON")

			sessionID, exists := sessionResp["id"].(string)
			require.True(t, exists, "Session should have ID")
			sessionIDs = append(sessionIDs, sessionID)

			// Complete session
			completeReq := map[string]interface{}{
				"status":             "completed",
				"actual_duration":    session.actualDuration,
				"interruption_count": session.interruptions,
			}
			completeBody, _ := json.Marshal(completeReq)

			req, _ = http.NewRequest(http.MethodPut, "/pomodoro/sessions/"+sessionID, bytes.NewBuffer(completeBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Session completion should succeed")
		}

		// Step 3: Generate daily report
		req, _ := http.NewRequest(http.MethodGet, "/reports?period=day", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Daily report generation should succeed")

		var dailyReportResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &dailyReportResp)
		require.NoError(t, err, "Daily report response should be valid JSON")

		// Verify daily report structure and content
		expectedFields := []string{"period", "total_sessions", "total_work_time", "total_break_time",
			"completed_sessions", "interrupted_sessions", "productivity_score", "tasks_worked_on"}

		for _, field := range expectedFields {
			_, exists := dailyReportResp[field]
			assert.True(t, exists, "Daily report should contain %s field", field)
		}

		// Verify metrics calculation
		totalSessions, exists := dailyReportResp["total_sessions"].(float64)
		require.True(t, exists, "Should have total sessions count")
		assert.Equal(t, float64(6), totalSessions, "Should count all 6 sessions")

		// Step 4: Generate weekly report with task breakdown
		req, _ = http.NewRequest(http.MethodGet, "/reports?period=week&include_tasks=true", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Weekly report generation should succeed")

		var weeklyReportResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &weeklyReportResp)
		require.NoError(t, err, "Weekly report response should be valid JSON")

		// Verify task breakdown
		taskBreakdown, exists := weeklyReportResp["task_breakdown"].([]interface{})
		require.True(t, exists, "Weekly report should include task breakdown")
		assert.GreaterOrEqual(t, len(taskBreakdown), 3, "Should have breakdown for worked-on tasks")

		// Step 5: Generate monthly report with trends
		req, _ = http.NewRequest(http.MethodGet, "/reports?period=month&include_trends=true", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Monthly report generation should succeed")

		var monthlyReportResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &monthlyReportResp)
		require.NoError(t, err, "Monthly report response should be valid JSON")

		// Verify trends data
		trends, exists := monthlyReportResp["trends"].(map[string]interface{})
		require.True(t, exists, "Monthly report should include trends")

		productivityTrend, exists := trends["productivity_trend"].([]interface{})
		require.True(t, exists, "Should have productivity trend data")
		assert.GreaterOrEqual(t, len(productivityTrend), 1, "Should have trend data points")
	})
}

// TestProductivityAnalytics tests detailed productivity analytics
func TestProductivityAnalytics(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Productivity Analytics", func(t *testing.T) {
		authToken := "test-token"

		// Test productivity score calculation
		req, _ := http.NewRequest(http.MethodGet, "/analytics/productivity", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Productivity analytics should succeed")

		var analyticsResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &analyticsResp)
		require.NoError(t, err, "Analytics response should be valid JSON")

		// Verify productivity metrics
		expectedMetrics := []string{"productivity_score", "focus_score", "completion_rate",
			"average_session_length", "interruption_rate", "optimal_work_periods"}

		for _, metric := range expectedMetrics {
			_, exists := analyticsResp[metric]
			assert.True(t, exists, "Analytics should contain %s metric", metric)
		}

		// Test time-based analytics
		startDate := time.Now().Add(-7 * 24 * time.Hour).Format("2006-01-02")
		endDate := time.Now().Format("2006-01-02")

		req, _ = http.NewRequest(http.MethodGet, "/analytics/productivity?start_date="+startDate+"&end_date="+endDate, nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Time-filtered analytics should succeed")
	})
}

// TestReportExport tests exporting reports in different formats
func TestReportExport(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Report Export Formats", func(t *testing.T) {
		authToken := "test-token"

		// Test CSV export
		req, _ := http.NewRequest(http.MethodGet, "/reports/export?format=csv&period=month", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "CSV export should succeed")
		assert.Equal(t, "text/csv", w.Header().Get("Content-Type"), "Should return CSV content type")

		// Test PDF export
		req, _ = http.NewRequest(http.MethodGet, "/reports/export?format=pdf&period=week", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "PDF export should succeed")
		assert.Equal(t, "application/pdf", w.Header().Get("Content-Type"), "Should return PDF content type")

		// Test JSON export (default)
		req, _ = http.NewRequest(http.MethodGet, "/reports/export?period=day", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "JSON export should succeed")
		assert.Equal(t, "application/json", w.Header().Get("Content-Type"), "Should return JSON content type")

		// Test invalid format
		req, _ = http.NewRequest(http.MethodGet, "/reports/export?format=invalid", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code, "Invalid format should return bad request")
	})
}

// TestReportPerformance tests report generation performance
func TestReportPerformance(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Report Generation Performance", func(t *testing.T) {
		authToken := "test-token"

		// Test performance for different report periods
		periods := []string{"day", "week", "month", "quarter", "year"}

		for _, period := range periods {
			start := time.Now()

			req, _ := http.NewRequest(http.MethodGet, "/reports?period="+period, nil)
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			duration := time.Since(start)

			// Even with placeholder handlers, response should be fast
			assert.Less(t, duration, 150*time.Millisecond,
				"Report generation for %s should complete within 150ms", period)
		}

		// Test performance with large dataset simulation
		start := time.Now()

		req, _ := http.NewRequest(http.MethodGet, "/reports?period=year&include_all_data=true", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		duration := time.Since(start)

		// Performance requirement: < 150ms for API responses
		assert.Less(t, duration, 150*time.Millisecond,
			"Large dataset report should complete within 150ms")
	})
}

// TestReportFiltering tests report filtering and customization
func TestReportFiltering(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Report Filtering and Customization", func(t *testing.T) {
		authToken := "test-token"

		// Test filtering by task tags
		req, _ := http.NewRequest(http.MethodGet, "/reports?period=month&tags=development,testing", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Tag-filtered report should succeed")

		// Test filtering by completion status
		req, _ = http.NewRequest(http.MethodGet, "/reports?period=week&completed_only=true", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Completion-filtered report should succeed")

		// Test custom date range
		startDate := time.Now().Add(-14 * 24 * time.Hour).Format("2006-01-02")
		endDate := time.Now().Add(-7 * 24 * time.Hour).Format("2006-01-02")

		req, _ = http.NewRequest(http.MethodGet, "/reports/custom?start_date="+startDate+"&end_date="+endDate, nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Custom date range report should succeed")

		// Test filtering by session type
		req, _ = http.NewRequest(http.MethodGet, "/reports?period=month&session_types=work", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Session type filtered report should succeed")
	})
}

// TestHistoricalDataAnalysis tests historical data analysis features
func TestHistoricalDataAnalysis(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Historical Data Analysis", func(t *testing.T) {
		authToken := "test-token"

		// Test productivity trends over time
		req, _ := http.NewRequest(http.MethodGet, "/analytics/trends?metric=productivity&period=3months", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Productivity trends should succeed")

		var trendsResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &trendsResp)
		require.NoError(t, err, "Trends response should be valid JSON")

		// Verify trend data structure
		dataPoints, exists := trendsResp["data_points"].([]interface{})
		require.True(t, exists, "Trends should contain data points")

		if len(dataPoints) > 0 {
			firstPoint := dataPoints[0].(map[string]interface{})
			expectedFields := []string{"date", "value", "moving_average"}

			for _, field := range expectedFields {
				_, exists := firstPoint[field]
				assert.True(t, exists, "Data point should contain %s field", field)
			}
		}

		// Test comparison with previous periods
		req, _ = http.NewRequest(http.MethodGet, "/analytics/compare?current_period=month&compare_period=previous_month", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Period comparison should succeed")

		var comparisonResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &comparisonResp)
		require.NoError(t, err, "Comparison response should be valid JSON")

		// Verify comparison structure
		expectedComparisons := []string{"current_period", "previous_period", "change_percentage", "improvement_areas"}

		for _, field := range expectedComparisons {
			_, exists := comparisonResp[field]
			assert.True(t, exists, "Comparison should contain %s field", field)
		}

		// Test goal tracking
		req, _ = http.NewRequest(http.MethodGet, "/analytics/goals", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Goal tracking should succeed")
	})
}