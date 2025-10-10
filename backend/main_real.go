package main

import (
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/services"
)

// Services holds all application services
type Services struct {
	Auth *services.SimpleAuthService
	Task *services.TaskService
}

func main() {
	// Load environment variables
	if err := godotenv.Load("../.env"); err != nil {
		log.Println("No .env file found, using defaults")
	}

	// Initialize services
	services := initServices()

	// Setup Gin
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// CORS configuration
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"http://localhost:3000", "http://localhost:3001", "http://localhost:8080"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	config.AllowCredentials = true
	r.Use(cors.New(config))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "ok",
			"message":   "🍅 Pomodoro Genie API v2.0 - Real Implementation",
			"version":   "2.0.0",
			"timestamp": time.Now().Format(time.RFC3339),
			"features": gin.H{
				"auth":         "JWT-based authentication",
				"tasks":        "Full CRUD with in-memory storage",
				"users":        "Registration and profile management",
				"storage":      "In-memory (ready for database upgrade)",
			},
		})
	})

	// API routes
	setupRoutes(r, services)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Pomodoro Genie API v2.0 starting on port %s", port)
	log.Printf("🔗 Health check: http://localhost:%s/health", port)
	log.Printf("🔌 API endpoint: http://localhost:%s/v1", port)
	log.Printf("✨ Features: Real JWT auth, Task CRUD, User management")

	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func initServices() *Services {
	// JWT configuration
	jwtSecret := getEnv("JWT_SECRET", "default-secret-change-in-production")
	tokenExpiry := time.Hour * 24 // 24 hours

	// Initialize services
	authService := services.NewSimpleAuthService(jwtSecret, tokenExpiry)
	taskService := services.NewTaskService()

	// Create a demo user for testing
	demoUser := models.UserCreateRequest{
		Email:    "demo@example.com",
		Password: "password123",
		Name:     "Demo User",
	}

	if _, err := authService.Register(demoUser); err != nil {
		log.Printf("Demo user already exists or failed to create: %v", err)
	} else {
		log.Println("✅ Demo user created: demo@example.com / password123")
	}

	return &Services{
		Auth: authService,
		Task: taskService,
	}
}

func setupRoutes(r *gin.Engine, services *Services) {
	// Root endpoint
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":        "Pomodoro Genie API v2.0",
			"description": "Real implementation with JWT auth and task management",
			"version":     "2.0.0",
			"endpoints": gin.H{
				"health":       "/health",
				"auth":         "/v1/auth",
				"tasks":        "/v1/tasks",
				"users":        "/v1/users",
				"demo":         "POST /v1/auth/login with demo@example.com / password123",
			},
		})
	})

	v1 := r.Group("/v1")
	{
		// Authentication routes
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handleRegister(services))
			auth.POST("/login", handleLogin(services))
			auth.POST("/logout", handleLogout(services))
		}

		// Protected routes (require authentication)
		protected := v1.Group("/")
		protected.Use(authMiddleware(services.Auth))
		{
			// User routes
			users := protected.Group("/users")
			{
				users.GET("/profile", handleGetProfile(services))
				users.PUT("/profile", handleUpdateProfile(services))
			}

			// Task routes
			tasks := protected.Group("/tasks")
			{
				tasks.GET("/", handleGetTasks(services))
				tasks.POST("/", handleCreateTask(services))
				tasks.GET("/:id", handleGetTask(services))
				tasks.PUT("/:id", handleUpdateTask(services))
				tasks.DELETE("/:id", handleDeleteTask(services))
				tasks.POST("/:id/subtasks", handleCreateSubtask(services))
			}
		}
	}
}

// Authentication handlers

func handleRegister(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.UserCreateRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Invalid request format", "details": err.Error()})
			return
		}

		authResp, err := services.Auth.Register(req)
		if err != nil {
			if err == services.ErrUserExists {
				c.JSON(409, gin.H{"error": "User already exists"})
				return
			}
			c.JSON(500, gin.H{"error": "Failed to register user", "details": err.Error()})
			return
		}

		c.JSON(201, gin.H{
			"message": "User registered successfully",
			"data":    authResp,
		})
	}
}

func handleLogin(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.UserLoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Invalid request format", "details": err.Error()})
			return
		}

		authResp, err := services.Auth.Login(req)
		if err != nil {
			if err == services.ErrInvalidCredentials {
				c.JSON(401, gin.H{"error": "Invalid email or password"})
				return
			}
			c.JSON(500, gin.H{"error": "Login failed", "details": err.Error()})
			return
		}

		c.JSON(200, gin.H{
			"message": "Login successful",
			"data":    authResp,
		})
	}
}

func handleLogout(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "Logout successful"})
	}
}

// User handlers

func handleGetProfile(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")

		user, err := services.Auth.GetUserByID(userID)
		if err != nil {
			c.JSON(404, gin.H{"error": "User not found"})
			return
		}

		c.JSON(200, gin.H{
			"message": "Profile retrieved",
			"data":    user.ToResponse(),
		})
	}
}

func handleUpdateProfile(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "Profile update not implemented yet"})
	}
}

// Task handlers

func handleGetTasks(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		status := c.Query("status")

		tasks, err := services.Task.GetUserTasks(userID, status)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to get tasks", "details": err.Error()})
			return
		}

		c.JSON(200, gin.H{
			"message": "Tasks retrieved",
			"data":    tasks,
			"count":   len(tasks),
		})
	}
}

func handleCreateTask(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")

		var req models.TaskCreateRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Invalid request format", "details": err.Error()})
			return
		}

		task, err := services.Task.CreateTask(userID, req)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to create task", "details": err.Error()})
			return
		}

		c.JSON(201, gin.H{
			"message": "Task created successfully",
			"data":    task,
		})
	}
}

func handleGetTask(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		taskID := c.Param("id")

		task, err := services.Task.GetTask(taskID, userID)
		if err != nil {
			c.JSON(404, gin.H{"error": "Task not found"})
			return
		}

		c.JSON(200, gin.H{
			"message": "Task retrieved",
			"data":    task,
		})
	}
}

func handleUpdateTask(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		taskID := c.Param("id")

		var req models.TaskUpdateRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Invalid request format", "details": err.Error()})
			return
		}

		task, err := services.Task.UpdateTask(taskID, userID, req)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to update task", "details": err.Error()})
			return
		}

		c.JSON(200, gin.H{
			"message": "Task updated successfully",
			"data":    task,
		})
	}
}

func handleDeleteTask(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		taskID := c.Param("id")

		err := services.Task.DeleteTask(taskID, userID)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to delete task", "details": err.Error()})
			return
		}

		c.JSON(200, gin.H{"message": "Task deleted successfully"})
	}
}

func handleCreateSubtask(services *Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		taskID := c.Param("id")

		var req struct {
			Title string `json:"title" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Invalid request format", "details": err.Error()})
			return
		}

		subtask, err := services.Task.AddSubtask(taskID, userID, req.Title)
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to create subtask", "details": err.Error()})
			return
		}

		c.JSON(201, gin.H{
			"message": "Subtask created successfully",
			"data":    subtask,
		})
	}
}

// Middleware

func authMiddleware(authService *services.SimpleAuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(401, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Extract token from "Bearer TOKEN" format
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(401, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		claims, err := authService.ValidateToken(tokenParts[1])
		if err != nil {
			c.JSON(401, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Set user info in context
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Next()
	}
}

// Helper functions

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}