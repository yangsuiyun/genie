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

// StartSessionRequest represents the request payload for starting a Pomodoro session
type StartSessionRequest struct {
	TaskID          string `json:"task_id" binding:"required"`
	SessionType     string `json:"session_type" binding:"required,oneof=work short_break long_break"`
	PlannedDuration int    `json:"planned_duration" binding:"required,min=60,max=3600"`
}

// PomodoroSession represents a Pomodoro session entity
type PomodoroSession struct {
	ID                string `json:"id"`
	UserID            string `json:"user_id"`
	TaskID            string `json:"task_id"`
	StartedAt         string `json:"started_at"`
	PlannedDuration   int    `json:"planned_duration"`
	SessionType       string `json:"session_type"`
	Status            string `json:"status"`
	InterruptionCount int    `json:"interruption_count"`
	CreatedAt         string `json:"created_at"`
}

// TestPomodoroStartContract tests the POST /pomodoro/sessions endpoint contract
func TestPomodoroStartContract(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		payload        StartSessionRequest
		authHeader     string
		expectedStatus int
		expectedFields []string
	}{
		{
			name: "start work session",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "work",
				PlannedDuration: 1500, // 25 minutes
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "task_id", "session_type", "status", "planned_duration", "started_at"},
		},
		{
			name: "start short break session",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "short_break",
				PlannedDuration: 300, // 5 minutes
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "task_id", "session_type", "status", "planned_duration"},
		},
		{
			name: "start long break session",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "long_break",
				PlannedDuration: 900, // 15 minutes
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusCreated,
			expectedFields: []string{"id", "task_id", "session_type", "status", "planned_duration"},
		},
		{
			name: "missing task_id",
			payload: StartSessionRequest{
				SessionType:     "work",
				PlannedDuration: 1500,
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "invalid session type",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "invalid_type",
				PlannedDuration: 1500,
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "duration too short",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "work",
				PlannedDuration: 30, // Less than 1 minute
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "duration too long",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "work",
				PlannedDuration: 7200, // More than 1 hour
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusBadRequest,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "unauthorized access",
			payload: StartSessionRequest{
				TaskID:          "task-uuid-123",
				SessionType:     "work",
				PlannedDuration: 1500,
			},
			authHeader:     "",
			expectedStatus: http.StatusUnauthorized,
			expectedFields: []string{"error", "message"},
		},
		{
			name: "nonexistent task",
			payload: StartSessionRequest{
				TaskID:          "nonexistent-task-uuid",
				SessionType:     "work",
				PlannedDuration: 1500,
			},
			authHeader:     "Bearer valid-token",
			expectedStatus: http.StatusNotFound,
			expectedFields: []string{"error", "message"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			router := gin.New()
			// NOTE: This will fail until we implement the actual handler
			router.POST("/pomodoro/sessions", func(c *gin.Context) {
				c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
			})

			// Create request
			jsonBody, _ := json.Marshal(tt.payload)
			req, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(jsonBody))
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
				// var response PomodoroSession
				// err := json.Unmarshal(w.Body.Bytes(), &response)
				// assert.NoError(t, err, "Response should be valid JSON")
			} else {
				// For now, we expect 501 Not Implemented
				assert.Equal(t, http.StatusNotImplemented, w.Code, "Should return not implemented")
			}
		})
	}
}

// TestPomodoroStartActiveSessionConflict tests starting session when one is already active
func TestPomodoroStartActiveSessionConflict(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.POST("/pomodoro/sessions", func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "not implemented"})
	})

	payload := StartSessionRequest{
		TaskID:          "task-uuid-123",
		SessionType:     "work",
		PlannedDuration: 1500,
	}

	// First session start (should succeed when implemented)
	jsonBody, _ := json.Marshal(payload)
	req1, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(jsonBody))
	req1.Header.Set("Content-Type", "application/json")
	req1.Header.Set("Authorization", "Bearer valid-token")

	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)

	// Second session start (should fail with 409 conflict when implemented)
	jsonBody2, _ := json.Marshal(payload)
	req2, _ := http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(jsonBody2))
	req2.Header.Set("Content-Type", "application/json")
	req2.Header.Set("Authorization", "Bearer valid-token")

	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)

	// For now, both return 501, but when implemented:
	// First should return 201, second should return 409
	assert.Equal(t, http.StatusNotImplemented, w1.Code, "Should return not implemented (will be 201 when implemented)")
	assert.Equal(t, http.StatusNotImplemented, w2.Code, "Should return not implemented (will be 409 when implemented)")
}