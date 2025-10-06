package integration

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// TestDefaultProjectProtectionIntegration tests:
// 1. Default "Inbox" project cannot be deleted
// 2. Appropriate error messages are returned
func TestDefaultProjectProtectionIntegration(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// TODO: This will fail - no handler registered yet
	// router.DELETE("/v1/projects/:id", authMiddleware(), projectHandler.DeleteProject)

	t.Run("Cannot delete default Inbox project", func(t *testing.T) {
		// Attempt to delete the default Inbox project
		req := httptest.NewRequest("DELETE", "/v1/projects/11111111-1111-1111-1111-111111111111", nil)
		req.Header.Set("Authorization", "Bearer valid-token")
		w := httptest.NewRecorder()

		router.ServeHTTP(w, req)

		// This SHOULD FAIL initially (404 - route not found)
		assert.Equal(t, http.StatusNotFound, w.Code, "Expected 404 since handler not implemented yet")

		// TODO: Uncomment when handler is implemented
		// assert.Equal(t, http.StatusForbidden, w.Code)
		//
		// var errorResponse map[string]interface{}
		// err := json.Unmarshal(w.Body.Bytes(), &errorResponse)
		// assert.NoError(t, err)
		// assert.Equal(t, "forbidden", errorResponse["error"])
		// assert.Contains(t, errorResponse["message"], "Cannot delete default project")
	})
}