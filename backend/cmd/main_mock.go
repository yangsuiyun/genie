package main

import (
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"pomodoro-backend/internal/middleware"
)

func main() {
	// Load environment variables
	if err := godotenv.Load("../.env"); err != nil {
		log.Println("No .env file found, using default configuration")
	}

	// Set Gin mode
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create Gin router
	r := gin.New()

	// Add middleware
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// Configure CORS
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{
		"http://localhost:3000",
		"http://localhost:3001",
		"http://localhost:3002",
		"http://localhost:8080",
		"http://localhost:5173",
	}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	config.AllowCredentials = true
	r.Use(cors.New(config))

	// Error handling middleware
	r.Use(middleware.ErrorHandler())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "ok",
			"message":   "🍅 Pomodoro Genie API is running (Mock Mode)",
			"version":   "1.0.0",
			"timestamp": time.Now().Format(time.RFC3339),
			"mode":      "mock",
			"services": gin.H{
				"database": "mock",
				"cache":    "mock",
				"api":      "running",
			},
		})
	})

	// Root endpoint
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":        "Pomodoro Genie API",
			"description": "Task Management & Pomodoro Technique Application Backend",
			"version":     "1.0.0",
			"mode":        "mock",
			"features":    []string{"Projects (Mock)", "Tasks (Mock)", "Pomodoro Sessions (Mock)", "Analytics (Mock)"},
			"endpoints": gin.H{
				"health":     "/health",
				"api_v1":     "/v1",
				"auth":       "/v1/auth",
				"projects":   "/v1/projects",
				"tasks":      "/v1/tasks",
				"sessions":   "/v1/sessions",
				"reports":    "/v1/reports",
				"docs":       "/docs",
			},
		})
	})

	// API version 1 routes
	v1 := r.Group("/v1")

	// Authentication routes (mock)
	auth := v1.Group("/auth")
	{
		auth.POST("/register", handleMockRegister)
		auth.POST("/login", handleMockLogin)
		auth.POST("/logout", handleMockLogout)
		auth.POST("/refresh", handleMockRefresh)
	}

	// Protected routes group with auth middleware
	protected := v1.Group("/")
	protected.Use(middleware.MockAuthMiddleware())
	{
		// Project routes (mock implementation that matches our API contract)
		projects := protected.Group("/projects")
		{
			projects.GET("/", handleMockListProjects)
			projects.POST("/", handleMockCreateProject)
			projects.GET("/:id", handleMockGetProject)
			projects.PUT("/:id", handleMockUpdateProject)
			projects.DELETE("/:id", handleMockDeleteProject)
			projects.GET("/:id/statistics", handleMockGetProjectStatistics)
			projects.POST("/:id/complete", handleMockToggleProjectCompletion)
		}

		// Task routes (mock)
		tasks := protected.Group("/tasks")
		{
			tasks.GET("/", handleMockGetTasks)
			tasks.POST("/", handleMockCreateTask)
			tasks.GET("/:id", handleMockGetTask)
			tasks.PUT("/:id", handleMockUpdateTask)
			tasks.DELETE("/:id", handleMockDeleteTask)
		}

		// Session routes (mock)
		sessions := protected.Group("/sessions")
		{
			sessions.GET("/", handleMockGetSessions)
			sessions.POST("/", handleMockCreateSession)
			sessions.GET("/:id", handleMockGetSession)
			sessions.PUT("/:id", handleMockUpdateSession)
			sessions.DELETE("/:id", handleMockDeleteSession)
		}

		// User routes (mock)
		users := protected.Group("/users")
		{
			users.GET("/profile", handleMockGetProfile)
			users.PUT("/profile", handleMockUpdateProfile)
		}

		// Reports routes (mock)
		reports := protected.Group("/reports")
		{
			reports.GET("/", handleMockGetReports)
			reports.POST("/", handleMockGenerateReport)
			reports.GET("/analytics", handleMockGetAnalytics)
		}
	}

	// Documentation routes
	r.GET("/docs", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "API Documentation (Mock Mode)",
			"note":    "This is running in mock mode for testing API contracts",
			"swagger": "/docs/swagger.yaml",
			"postman": "/docs/postman.json",
			"routes": gin.H{
				"projects": gin.H{
					"list":       "GET /v1/projects",
					"create":     "POST /v1/projects",
					"get":        "GET /v1/projects/:id",
					"update":     "PUT /v1/projects/:id",
					"delete":     "DELETE /v1/projects/:id",
					"statistics": "GET /v1/projects/:id/statistics",
					"complete":   "POST /v1/projects/:id/complete",
				},
			},
		})
	})

	// Get port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082" // Different port for mock version
	}

	log.Printf("🚀 Pomodoro Genie API (Mock Mode) starting on port %s", port)
	log.Printf("🔗 Health check: http://localhost:%s/health", port)
	log.Printf("📊 API docs: http://localhost:%s/docs", port)
	log.Printf("🔌 API endpoint: http://localhost:%s/v1", port)
	log.Printf("📁 Projects API: http://localhost:%s/v1/projects", port)
	log.Printf("💡 Test with: curl -H 'Authorization: Bearer valid-token' http://localhost:%s/v1/projects", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// Mock handlers that match our API contracts

func handleMockListProjects(c *gin.Context) {
	c.JSON(200, gin.H{
		"data": []gin.H{
			{
				"id":           "11111111-1111-1111-1111-111111111111",
				"user_id":      "550e8400-e29b-41d4-a716-446655440001",
				"name":         "Inbox",
				"description":  "Default project for tasks",
				"is_default":   true,
				"is_completed": false,
				"created_at":   "2024-01-01T00:00:00Z",
				"updated_at":   "2024-01-01T00:00:00Z",
				"statistics": gin.H{
					"total_tasks":          5,
					"completed_tasks":      2,
					"pending_tasks":        3,
					"completion_percent":   40.0,
					"total_pomodoros":      8,
					"total_time_seconds":   12000,
					"total_time_formatted": "3h 20m",
					"avg_pomodoro_duration_sec": 1500,
					"last_activity_at":     "2024-01-01T10:00:00Z",
				},
			},
			{
				"id":           "22222222-2222-2222-2222-222222222222",
				"user_id":      "550e8400-e29b-41d4-a716-446655440001",
				"name":         "Mobile App Project",
				"description":  "Development of mobile application",
				"is_default":   false,
				"is_completed": false,
				"created_at":   "2024-01-02T00:00:00Z",
				"updated_at":   "2024-01-02T00:00:00Z",
				"statistics": gin.H{
					"total_tasks":          10,
					"completed_tasks":      7,
					"pending_tasks":        3,
					"completion_percent":   70.0,
					"total_pomodoros":      15,
					"total_time_seconds":   22500,
					"total_time_formatted": "6h 15m",
					"avg_pomodoro_duration_sec": 1500,
					"last_activity_at":     "2024-01-02T14:30:00Z",
				},
			},
		},
		"pagination": gin.H{
			"page":        1,
			"limit":       20,
			"total":       2,
			"total_pages": 1,
		},
	})
}

func handleMockCreateProject(c *gin.Context) {
	c.JSON(201, gin.H{
		"id":           "33333333-3333-3333-3333-333333333333",
		"user_id":      "550e8400-e29b-41d4-a716-446655440001",
		"name":         "New Project",
		"description":  "A newly created project",
		"is_default":   false,
		"is_completed": false,
		"created_at":   time.Now().Format(time.RFC3339),
		"updated_at":   time.Now().Format(time.RFC3339),
	})
}

func handleMockGetProject(c *gin.Context) {
	projectID := c.Param("id")
	c.JSON(200, gin.H{
		"id":           projectID,
		"user_id":      "550e8400-e29b-41d4-a716-446655440001",
		"name":         "Project Details",
		"description":  "Detailed view of a project",
		"is_default":   false,
		"is_completed": false,
		"created_at":   "2024-01-01T00:00:00Z",
		"updated_at":   "2024-01-01T00:00:00Z",
		"statistics": gin.H{
			"total_tasks":          5,
			"completed_tasks":      2,
			"pending_tasks":        3,
			"completion_percent":   40.0,
			"total_pomodoros":      8,
			"total_time_seconds":   12000,
			"total_time_formatted": "3h 20m",
			"avg_pomodoro_duration_sec": 1500,
			"last_activity_at":     "2024-01-01T10:00:00Z",
		},
	})
}

func handleMockUpdateProject(c *gin.Context) {
	projectID := c.Param("id")
	c.JSON(200, gin.H{
		"id":           projectID,
		"user_id":      "550e8400-e29b-41d4-a716-446655440001",
		"name":         "Updated Project Name",
		"description":  "Updated project description",
		"is_default":   false,
		"is_completed": false,
		"created_at":   "2024-01-01T00:00:00Z",
		"updated_at":   time.Now().Format(time.RFC3339),
	})
}

func handleMockDeleteProject(c *gin.Context) {
	c.Status(204) // No content
}

func handleMockGetProjectStatistics(c *gin.Context) {
	c.JSON(200, gin.H{
		"total_tasks":          5,
		"completed_tasks":      2,
		"pending_tasks":        3,
		"completion_percent":   40.0,
		"total_pomodoros":      8,
		"total_time_seconds":   12000,
		"total_time_formatted": "3h 20m",
		"avg_pomodoro_duration_sec": 1500,
		"last_activity_at":     "2024-01-01T10:00:00Z",
	})
}

func handleMockToggleProjectCompletion(c *gin.Context) {
	projectID := c.Param("id")
	c.JSON(200, gin.H{
		"id":           projectID,
		"user_id":      "550e8400-e29b-41d4-a716-446655440001",
		"name":         "Project Name",
		"description":  "Project description",
		"is_default":   false,
		"is_completed": true, // Toggled to completed
		"created_at":   "2024-01-01T00:00:00Z",
		"updated_at":   time.Now().Format(time.RFC3339),
	})
}

// Reuse existing mock handlers for other endpoints
func handleMockRegister(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "User registration (mock)",
		"status":  "success",
		"data":    gin.H{"user_id": "550e8400-e29b-41d4-a716-446655440001"},
	})
}

