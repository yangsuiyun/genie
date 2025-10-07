package middleware

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// MockAuthMiddleware provides mock authentication for development
// In production, this should be replaced with real JWT authentication
func MockAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check for Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Authorization header is required",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>" format
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		token := parts[1]

		// Mock validation - accept "valid-token" and any JWT-like string
		if token != "valid-token" && !strings.Contains(token, "jwt") && !strings.Contains(token, "demo") {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "unauthorized",
				"message": "Invalid token",
			})
			c.Abort()
			return
		}

		// Set mock user context
		userID := "550e8400-e29b-41d4-a716-446655440001" // Fixed UUID for consistent testing
		c.Set("user_id", userID)
		c.Set("user_email", "demo@example.com")
		c.Set("user_name", "Demo User")

		c.Next()
	}
}

// AuthMiddleware provides real JWT authentication
// TODO: Implement real JWT validation when auth service is ready
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract and validate JWT token
		// For now, fallback to mock
		MockAuthMiddleware()(c)
	}
}

// GetUserIDFromContext extracts user ID from gin context
func GetUserIDFromContext(c *gin.Context) (uuid.UUID, error) {
	userIDInterface, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, fmt.Errorf("user ID not found in context")
	}

	userIDStr, ok := userIDInterface.(string)
	if !ok {
		return uuid.Nil, fmt.Errorf("user ID is not a string")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return uuid.Nil, fmt.Errorf("invalid user ID format: %w", err)
	}

	return userID, nil
}