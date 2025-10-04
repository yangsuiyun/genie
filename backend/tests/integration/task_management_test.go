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

// TestTaskManagementWorkflow tests complete task management with reminders
// This covers: Task creation → Subtask management → Due date reminders → Task completion
func TestTaskManagementWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Complete Task Management Workflow", func(t *testing.T) {
		authToken := "test-token" // In real implementation, get from auth

		// Step 1: Create parent task with due date
		parentTaskReq := map[string]interface{}{
			"title":       "Plan quarterly review",
			"description": "Prepare comprehensive quarterly review presentation",
			"due_date":    time.Now().Add(7 * 24 * time.Hour).Format(time.RFC3339), // Due in 1 week
		}
		parentTaskBody, _ := json.Marshal(parentTaskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(parentTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This will fail until implemented - expected in TDD
		assert.Equal(t, http.StatusCreated, w.Code, "Parent task creation should succeed")

		var parentTaskResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &parentTaskResp)
		require.NoError(t, err, "Parent task response should be valid JSON")

		parentTaskID, exists := parentTaskResp["id"].(string)
		require.True(t, exists, "Parent task should have ID")

		// Step 2: Create subtasks
		subtasks := []map[string]interface{}{
			{
				"title":          "Gather financial data",
				"description":    "Collect Q3 financial metrics and reports",
				"parent_task_id": parentTaskID,
				"due_date":       time.Now().Add(3 * 24 * time.Hour).Format(time.RFC3339), // Due in 3 days
			},
			{
				"title":          "Prepare presentation slides",
				"description":    "Create PowerPoint slides for quarterly review",
				"parent_task_id": parentTaskID,
				"due_date":       time.Now().Add(5 * 24 * time.Hour).Format(time.RFC3339), // Due in 5 days
			},
			{
				"title":          "Schedule stakeholder meeting",
				"description":    "Coordinate calendars for quarterly review meeting",
				"parent_task_id": parentTaskID,
				"due_date":       time.Now().Add(2 * 24 * time.Hour).Format(time.RFC3339), // Due in 2 days
			},
		}

		var subtaskIDs []string
		for i, subtaskReq := range subtasks {
			subtaskBody, _ := json.Marshal(subtaskReq)

			req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(subtaskBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusCreated, w.Code, "Subtask %d creation should succeed", i+1)

			var subtaskResp map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &subtaskResp)
			require.NoError(t, err, "Subtask response should be valid JSON")

			subtaskID, exists := subtaskResp["id"].(string)
			require.True(t, exists, "Subtask should have ID")
			subtaskIDs = append(subtaskIDs, subtaskID)

			// Verify parent-child relationship
			assert.Equal(t, parentTaskID, subtaskResp["parent_task_id"], "Subtask should reference parent")
		}

		// Step 3: Test task hierarchy retrieval
		req, _ = http.NewRequest(http.MethodGet, "/tasks/"+parentTaskID+"/subtasks", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Subtask retrieval should succeed")

		var subtasksResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &subtasksResp)
		require.NoError(t, err, "Subtasks response should be valid JSON")

		subtasksList, exists := subtasksResp["subtasks"].([]interface{})
		require.True(t, exists, "Response should contain subtasks array")
		assert.Len(t, subtasksList, 3, "Should return 3 subtasks")

		// Step 4: Complete subtasks progressively
		for i, subtaskID := range subtaskIDs {
			completeReq := map[string]interface{}{
				"is_completed": true,
			}
			completeBody, _ := json.Marshal(completeReq)

			req, _ := http.NewRequest(http.MethodPut, "/tasks/"+subtaskID, bytes.NewBuffer(completeBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Subtask %d completion should succeed", i+1)
		}

		// Step 5: Verify parent task progress calculation
		req, _ = http.NewRequest(http.MethodGet, "/tasks/"+parentTaskID, nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Parent task retrieval should succeed")

		var updatedParentResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &updatedParentResp)
		require.NoError(t, err, "Updated parent response should be valid JSON")

		// Verify progress calculation (all subtasks completed = 100%)
		progress, exists := updatedParentResp["progress"].(float64)
		require.True(t, exists, "Parent task should have progress field")
		assert.Equal(t, 100.0, progress, "Parent task should show 100% progress")

		// Step 6: Complete parent task
		completeParentReq := map[string]interface{}{
			"is_completed": true,
		}
		completeParentBody, _ := json.Marshal(completeParentReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/"+parentTaskID, bytes.NewBuffer(completeParentBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Parent task completion should succeed")
	})
}