func handleMockLogin(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "User login (mock)",
		"status":  "success",
		"data": gin.H{
			"access_token":  "demo-jwt-token",
			"refresh_token": "demo-refresh-token",
			"user": gin.H{
				"id":    "550e8400-e29b-41d4-a716-446655440001",
				"email": "demo@example.com",
				"name":  "Demo User",
			},
		},
	})
}

func handleMockLogout(c *gin.Context) {
	c.JSON(200, gin.H{"message": "User logout (mock)", "status": "success"})
}

func handleMockRefresh(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Token refresh (mock)",
		"status":  "success",
		"data":    gin.H{"access_token": "new-demo-jwt-token"},
	})
}

func handleMockGetProfile(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get user profile (mock)",
		"status":  "success",
		"data": gin.H{
			"id":    "550e8400-e29b-41d4-a716-446655440001",
			"email": "demo@example.com",
			"name":  "Demo User",
			"settings": gin.H{
				"work_duration":       25,
				"short_break":         5,
				"long_break":          15,
				"sessions_until_long": 4,
			},
		},
	})
}

func handleMockUpdateProfile(c *gin.Context) {
	c.JSON(200, gin.H{"message": "Update user profile (mock)", "status": "success"})
}

func handleMockGetTasks(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get tasks (mock)",
		"status":  "success",
		"data":    []gin.H{},
	})
}

func handleMockCreateTask(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "Create task (mock)",
		"status":  "success",
		"data":    gin.H{"id": "mock-task-id"},
	})
}

func handleMockGetTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get task (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockUpdateTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Update task (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockDeleteTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Delete task (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockGetSessions(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get sessions (mock)",
		"status":  "success",
		"data":    []gin.H{},
	})
}

func handleMockCreateSession(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "Create session (mock)",
		"status":  "success",
		"data":    gin.H{"id": "mock-session-id"},
	})
}

func handleMockGetSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get session (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockUpdateSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Update session (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockDeleteSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Delete session (mock)",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockGetReports(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get reports (mock)",
		"status":  "success",
		"data":    []gin.H{},
	})
}

func handleMockGenerateReport(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "Generate report (mock)",
		"status":  "success",
		"data":    gin.H{"report_id": "mock-report-id"},
	})
}

func handleMockGetAnalytics(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get analytics (mock)",
		"status":  "success",
		"data": gin.H{
			"today": gin.H{
				"sessions_completed": 3,
				"focus_time":         75,
				"tasks_completed":    2,
			},
		},
	})
}