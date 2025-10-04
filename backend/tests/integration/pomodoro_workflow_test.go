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

// TestCompletePomodoroWorkflow tests the complete Pomodoro workflow from quickstart scenario
// This test covers: User registration → Task creation → Pomodoro session → Task completion
func TestCompletePomodoroWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// This is a placeholder router that will fail until we implement actual handlers
	// Following TDD principle: write failing tests first
	router := setupTestRouter()

	t.Run("Complete Pomodoro Workflow", func(t *testing.T) {
		// Step 1: Register a new user
		registerReq := map[string]interface{}{
			"email":    "workflow@test.com",
			"password": "securePassword123",
			"name":     "Workflow Tester",
		}
		registerBody, _ := json.Marshal(registerReq)

		req, _ := http.NewRequest(http.MethodPost, "/auth/register", bytes.NewBuffer(registerBody))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This will fail until implemented - expected in TDD
		assert.Equal(t, http.StatusCreated, w.Code, "User registration should succeed")

		var registerResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &registerResp)
		require.NoError(t, err, "Register response should be valid JSON")

		// Extract auth token for subsequent requests
		authToken, exists := registerResp["token"].(string)
		require.True(t, exists, "Registration should return auth token")

		// Step 2: Create a task
		taskReq := map[string]interface{}{
			"title":       "Complete project documentation",
			"description": "Write comprehensive documentation for the new feature",
			"due_date":    time.Now().Add(24 * time.Hour).Format(time.RFC3339),
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Task creation should succeed")

		var taskResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &taskResp)
		require.NoError(t, err, "Task response should be valid JSON")

		taskID, exists := taskResp["id"].(string)
		require.True(t, exists, "Task creation should return task ID")

		// Step 3: Start a Pomodoro session for the task
		sessionReq := map[string]interface{}{
			"task_id":          taskID,
			"session_type":     "work",
			"planned_duration": 1500, // 25 minutes
		}
		sessionBody, _ := json.Marshal(sessionReq)

		req, _ = http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(sessionBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Pomodoro session should start successfully")

		var sessionResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &sessionResp)
		require.NoError(t, err, "Session response should be valid JSON")

		sessionID, exists := sessionResp["id"].(string)
		require.True(t, exists, "Session creation should return session ID")
		assert.Equal(t, "active", sessionResp["status"], "Session should be in active status")

		// Step 4: Complete the Pomodoro session
		completeReq := map[string]interface{}{
			"status":         "completed",
			"actual_duration": 1500,
		}
		completeBody, _ := json.Marshal(completeReq)

		req, _ = http.NewRequest(http.MethodPut, "/pomodoro/sessions/"+sessionID, bytes.NewBuffer(completeBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Session completion should succeed")

		var updatedSession map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &updatedSession)
		require.NoError(t, err, "Updated session response should be valid JSON")

		assert.Equal(t, "completed", updatedSession["status"], "Session should be marked as completed")

		// Step 5: Mark task as completed
		updateTaskReq := map[string]interface{}{
			"is_completed": true,
		}
		updateTaskBody, _ := json.Marshal(updateTaskReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/"+taskID, bytes.NewBuffer(updateTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task completion should succeed")

		var updatedTask map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &updatedTask)
		require.NoError(t, err, "Updated task response should be valid JSON")

		assert.Equal(t, true, updatedTask["is_completed"], "Task should be marked as completed")

		// Step 6: Verify workflow completion by checking reports
		req, _ = http.NewRequest(http.MethodGet, "/reports?period=day", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Report generation should succeed")

		var reportResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &reportResp)
		require.NoError(t, err, "Report response should be valid JSON")

		// Verify report contains our completed session
		sessions, exists := reportResp["completed_sessions"].([]interface{})
		require.True(t, exists, "Report should contain completed sessions")
		assert.Len(t, sessions, 1, "Should have one completed session")
	})
}

// TestPomodoroInterruptionWorkflow tests Pomodoro session with interruptions
func TestPomodoroInterruptionWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Pomodoro with Interruption", func(t *testing.T) {
		// Setup: Register user and create task (abbreviated for this test)
		authToken := "test-token" // In real implementation, this would come from registration
		taskID := "test-task-id"   // In real implementation, this would come from task creation

		// Start Pomodoro session
		sessionReq := map[string]interface{}{
			"task_id":          taskID,
			"session_type":     "work",
			"planned_duration": 1500,
		}
		sessionBody, _ := json.Marshal(sessionReq)

		req, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(sessionBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This will fail until implemented
		assert.Equal(t, http.StatusCreated, w.Code, "Session should start")

		var sessionResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &sessionResp)
		sessionID := sessionResp["id"].(string)

		// Record interruption
		interruptReq := map[string]interface{}{
			"interruption_count": 1,
			"interruption_reason": "phone_call",
		}
		interruptBody, _ := json.Marshal(interruptReq)

		req, _ = http.NewRequest(http.MethodPut, "/pomodoro/sessions/"+sessionID, bytes.NewBuffer(interruptBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Interruption recording should succeed")

		// Complete session with interruption
		completeReq := map[string]interface{}{
			"status": "completed",
			"actual_duration": 1200, // Completed early due to interruption
			"interruption_count": 1,
		}
		completeBody, _ := json.Marshal(completeReq)

		req, _ = http.NewRequest(http.MethodPut, "/pomodoro/sessions/"+sessionID, bytes.NewBuffer(completeBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Session completion with interruption should succeed")
	})
}

// TestPomodoroBreakCycle tests the complete work/break cycle
func TestPomodoroBreakCycle(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Complete Work-Break Cycle", func(t *testing.T) {
		authToken := "test-token"
		taskID := "test-task-id"

		// Work session
		workReq := map[string]interface{}{
			"task_id":          taskID,
			"session_type":     "work",
			"planned_duration": 1500,
		}
		workBody, _ := json.Marshal(workReq)

		req, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(workBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusCreated, w.Code, "Work session should start")

		// Short break session
		breakReq := map[string]interface{}{
			"task_id":          taskID,
			"session_type":     "short_break",
			"planned_duration": 300,
		}
		breakBody, _ := json.Marshal(breakReq)

		req, _ = http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(breakBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusCreated, w.Code, "Break session should start")

		// Verify break follows work session (business logic)
		// This tests the Pomodoro technique implementation
	})
}

// setupTestRouter creates a test router with placeholder handlers
// These handlers return 501 Not Implemented until actual implementation
func setupTestRouter() *gin.Engine {
	router := gin.New()

	// Auth endpoints
	router.POST("/auth/register", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})
	router.POST("/auth/login", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})

	// Task endpoints
	router.GET("/tasks", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})
	router.POST("/tasks", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})
	router.PUT("/tasks/:id", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})

	// Pomodoro endpoints
	router.POST("/pomodoro/sessions", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})
	router.PUT("/pomodoro/sessions/:id", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})

	// Reports endpoint
	router.GET("/reports", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})

	return router
}