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

// TestCrossDeviceSyncWorkflow tests data synchronization between multiple devices
// This simulates the quickstart scenario where user works across mobile, desktop, and web
func TestCrossDeviceSyncWorkflow(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Cross-Device Sync Simulation", func(t *testing.T) {
		// Simulate user authentication from different devices
		authToken := "test-token" // In real implementation, same user token

		// Device 1 (Mobile): Create a task
		mobileTaskReq := map[string]interface{}{
			"title":       "Review quarterly budget",
			"description": "Analyze Q3 budget allocation and variances",
			"device_id":   "mobile-device-123",
			"sync_version": 1,
		}
		mobileTaskBody, _ := json.Marshal(mobileTaskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(mobileTaskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "mobile-device-123")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This will fail until implemented - expected in TDD
		assert.Equal(t, http.StatusCreated, w.Code, "Task creation on mobile should succeed")

		var mobileTaskResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &mobileTaskResp)
		require.NoError(t, err, "Mobile task response should be valid JSON")

		taskID, exists := mobileTaskResp["id"].(string)
		require.True(t, exists, "Task should have ID")

		// Verify sync metadata
		syncVersion, exists := mobileTaskResp["sync_version"].(float64)
		require.True(t, exists, "Task should have sync version")
		assert.Equal(t, float64(1), syncVersion, "Initial sync version should be 1")

		// Device 2 (Desktop): Fetch sync changes
		req, _ = http.NewRequest(http.MethodGet, "/sync/changes?since_version=0", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "desktop-device-456")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Sync changes retrieval should succeed")

		var syncResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &syncResp)
		require.NoError(t, err, "Sync response should be valid JSON")

		changes, exists := syncResp["changes"].([]interface{})
		require.True(t, exists, "Sync response should contain changes")
		assert.GreaterOrEqual(t, len(changes), 1, "Should have at least one change (the new task)")

		// Device 2 (Desktop): Update the task
		desktopUpdateReq := map[string]interface{}{
			"description": "Analyze Q3 budget allocation, variances, and prepare recommendations for Q4",
			"device_id":   "desktop-device-456",
			"sync_version": 2,
		}
		desktopUpdateBody, _ := json.Marshal(desktopUpdateReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/"+taskID, bytes.NewBuffer(desktopUpdateBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "desktop-device-456")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task update on desktop should succeed")

		var desktopUpdateResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &desktopUpdateResp)
		require.NoError(t, err, "Desktop update response should be valid JSON")

		// Verify sync version incremented
		newSyncVersion, exists := desktopUpdateResp["sync_version"].(float64)
		require.True(t, exists, "Updated task should have sync version")
		assert.Equal(t, float64(2), newSyncVersion, "Sync version should increment")

		// Device 3 (Web): Get latest sync state
		req, _ = http.NewRequest(http.MethodGet, "/sync/changes?since_version=1", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "web-device-789")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Web sync should succeed")

		var webSyncResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &webSyncResp)
		require.NoError(t, err, "Web sync response should be valid JSON")

		webChanges, exists := webSyncResp["changes"].([]interface{})
		require.True(t, exists, "Web sync should contain changes")
		assert.GreaterOrEqual(t, len(webChanges), 1, "Should have desktop update change")

		// Device 1 (Mobile): Start Pomodoro session
		sessionReq := map[string]interface{}{
			"task_id":          taskID,
			"session_type":     "work",
			"planned_duration": 1500,
			"device_id":        "mobile-device-123",
			"sync_version":     3,
		}
		sessionBody, _ := json.Marshal(sessionReq)

		req, _ = http.NewRequest(http.MethodPost, "/pomodoro/sessions", bytes.NewBuffer(sessionBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "mobile-device-123")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Pomodoro session start on mobile should succeed")

		// All devices: Verify sync consistency
		req, _ = http.NewRequest(http.MethodGet, "/sync/status", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Sync status check should succeed")

		var statusResp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &statusResp)
		require.NoError(t, err, "Sync status response should be valid JSON")

		lastSyncVersion, exists := statusResp["last_sync_version"].(float64)
		require.True(t, exists, "Should have last sync version")
		assert.GreaterOrEqual(t, lastSyncVersion, float64(3), "Sync version should be at least 3")
	})
}