// TestTaskReminderSystem tests the reminder notification system
func TestTaskReminderSystem(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Task Reminder Notifications", func(t *testing.T) {
		authToken := "test-token"

		// Create task with upcoming due date
		taskReq := map[string]interface{}{
			"title":       "Submit monthly report",
			"description": "Complete and submit the monthly performance report",
			"due_date":    time.Now().Add(2 * time.Hour).Format(time.RFC3339), // Due in 2 hours
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Task with reminder should be created")

		var taskResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &taskResp)
		require.NoError(t, err, "Task response should be valid JSON")

		_, exists := taskResp["id"].(string)
		require.True(t, exists, "Task should have ID")

		// Test getting upcoming reminders
		req, _ = http.NewRequest(http.MethodGet, "/reminders/upcoming", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Upcoming reminders should be retrieved")

		var remindersResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &remindersResp)
		require.NoError(t, err, "Reminders response should be valid JSON")

		reminders, exists := remindersResp["reminders"].([]interface{})
		require.True(t, exists, "Response should contain reminders array")
		assert.GreaterOrEqual(t, len(reminders), 1, "Should have at least one upcoming reminder")

		// Test marking reminder as acknowledged
		if len(reminders) > 0 {
			reminder := reminders[0].(map[string]interface{})
			reminderID := reminder["id"].(string)

			ackReq := map[string]interface{}{
				"acknowledged": true,
			}
			ackBody, _ := json.Marshal(ackReq)

			req, _ = http.NewRequest(http.MethodPut, "/reminders/"+reminderID, bytes.NewBuffer(ackBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Reminder acknowledgment should succeed")
		}
	})
}

// TestTaskSearchAndFiltering tests task search and filtering capabilities
func TestTaskSearchAndFiltering(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Task Search and Filtering", func(t *testing.T) {
		authToken := "test-token"

		// Create multiple tasks with different properties
		tasks := []map[string]interface{}{
			{
				"title":       "Design user interface",
				"description": "Create mockups for the new dashboard",
				"due_date":    time.Now().Add(5 * 24 * time.Hour).Format(time.RFC3339),
				"tags":        []string{"design", "ui", "dashboard"},
			},
			{
				"title":       "Implement API endpoints",
				"description": "Develop REST API for user management",
				"due_date":    time.Now().Add(3 * 24 * time.Hour).Format(time.RFC3339),
				"tags":        []string{"backend", "api", "development"},
			},
			{
				"title":       "Write unit tests",
				"description": "Create comprehensive test suite",
				"due_date":    time.Now().Add(7 * 24 * time.Hour).Format(time.RFC3339),
				"tags":        []string{"testing", "quality", "development"},
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

			assert.Equal(t, http.StatusCreated, w.Code, "Task creation should succeed")

			var taskResp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &taskResp)
			taskIDs = append(taskIDs, taskResp["id"].(string))
		}

		// Test search by title
		req, _ := http.NewRequest(http.MethodGet, "/tasks?search=API", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task search should succeed")

		// Test filter by tag
		req, _ = http.NewRequest(http.MethodGet, "/tasks?tags=development", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task filtering by tag should succeed")

		// Test filter by due date range
		startDate := time.Now().Format(time.RFC3339)
		endDate := time.Now().Add(4 * 24 * time.Hour).Format(time.RFC3339)
		req, _ = http.NewRequest(http.MethodGet, "/tasks?due_after="+startDate+"&due_before="+endDate, nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task filtering by due date should succeed")
	})
}

// TestTaskNotesManagement tests adding and managing notes on tasks
func TestTaskNotesManagement(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Task Notes Management", func(t *testing.T) {
		authToken := "test-token"

		// Create a task
		taskReq := map[string]interface{}{
			"title":       "Research competitor analysis",
			"description": "Analyze top 5 competitors in our market",
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Task creation should succeed")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Add multiple notes to the task
		notes := []string{
			"Found great insights on competitor A's pricing strategy",
			"Competitor B has interesting mobile app features",
			"Need to research competitor C's market positioning more",
		}

		var noteIDs []string
		for _, noteContent := range notes {
			noteReq := map[string]interface{}{
				"content": noteContent,
				"task_id": taskID,
			}
			noteBody, _ := json.Marshal(noteReq)

			req, _ := http.NewRequest(http.MethodPost, "/tasks/"+taskID+"/notes", bytes.NewBuffer(noteBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+authToken)

			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusCreated, w.Code, "Note creation should succeed")

			var noteResp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &noteResp)
			noteIDs = append(noteIDs, noteResp["id"].(string))
		}

		// Retrieve all notes for the task
		req, _ = http.NewRequest(http.MethodGet, "/tasks/"+taskID+"/notes", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Notes retrieval should succeed")

		var notesResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &notesResp)

		notesList, exists := notesResp["notes"].([]interface{})
		require.True(t, exists, "Response should contain notes array")
		assert.Len(t, notesList, 3, "Should return 3 notes")

		// Update a note
		updateNoteReq := map[string]interface{}{
			"content": "Updated: Found comprehensive analysis on competitor A's pricing strategy with detailed breakdown",
		}
		updateNoteBody, _ := json.Marshal(updateNoteReq)

		req, _ = http.NewRequest(http.MethodPut, "/notes/"+noteIDs[0], bytes.NewBuffer(updateNoteBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Note update should succeed")

		// Delete a note
		req, _ = http.NewRequest(http.MethodDelete, "/notes/"+noteIDs[2], nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Note deletion should succeed")
	})
}