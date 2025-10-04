package contract

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// CreateTaskRequest represents the request payload for creating a task
type CreateTaskRequest struct {
	Title       string `json:"title" binding:"required,min=1,max=200"`
	Description string `json:"description" binding:"max=2000"`
	DueDate     string `json:"due_date,omitempty"`
	ParentTaskID string `json:"parent_task_id,omitempty"`
}

// TestTasksCreateContract tests the POST /tasks endpoint contract
func TestTasksCreateContract(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		payload        CreateTaskRequest
		authHeader     string
		expectedStatus int
		expectedFields []string
	}{
		{
			name: "valid task creation",
			payload: CreateTaskRequest{
				Title:       "Complete project proposal",
				Description: "Write and submit the quarterly project proposal",
				DueDate:     "2025-10-15T14:00:00Z",
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "title", "description", "due_date", "is_completed", "created_at"},
		},
		{
			name: "minimal valid task",
			payload: CreateTaskRequest{
				Title: "Simple task",
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "title", "is_completed", "created_at"},
		},
		{
			name: "subtask creation",
			payload: CreateTaskRequest{
				Title:        "Subtask example",
				ParentTaskID: "parent-task-uuid",
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "title", "parent_task_id", "is_completed", "created_at"},
		},
		{
			name: "empty title",
			payload: CreateTaskRequest{
				Title:       "",
				Description: "Task without title",
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "title too long",
			payload: CreateTaskRequest{
				Title: string(make([]byte, 201)), // 201 characters
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "description too long",
			payload: CreateTaskRequest{
				Title:       "Valid title",
				Description: string(make([]byte, 2001)), // 2001 characters
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "invalid due date format",
			payload: CreateTaskRequest{
				Title:   "Task with invalid date",
				DueDate: "invalid-date-format",
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "unauthorized access",
			payload: CreateTaskRequest{
				Title: "Unauthorized task",
			},
			authHeader:     "",
			expectedStatus: http.StatusUnauthorized,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "invalid auth token",
			payload: CreateTaskRequest{
				Title: "Task with invalid token",
			},
			authHeader:     "Bearer invalid-token",
			expectedStatus: http.StatusUnauthorized,
			expectedFields: []string{"error", "message"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			router := gin.New()
			// NOTE: This will fail until we implement the actual handler
			router.POST("/tasks", func(c *gin.Context) {
				c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
			})

			// Create request
			jsonBody, _ := json.Marshal(tt.payload)
			req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}

			// Perform request
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// This test should FAIL until we implement the actual handler
			if tt.expectedStatus == http.StatusCreated {
				// This assertion will fail, which is expected in TDD
				assert.Equal(t, tt.expectedStatus, w.Code, "Expected status code to match")

				// TODO: Validate response structure when implemented
				// var response Task
				// err := json.Unmarshal(w.Body.Bytes(), &response)
				// assert.NoError(t, err, "Response should be valid JSON")
			} else {
				// For now, we expect 501 Not Implemented
				assert.Equal(t, http.StatusNotImplemented, w.Code, "Should return not implemented")
			}
		})
	}
}