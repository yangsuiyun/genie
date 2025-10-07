package middleware

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ErrorHandler middleware handles panics and errors
func ErrorHandler() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, err interface{}) {
		log.Printf("Panic recovered: %v", err)

		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "internal_error",
			"message": "An unexpected error occurred",
		})

		c.Abort()
	})
}