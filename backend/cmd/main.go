package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"pomodoro-backend/internal/handlers"
	"pomodoro-backend/internal/middleware"
	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/repositories"
	"pomodoro-backend/internal/services"
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

	// Initialize database
	db, err := initDatabase()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Initialize dependency injection
	projectRepo := repositories.NewProjectRepository(db)
	taskRepo := repositories.NewTaskRepository(db)

	projectService := services.NewProjectService(projectRepo)
	taskService := services.NewTaskService(taskRepo, projectRepo)

	projectHandler := handlers.NewProjectHandler(projectService)

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
			"message":   "🍅 Pomodoro Genie API is running",
			"version":   "1.0.0",
			"timestamp": time.Now().Format(time.RFC3339),
			"services": gin.H{
				"database": checkDatabaseConnection(db),
				"cache":    "available",
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
			"features":    []string{"Projects", "Tasks", "Pomodoro Sessions", "Analytics"},
			"endpoints": gin.H{
				"health":   "/health",
				"api_v1":   "/v1",
				"auth":     "/v1/auth",
				"projects": "/v1/projects",
				"tasks":    "/v1/tasks",
				"sessions": "/v1/sessions",
				"reports":  "/v1/reports",
				"docs":     "/docs",
			},
		})
	})

	// API version 1 routes
	v1 := r.Group("/v1")

	// Authentication routes (mock for now)
	auth := v1.Group("/auth")
	{
		auth.POST("/register", handleMockRegister)
		auth.POST("/login", handleMockLogin)
		auth.POST("/logout", handleMockLogout)
		auth.POST("/refresh", handleMockRefresh)
	}

	// Protected routes group with auth middleware
	protected := v1.Group("/")
	protected.Use(middleware.MockAuthMiddleware()) // Replace with real auth when ready
	{
		// Project routes
		projects := protected.Group("/projects")
		{
			projects.GET("/", projectHandler.ListProjects)
			projects.POST("/", projectHandler.CreateProject)
			projects.GET("/:id", projectHandler.GetProject)
			projects.PUT("/:id", projectHandler.UpdateProject)
			projects.DELETE("/:id", projectHandler.DeleteProject)
			projects.GET("/:id/statistics", projectHandler.GetProjectStatistics)
			projects.POST("/:id/complete", projectHandler.ToggleProjectCompletion)
		}

		// Task routes (mock for now)
		tasks := protected.Group("/tasks")
		{
			tasks.GET("/", handleMockGetTasks)
			tasks.POST("/", handleMockCreateTask)
			tasks.GET("/:id", handleMockGetTask)
			tasks.PUT("/:id", handleMockUpdateTask)
			tasks.DELETE("/:id", handleMockDeleteTask)
		}

		// Session routes (mock for now)
		sessions := protected.Group("/sessions")
		{
			sessions.GET("/", handleMockGetSessions)
			sessions.POST("/", handleMockCreateSession)
			sessions.GET("/:id", handleMockGetSession)
			sessions.PUT("/:id", handleMockUpdateSession)
			sessions.DELETE("/:id", handleMockDeleteSession)
		}

		// User routes (mock for now)
		users := protected.Group("/users")
		{
			users.GET("/profile", handleMockGetProfile)
			users.PUT("/profile", handleMockUpdateProfile)
		}

		// Reports routes (mock for now)
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
			"message": "API Documentation",
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

	// Static files
	r.Static("/docs", "./docs")

	// Get port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Pomodoro Genie API starting on port %s", port)
	log.Printf("🔗 Health check: http://localhost:%s/health", port)
	log.Printf("📊 API docs: http://localhost:%s/docs", port)
	log.Printf("🔌 API endpoint: http://localhost:%s/v1", port)
	log.Printf("📁 Projects API: http://localhost:%s/v1/projects", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// initDatabase initializes the database connection and runs migrations
func initDatabase() (*gorm.DB, error) {
	// Get database configuration from environment
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "postgres")
	dbPassword := getEnv("DB_PASSWORD", "postgres123")
	dbName := getEnv("DB_NAME", "pomodoro_genie")
	dbSSLMode := getEnv("DB_SSLMODE", "disable")

	// Construct DSN
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=UTC",
		dbHost, dbPort, dbUser, dbPassword, dbName, dbSSLMode)

	// Configure GORM logger
	gormLogger := logger.Default.LogMode(logger.Info)
	if gin.Mode() == gin.ReleaseMode {
		gormLogger = logger.Default.LogMode(logger.Error)
	}

	// Connect to database
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: gormLogger,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Auto-migrate models (in development only)
	if gin.Mode() != gin.ReleaseMode {
		log.Println("Running database auto-migration...")
		if err := db.AutoMigrate(
			&models.User{},
			&models.Project{},
			&models.Task{},
			&models.PomodoroSession{},
		); err != nil {
			log.Printf("Warning: Auto-migration failed: %v", err)
		}
	}

	log.Println("✅ Database connection established")
	return db, nil
}

// checkDatabaseConnection checks if database is accessible
func checkDatabaseConnection(db *gorm.DB) string {
	sqlDB, err := db.DB()
	if err != nil {
		return "error"
	}

	if err := sqlDB.Ping(); err != nil {
		return "disconnected"
	}

	return "connected"
}

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// Mock handlers for authentication (to be replaced with real implementation)

func handleMockRegister(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "User registration (mock)",
		"status":  "success",
		"data":    gin.H{"user_id": "demo-user-123"},
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
				"id":    "demo-user-123",
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
			"id":    "demo-user-123",
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

// Mock handlers for other endpoints (to be replaced)

func handleMockGetTasks(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get tasks (mock) - will be replaced with real task service",
		"status":  "success",
		"data":    []gin.H{},
	})
}

func handleMockCreateTask(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "Create task (mock) - will be replaced with real task service",
		"status":  "success",
		"data":    gin.H{"id": "mock-task-id"},
	})
}

func handleMockGetTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get task (mock) - will be replaced with real task service",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockUpdateTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Update task (mock) - will be replaced with real task service",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockDeleteTask(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Delete task (mock) - will be replaced with real task service",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockGetSessions(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get sessions (mock) - will be replaced with real session service",
		"status":  "success",
		"data":    []gin.H{},
	})
}

func handleMockCreateSession(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "Create session (mock) - will be replaced with real session service",
		"status":  "success",
		"data":    gin.H{"id": "mock-session-id"},
	})
}

func handleMockGetSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Get session (mock) - will be replaced with real session service",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockUpdateSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Update session (mock) - will be replaced with real session service",
		"status":  "success",
		"data":    gin.H{"id": c.Param("id")},
	})
}

func handleMockDeleteSession(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "Delete session (mock) - will be replaced with real session service",
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
				"sessions_completed": 0,
				"focus_time":         0,
				"tasks_completed":    0,
			},
		},
	})
}
