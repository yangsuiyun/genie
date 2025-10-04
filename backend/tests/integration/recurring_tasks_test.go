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

// TestRecurringTasksWorkflow tests complete recurring task management workflow
// This covers: Recurring task creation → Instance generation → Completion tracking → Schedule updates
func TestRecurringTasksWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Complete Recurring Tasks Workflow", func(t *testing.T) {
		authToken := "test-token"

		// Step 1: Create daily recurring task
		dailyTaskReq := map[string]interface{}{
			"title":       "Daily standup meeting",
			"description": "Attend daily team standup meeting",
			"recurrence_rule": map[string]interface{}{
				"frequency":  "daily",
				"interval":   1,
				"start_date": time.Now().Format("2006-01-02"),
				"end_date":   time.Now().Add(30 * 24 * time.Hour).Format("2006-01-02"), // 30 days
				"time":       "09:00",
				"timezone":   "UTC",
			},
			"tags": []string{"meeting", "daily", "team"},
		}
		dailyTaskBody, _ := json.Marshal(dailyTaskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(dailyTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This will fail until implemented - expected in TDD
		assert.Equal(t, http.StatusCreated, w.Code, "Daily recurring task creation should succeed")

		var dailyTaskResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &dailyTaskResp)
		require.NoError(t, err, "Daily task response should be valid JSON")

		dailyTaskID, exists := dailyTaskResp["id"].(string)
		require.True(t, exists, "Daily task should have ID")

		// Verify recurrence rule
		recurrenceRule, exists := dailyTaskResp["recurrence_rule"].(map[string]interface{})
		require.True(t, exists, "Task should have recurrence rule")
		assert.Equal(t, "daily", recurrenceRule["frequency"], "Should have daily frequency")

		// Step 2: Create weekly recurring task
		weeklyTaskReq := map[string]interface{}{
			"title":       "Weekly project review",
			"description": "Review project progress and update stakeholders",
			"recurrence_rule": map[string]interface{}{
				"frequency":    "weekly",
				"interval":     1,
				"days_of_week": []string{"friday"},
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "15:00",
				"timezone":     "UTC",
			},
			"tags": []string{"review", "weekly", "project"},
		}
		weeklyTaskBody, _ := json.Marshal(weeklyTaskReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(weeklyTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Weekly recurring task creation should succeed")

		var weeklyTaskResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &weeklyTaskResp)
		require.NoError(t, err, "Weekly task response should be valid JSON")

		_, exists = weeklyTaskResp["id"].(string)
		require.True(t, exists, "Weekly task should have ID")

		// Step 3: Create monthly recurring task with custom pattern
		monthlyTaskReq := map[string]interface{}{
			"title":       "Monthly expense report",
			"description": "Compile and submit monthly expense report",
			"recurrence_rule": map[string]interface{}{
				"frequency":         "monthly",
				"interval":          1,
				"day_of_month":      "last_friday",
				"start_date":        time.Now().Format("2006-01-02"),
				"time":              "17:00",
				"timezone":          "UTC",
				"skip_weekends":     true,
				"skip_holidays":     true,
			},
			"tags": []string{"expense", "monthly", "finance"},
		}
		monthlyTaskBody, _ := json.Marshal(monthlyTaskReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(monthlyTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Monthly recurring task creation should succeed")

		// Step 4: Test recurring task instance generation
		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring/"+dailyTaskID+"/generate", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task instance generation should succeed")

		var generationResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &generationResp)
		require.NoError(t, err, "Generation response should be valid JSON")

		generatedCount, exists := generationResp["generated_count"].(float64)
		require.True(t, exists, "Should return generated count")
		assert.GreaterOrEqual(t, generatedCount, float64(1), "Should generate at least one instance")

		// Step 5: Get upcoming recurring task instances
		req, _ = http.NewRequest(http.MethodGet, "/tasks/recurring/upcoming?days=7", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Upcoming instances retrieval should succeed")

		var upcomingResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &upcomingResp)
		require.NoError(t, err, "Upcoming response should be valid JSON")

		upcomingTasks, exists := upcomingResp["upcoming_tasks"].([]interface{})
		require.True(t, exists, "Should return upcoming tasks")
		assert.GreaterOrEqual(t, len(upcomingTasks), 1, "Should have upcoming task instances")

		// Step 6: Complete a recurring task instance
		if len(upcomingTasks) > 0 {
			firstTask := upcomingTasks[0].(map[string]interface{})
			instanceID := firstTask["id"].(string)

			completeReq := map[string]interface{}{
				"is_completed": true,
				"completed_at": time.Now().Format(time.RFC3339),
			}
			completeBody, _ := json.Marshal(completeReq)

			req, _ = http.NewRequest(http.MethodPut, "/tasks/"+instanceID, bytes.NewBuffer(completeBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Recurring task instance completion should succeed")

			// Verify completion tracking
			req, _ = http.NewRequest(http.MethodGet, "/tasks/recurring/"+dailyTaskID+"/stats", nil)
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Recurring task stats should succeed")

			var statsResp map[string]interface{}
			err = json.Unmarshal(w.Body.Bytes(), &statsResp)
			require.NoError(t, err, "Stats response should be valid JSON")

			completionRate, exists := statsResp["completion_rate"].(float64)
			require.True(t, exists, "Should have completion rate")
			assert.GreaterOrEqual(t, completionRate, 0.0, "Completion rate should be valid")
		}
	})
}

// TestRecurrencePatterns tests various recurrence patterns and edge cases
func TestRecurrencePatterns(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Complex Recurrence Patterns", func(t *testing.T) {
		authToken := "test-token"

		// Test every 2 weeks on specific days
		biweeklyTaskReq := map[string]interface{}{
			"title":       "Bi-weekly team retrospective",
			"description": "Conduct team retrospective meeting",
			"recurrence_rule": map[string]interface{}{
				"frequency":    "weekly",
				"interval":     2,
				"days_of_week": []string{"tuesday", "thursday"},
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "14:00",
			},
		}
		biweeklyTaskBody, _ := json.Marshal(biweeklyTaskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(biweeklyTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Bi-weekly recurring task should be created")

		// Test quarterly recurrence
		quarterlyTaskReq := map[string]interface{}{
			"title":       "Quarterly business review",
			"description": "Conduct quarterly business review with leadership",
			"recurrence_rule": map[string]interface{}{
				"frequency":    "monthly",
				"interval":     3,
				"day_of_month": 15,
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "10:00",
			},
		}
		quarterlyTaskBody, _ := json.Marshal(quarterlyTaskReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(quarterlyTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Quarterly recurring task should be created")

		// Test custom workday pattern (Monday to Friday, excluding holidays)
		workdayTaskReq := map[string]interface{}{
			"title":       "Daily email check",
			"description": "Check and respond to important emails",
			"recurrence_rule": map[string]interface{}{
				"frequency":    "daily",
				"interval":     1,
				"days_of_week": []string{"monday", "tuesday", "wednesday", "thursday", "friday"},
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "08:30",
				"skip_holidays": true,
			},
		}
		workdayTaskBody, _ := json.Marshal(workdayTaskReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(workdayTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Workday recurring task should be created")
	})
}

// TestRecurringTaskModification tests modifying recurring tasks and their instances
func TestRecurringTaskModification(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Recurring Task Modification", func(t *testing.T) {
		authToken := "test-token"

		// Create a recurring task
		taskReq := map[string]interface{}{
			"title":       "Weekly team meeting",
			"description": "Regular team sync meeting",
			"recurrence_rule": map[string]interface{}{
				"frequency":    "weekly",
				"interval":     1,
				"days_of_week": []string{"monday"},
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "10:00",
			},
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Recurring task creation should succeed")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Update recurrence rule (change time and day)
		updateReq := map[string]interface{}{
			"title": "Weekly team sync", // Updated title
			"recurrence_rule": map[string]interface{}{
				"frequency":    "weekly",
				"interval":     1,
				"days_of_week": []string{"tuesday"}, // Changed day
				"start_date":   time.Now().Format("2006-01-02"),
				"time":         "14:00", // Changed time
			},
		}
		updateBody, _ := json.Marshal(updateReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/recurring/"+taskID, bytes.NewBuffer(updateBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Recurring task update should succeed")

		// Test modifying future instances only
		futureUpdateReq := map[string]interface{}{
			"description": "Updated description for future instances",
			"apply_to":    "future_only",
		}
		futureUpdateBody, _ := json.Marshal(futureUpdateReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/recurring/"+taskID+"/future", bytes.NewBuffer(futureUpdateBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Future instances update should succeed")

		// Test pausing recurring task
		pauseReq := map[string]interface{}{
			"paused": true,
			"pause_until": time.Now().Add(7 * 24 * time.Hour).Format("2006-01-02"),
		}
		pauseBody, _ := json.Marshal(pauseReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/recurring/"+taskID+"/pause", bytes.NewBuffer(pauseBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Recurring task pause should succeed")
	})
}

// TestRecurringTaskExceptions tests handling exceptions in recurring tasks
func TestRecurringTaskExceptions(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Recurring Task Exceptions", func(t *testing.T) {
		authToken := "test-token"

		// Create recurring task
		taskReq := map[string]interface{}{
			"title": "Daily standup",
			"recurrence_rule": map[string]interface{}{
				"frequency":  "daily",
				"interval":   1,
				"start_date": time.Now().Format("2006-01-02"),
				"time":       "09:00",
			},
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Recurring task should be created")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Add exception date (skip specific date)
		exceptionReq := map[string]interface{}{
			"exception_date": time.Now().Add(3 * 24 * time.Hour).Format("2006-01-02"),
			"exception_type": "skip",
			"reason":         "National holiday",
		}
		exceptionBody, _ := json.Marshal(exceptionReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring/"+taskID+"/exceptions", bytes.NewBuffer(exceptionBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Exception creation should succeed")

		// Add rescheduled exception
		rescheduleReq := map[string]interface{}{
			"exception_date":    time.Now().Add(5 * 24 * time.Hour).Format("2006-01-02"),
			"exception_type":    "reschedule",
			"new_date":          time.Now().Add(6 * 24 * time.Hour).Format("2006-01-02"),
			"new_time":          "10:00",
			"reason":            "Conflict with important meeting",
		}
		rescheduleBody, _ := json.Marshal(rescheduleReq)

		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring/"+taskID+"/exceptions", bytes.NewBuffer(rescheduleBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Reschedule exception should succeed")

		// Get exceptions list
		req, _ = http.NewRequest(http.MethodGet, "/tasks/recurring/"+taskID+"/exceptions", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Exceptions listing should succeed")

		var exceptionsResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &exceptionsResp)
		require.NoError(t, err, "Exceptions response should be valid JSON")

		exceptions, exists := exceptionsResp["exceptions"].([]interface{})
		require.True(t, exists, "Should return exceptions list")
		assert.Len(t, exceptions, 2, "Should have 2 exceptions")
	})
}

// TestRecurringTaskCompletion tests completion tracking for recurring tasks
func TestRecurringTaskCompletion(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Recurring Task Completion Tracking", func(t *testing.T) {
		authToken := "test-token"

		// Create recurring task and generate instances
		taskReq := map[string]interface{}{
			"title": "Daily exercise",
			"recurrence_rule": map[string]interface{}{
				"frequency":  "daily",
				"interval":   1,
				"start_date": time.Now().Add(-7 * 24 * time.Hour).Format("2006-01-02"), // Started 7 days ago
				"time":       "07:00",
			},
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks/recurring", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Recurring task should be created")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Generate past instances
		req, _ = http.NewRequest(http.MethodPost, "/tasks/recurring/"+taskID+"/generate", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Instance generation should succeed")

		// Get completion statistics
		req, _ = http.NewRequest(http.MethodGet, "/tasks/recurring/"+taskID+"/completion-stats", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Completion stats should succeed")

		var statsResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &statsResp)
		require.NoError(t, err, "Stats response should be valid JSON")

		// Verify completion statistics structure
		expectedStats := []string{"total_instances", "completed_instances", "completion_rate",
			"current_streak", "longest_streak", "weekly_completion", "monthly_completion"}

		for _, stat := range expectedStats {
			_, exists := statsResp[stat]
			assert.True(t, exists, "Stats should contain %s", stat)
		}

		// Test streak calculation
		currentStreak, exists := statsResp["current_streak"].(float64)
		require.True(t, exists, "Should have current streak")
		assert.GreaterOrEqual(t, currentStreak, 0.0, "Current streak should be valid")
	})
}