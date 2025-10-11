package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"pomodoro-backend/internal/config"
	"pomodoro-backend/internal/handlers"
	"pomodoro-backend/internal/middleware"
	"pomodoro-backend/internal/models"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func main() {
	// Load environment variables
	loadEnvironment()

	// Initialize database
	db, err := initDatabase()
	if err != nil {
		log.Fatalf("❌ Failed to initialize database: %v", err)
	}

	// Setup Gin router
	router := setupRouter(db)

	// Start server
	port := getEnv("PORT", "8081")
	log.Printf("🚀 Pomodoro Genie API starting on port %s", port)
	log.Printf("🔗 Health check: http://localhost:%s/health", port)
	log.Printf("📊 API docs: http://localhost:%s/docs", port)
	log.Printf("🔌 API endpoint: http://localhost:%s/v1", port)

	if err := router.Run(":" + port); err != nil {
		log.Fatalf("❌ Failed to start server: %v", err)
	}
}

// loadEnvironment loads environment variables
func loadEnvironment() {
	// Try to load .env file if it exists
	if _, err := os.Stat(".env"); err == nil {
		log.Println("📄 Environment file found")
	}

	// Set Gin mode
	if getEnv("GIN_MODE", "debug") == "release" {
		gin.SetMode(gin.ReleaseMode)
		log.Println("🔒 Running in release mode")
	} else {
		log.Println("🔧 Running in debug mode")
	}
}

// initDatabase initializes the database connection and runs migrations
func initDatabase() (*gorm.DB, error) {
	// Connect to database using simplified config
	database, err := config.ConnectDatabase()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Auto-migrate models
	log.Println("🔄 Running database migrations...")
	if err := database.DB.AutoMigrate(
		&models.User{},
		&models.Project{},
		&models.Task{},
		&models.PomodoroSession{},
	); err != nil {
		log.Printf("⚠️  Warning: Auto-migration failed: %v", err)
	}

	log.Println("✅ Database initialization completed")
	return database.DB, nil
}

// setupRouter configures the Gin router with middleware and routes
func setupRouter(db *gorm.DB) *gin.Engine {
	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// Configure CORS
	config := cors.Config{
		AllowOrigins: []string{
			"http://localhost:3000",
			"http://localhost:3001",
			"http://localhost:3002",
			"http://localhost:8080",
			"http://localhost:5173",
		},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}
	router.Use(cors.New(config))

	// Error handling middleware
	router.Use(middleware.ErrorHandler())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "ok",
			"message":   "🍅 Pomodoro Genie API is running",
			"version":   "2.2.0-simplified",
			"timestamp": time.Now().Format(time.RFC3339),
			"services": gin.H{
				"database": checkDatabaseConnection(db),
				"api":      "running",
			},
		})
	})

	// Root endpoint
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":        "Pomodoro Genie API",
			"description": "Task Management & Pomodoro Technique Application Backend",
			"version":     "2.2.0-simplified",
			"features":    []string{"Projects", "Tasks", "Pomodoro Sessions", "Analytics"},
			"endpoints": gin.H{
				"health":   "/health",
				"api_v1":   "/v1",
				"auth":     "/v1/auth",
				"projects": "/v1/projects",
				"tasks":    "/v1/tasks",
				"sessions": "/v1/sessions",
				"docs":     "/docs",
			},
		})
	})

	// API version 1 routes
	v1 := router.Group("/v1")

	// Authentication routes
	auth := v1.Group("/auth")
	{
		auth.POST("/register", handlers.Register)
		auth.POST("/login", handlers.Login)
		auth.POST("/logout", middleware.AuthMiddleware(), handlers.Logout)
	}

	// Protected routes group with auth middleware
	protected := v1.Group("/")
	protected.Use(middleware.AuthMiddleware())
	{
		// Project routes
		projects := protected.Group("/projects")
		{
			projects.GET("", handlers.GetProjects)
			projects.POST("", handlers.CreateProject)
			projects.GET("/:id", handlers.GetProject)
			projects.PUT("/:id", handlers.UpdateProject)
			projects.DELETE("/:id", handlers.DeleteProject)
		}

		// Task routes
		tasks := protected.Group("/tasks")
		{
			tasks.GET("", handlers.GetTasks)
			tasks.POST("", handlers.CreateTask)
			tasks.GET("/:id", handlers.GetTask)
			tasks.PUT("/:id", handlers.UpdateTask)
			tasks.DELETE("/:id", handlers.DeleteTask)
		}

		// Pomodoro routes
		pomodoro := protected.Group("/pomodoro")
		{
			pomodoro.POST("/start", handlers.StartPomodoro)
			pomodoro.POST("/pause", handlers.PausePomodoro)
			pomodoro.POST("/resume", handlers.ResumePomodoro)
			pomodoro.POST("/stop", handlers.StopPomodoro)
			pomodoro.GET("/sessions", handlers.GetPomodoroSessions)
		}
	}

	// Documentation routes
	router.GET("/docs", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "API Documentation",
			"version": "2.2.0-simplified",
			"routes": gin.H{
				"auth": gin.H{
					"register": "POST /v1/auth/register",
					"login":    "POST /v1/auth/login",
					"logout":   "POST /v1/auth/logout",
				},
				"projects": gin.H{
					"list":   "GET /v1/projects",
					"create": "POST /v1/projects",
					"get":    "GET /v1/projects/:id",
					"update": "PUT /v1/projects/:id",
					"delete": "DELETE /v1/projects/:id",
				},
				"tasks": gin.H{
					"list":   "GET /v1/tasks",
					"create": "POST /v1/tasks",
					"get":    "GET /v1/tasks/:id",
					"update": "PUT /v1/tasks/:id",
					"delete": "DELETE /v1/tasks/:id",
				},
				"pomodoro": gin.H{
					"start":    "POST /v1/pomodoro/start",
					"pause":    "POST /v1/pomodoro/pause",
					"resume":   "POST /v1/pomodoro/resume",
					"stop":     "POST /v1/pomodoro/stop",
					"sessions": "GET /v1/pomodoro/sessions",
				},
			},
		})
	})

	return router
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