// TestSyncConflictResolution tests the last-write-wins conflict resolution strategy
func TestSyncConflictResolution(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Sync Conflict Resolution", func(t *testing.T) {
		authToken := "test-token"

		// Create initial task
		taskReq := map[string]interface{}{
			"title":        "Initial task title",
			"description":  "Initial description",
			"sync_version": 1,
		}
		taskBody, _ := json.Marshal(taskReq)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Initial task creation should succeed")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Simulate offline Device A update (timestamp: T1)
		deviceAUpdateReq := map[string]interface{}{
			"title":        "Updated by Device A",
			"description":  "Description updated on Device A while offline",
			"sync_version": 2,
			"updated_at":   time.Now().Add(-5 * time.Minute).Format(time.RFC3339), // 5 minutes ago
		}
		deviceABody, _ := json.Marshal(deviceAUpdateReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/"+taskID, bytes.NewBuffer(deviceABody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "device-a")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Device A update should succeed")

		// Simulate offline Device B update (timestamp: T2, later than T1)
		deviceBUpdateReq := map[string]interface{}{
			"title":        "Updated by Device B",
			"description":  "Description updated on Device B while offline - more recent",
			"sync_version": 2, // Same base version (conflict scenario)
			"updated_at":   time.Now().Add(-2 * time.Minute).Format(time.RFC3339), // 2 minutes ago (more recent)
		}
		deviceBBody, _ := json.Marshal(deviceBUpdateReq)

		req, _ = http.NewRequest(http.MethodPut, "/tasks/"+taskID, bytes.NewBuffer(deviceBBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "device-b")

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// This should either succeed with conflict resolution or return a conflict status
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusConflict,
			"Device B update should either succeed or indicate conflict")

		// Verify final state (last-write-wins)
		req, _ = http.NewRequest(http.MethodGet, "/tasks/"+taskID, nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task retrieval should succeed")

		var finalTaskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &finalTaskResp)

		// In last-write-wins, Device B should win (more recent timestamp)
		assert.Equal(t, "Updated by Device B", finalTaskResp["title"],
			"Last-write-wins should preserve Device B's changes")
	})
}

// TestOfflineQueueSync tests the offline queue synchronization
func TestOfflineQueueSync(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Offline Queue Synchronization", func(t *testing.T) {
		authToken := "test-token"

		// Simulate device going offline and queuing operations
		offlineOperations := []map[string]interface{}{
			{
				"operation": "CREATE_TASK",
				"data": map[string]interface{}{
					"title":       "Offline created task 1",
					"description": "Created while device was offline",
				},
				"client_timestamp": time.Now().Add(-10 * time.Minute).Format(time.RFC3339),
				"client_id":        "offline-op-1",
			},
			{
				"operation": "CREATE_TASK",
				"data": map[string]interface{}{
					"title":       "Offline created task 2",
					"description": "Another task created offline",
				},
				"client_timestamp": time.Now().Add(-8 * time.Minute).Format(time.RFC3339),
				"client_id":        "offline-op-2",
			},
			{
				"operation": "START_POMODORO",
				"data": map[string]interface{}{
					"task_id":          "offline-task-id",
					"session_type":     "work",
					"planned_duration": 1500,
				},
				"client_timestamp": time.Now().Add(-5 * time.Minute).Format(time.RFC3339),
				"client_id":        "offline-op-3",
			},
		}

		// Device comes online and syncs queued operations
		syncReq := map[string]interface{}{
			"operations": offlineOperations,
			"device_id":  "mobile-device-offline",
		}
		syncBody, _ := json.Marshal(syncReq)

		req, _ := http.NewRequest(http.MethodPost, "/sync/operations", bytes.NewBuffer(syncBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("X-Device-ID", "mobile-device-offline")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Offline operations sync should succeed")

		var syncResp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &syncResp)
		require.NoError(t, err, "Sync response should be valid JSON")

		results, exists := syncResp["operation_results"].([]interface{})
		require.True(t, exists, "Sync response should contain operation results")
		assert.Len(t, results, 3, "Should process all 3 offline operations")

		// Verify each operation result
		for i, result := range results {
			resultMap := result.(map[string]interface{})
			status, exists := resultMap["status"].(string)
			require.True(t, exists, "Each operation should have status")

			// Tasks should be created successfully, Pomodoro might fail due to nonexistent task
			if i < 2 { // First two are task creations
				assert.Equal(t, "success", status, "Task creation should succeed")
			}
		}

		// Verify server state contains synced data
		req, _ = http.NewRequest(http.MethodGet, "/tasks", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code, "Task listing should succeed after sync")
	})
}

// TestRealtimeSync tests real-time synchronization using WebSocket/SSE
func TestRealtimeSync(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Real-time Sync Notifications", func(t *testing.T) {
		authToken := "test-token"

		// Test subscribing to real-time updates
		req, _ := http.NewRequest(http.MethodGet, "/sync/realtime", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)
		req.Header.Set("Accept", "text/event-stream")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		// For WebSocket/SSE, we'd normally expect different status codes
		// But since we're testing with placeholder handlers, we expect 501
		assert.Equal(t, http.StatusNotImplemented, w.Code, "Real-time sync not implemented yet")

		// TODO: When implemented, this would test:
		// 1. WebSocket connection establishment
		// 2. Real-time notifications when data changes
		// 3. Proper connection handling and cleanup
		// 4. Subscription filtering by user/device
	})
}

// TestSyncPerformance tests sync performance under load
func TestSyncPerformance(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Sync Performance with Large Dataset", func(t *testing.T) {
		authToken := "test-token"

		// Simulate requesting sync for large number of changes
		req, _ := http.NewRequest(http.MethodGet, "/sync/changes?limit=1000&since_version=0", nil)
		req.Header.Set("Authorization", "Bearer "+authToken)

		start := time.Now()
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		duration := time.Since(start)

		// Even with placeholder handler, response should be fast
		assert.Less(t, duration, 100*time.Millisecond, "Sync request should complete within 100ms")
		assert.Equal(t, http.StatusNotImplemented, w.Code, "Sync not implemented yet")

		// TODO: When implemented, verify:
		// 1. Response time < 150ms for up to 1000 changes
		// 2. Proper pagination
		// 3. Memory usage < 100MB during sync
		// 4. Database query optimization
	})
}

// TestSyncDataIntegrity tests data integrity across sync operations
func TestSyncDataIntegrity(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	t.Run("Sync Data Integrity", func(t *testing.T) {
		authToken := "test-token"

		// Create task with specific data
		originalTask := map[string]interface{}{
			"title":       "Critical task with important data",
			"description": "This task contains critical information that must not be corrupted during sync",
			"due_date":    time.Now().Add(24 * time.Hour).Format(time.RFC3339),
			"tags":        []string{"critical", "data-integrity", "test"},
		}
		taskBody, _ := json.Marshal(originalTask)

		req, _ := http.NewRequest(http.MethodPost, "/tasks", bytes.NewBuffer(taskBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code, "Task creation should succeed")

		var taskResp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &taskResp)
		taskID := taskResp["id"].(string)

		// Simulate multiple sync operations
		for i := 0; i < 5; i++ {
			// Get sync changes
			req, _ = http.NewRequest(http.MethodGet, "/sync/changes?since_version="+string(rune(i)), nil)
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// Verify task data integrity after each sync
			req, _ = http.NewRequest(http.MethodGet, "/tasks/"+taskID, nil)
			req.Header.Set("Authorization", "Bearer "+authToken)

			w = httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code == http.StatusOK {
				var retrievedTask map[string]interface{}
				json.Unmarshal(w.Body.Bytes(), &retrievedTask)

				// Verify data integrity (when implemented)
				assert.Equal(t, originalTask["title"], retrievedTask["title"],
					"Task title should remain consistent after sync %d", i)
			}
		}
	})
}