package main

import (
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// 加载环境变量
	if err := godotenv.Load("../.env"); err != nil {
		log.Println("未找到.env文件，使用默认配置")
	}

	// 设置Gin模式
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建Gin路由
	r := gin.Default()

	// 配置CORS
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"http://localhost:3000", "http://localhost:8080", "http://localhost:5173"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	config.AllowCredentials = true
	r.Use(cors.New(config))

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "ok",
			"message":   "🍅 Pomodoro Genie API正在运行",
			"version":   "1.0.0",
			"timestamp": time.Now().Format(time.RFC3339),
			"services": gin.H{
				"database": "connected",
				"cache":    "available",
				"api":      "running",
			},
		})
	})

	// 根路径
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":        "Pomodoro Genie API",
			"description": "任务管理与番茄工作法应用后端服务",
			"version":     "1.0.0",
			"endpoints": gin.H{
				"health":     "/health",
				"api_v1":     "/v1",
				"auth":       "/v1/auth",
				"tasks":      "/v1/tasks",
				"pomodoro":   "/v1/pomodoro",
				"reports":    "/v1/reports",
				"docs":       "/docs",
			},
		})
	})

	// API版本1路由组
	v1 := r.Group("/v1")
	{
		// 认证路由
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handleRegister)
			auth.POST("/login", handleLogin)
			auth.POST("/logout", handleLogout)
			auth.POST("/refresh", handleRefresh)
		}

		// 用户路由
		users := v1.Group("/users")
		{
			users.GET("/profile", handleGetProfile)
			users.PUT("/profile", handleUpdateProfile)
		}

		// 任务路由
		tasks := v1.Group("/tasks")
		{
			tasks.GET("/", handleGetTasks)
			tasks.POST("/", handleCreateTask)
			tasks.GET("/:id", handleGetTask)
			tasks.PUT("/:id", handleUpdateTask)
			tasks.DELETE("/:id", handleDeleteTask)
			tasks.POST("/:id/subtasks", handleCreateSubtask)
		}

		// Pomodoro路由
		pomodoro := v1.Group("/pomodoro")
		{
			sessions := pomodoro.Group("/sessions")
			{
				sessions.POST("/", handleStartSession)
				sessions.GET("/:id", handleGetSession)
				sessions.PUT("/:id", handleUpdateSession)
				sessions.DELETE("/:id", handleStopSession)
			}
		}

		// 报告路由
		reports := v1.Group("/reports")
		{
			reports.GET("/", handleGetReports)
			reports.POST("/", handleGenerateReport)
			reports.GET("/analytics", handleGetAnalytics)
		}

		// 同步路由
		sync := v1.Group("/sync")
		{
			sync.POST("/", handleSync)
			sync.GET("/status", handleSyncStatus)
		}
	}

	// 文档路由
	r.GET("/docs", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "API文档",
			"swagger": "/docs/swagger.yaml",
			"postman": "/docs/postman.json",
		})
	})

	// 静态文件 (如果有的话)
	r.Static("/docs", "./docs")

	// 获取端口
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Pomodoro Genie API启动在端口 %s", port)
	log.Printf("🔗 健康检查: http://localhost:%s/health", port)
	log.Printf("📊 API文档: http://localhost:%s/docs", port)
	log.Printf("🔌 API接口: http://localhost:%s/v1", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}

// 认证处理函数
func handleRegister(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "用户注册",
		"status":  "success",
		"data":    gin.H{"user_id": "demo-user-123"},
	})
}

func handleLogin(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "用户登录",
		"status":  "success",
		"data": gin.H{
			"access_token":  "demo-jwt-token",
			"refresh_token": "demo-refresh-token",
			"user": gin.H{
				"id":    "demo-user-123",
				"email": "demo@example.com",
				"name":  "演示用户",
			},
		},
	})
}

func handleLogout(c *gin.Context) {
	c.JSON(200, gin.H{"message": "用户登出", "status": "success"})
}

func handleRefresh(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "刷新令牌",
		"status":  "success",
		"data":    gin.H{"access_token": "new-demo-jwt-token"},
	})
}

// 用户处理函数
func handleGetProfile(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "获取用户资料",
		"status":  "success",
		"data": gin.H{
			"id":               "demo-user-123",
			"email":            "demo@example.com",
			"name":             "演示用户",
			"pomodoro_settings": gin.H{
				"work_duration":       25,
				"short_break":         5,
				"long_break":          15,
				"sessions_until_long": 4,
			},
		},
	})
}

func handleUpdateProfile(c *gin.Context) {
	c.JSON(200, gin.H{"message": "更新用户资料", "status": "success"})
}

// 任务处理函数
func handleGetTasks(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "获取任务列表",
		"status":  "success",
		"data": []gin.H{
			{
				"id":          "task-1",
				"title":       "完成项目文档",
				"description": "编写API文档和用户手册",
				"priority":    "high",
				"status":      "in_progress",
				"due_date":    time.Now().Add(24 * time.Hour).Format(time.RFC3339),
				"created_at":  time.Now().Add(-2 * time.Hour).Format(time.RFC3339),
			},
			{
				"id":          "task-2",
				"title":       "优化数据库查询",
				"description": "提高API响应速度",
				"priority":    "medium",
				"status":      "pending",
				"due_date":    time.Now().Add(48 * time.Hour).Format(time.RFC3339),
				"created_at":  time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
			},
		},
	})
}

func handleCreateTask(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "创建任务",
		"status":  "success",
		"data": gin.H{
			"id":         "new-task-123",
			"title":      "新任务",
			"status":     "pending",
			"created_at": time.Now().Format(time.RFC3339),
		},
	})
}

func handleGetTask(c *gin.Context) {
	taskID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "获取任务详情",
		"status":  "success",
		"data": gin.H{
			"id":          taskID,
			"title":       "任务详情",
			"description": "任务详细信息",
			"subtasks": []gin.H{
				{"id": "sub-1", "title": "子任务1", "completed": true},
				{"id": "sub-2", "title": "子任务2", "completed": false},
			},
		},
	})
}

func handleUpdateTask(c *gin.Context) {
	taskID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "更新任务",
		"status":  "success",
		"data":    gin.H{"id": taskID, "updated_at": time.Now().Format(time.RFC3339)},
	})
}

func handleDeleteTask(c *gin.Context) {
	taskID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "删除任务",
		"status":  "success",
		"data":    gin.H{"id": taskID},
	})
}

func handleCreateSubtask(c *gin.Context) {
	taskID := c.Param("id")
	c.JSON(201, gin.H{
		"message": "创建子任务",
		"status":  "success",
		"data":    gin.H{"task_id": taskID, "subtask_id": "new-subtask-123"},
	})
}

// Pomodoro处理函数
func handleStartSession(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "开始Pomodoro会话",
		"status":  "success",
		"data": gin.H{
			"session_id":  "session-123",
			"task_id":     "task-1",
			"type":        "work",
			"duration":    1500, // 25分钟
			"started_at":  time.Now().Format(time.RFC3339),
			"status":      "active",
		},
	})
}

func handleGetSession(c *gin.Context) {
	sessionID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "获取会话详情",
		"status":  "success",
		"data": gin.H{
			"session_id": sessionID,
			"status":     "active",
			"remaining":  1200, // 剩余时间(秒)
		},
	})
}

func handleUpdateSession(c *gin.Context) {
	sessionID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "更新会话",
		"status":  "success",
		"data":    gin.H{"session_id": sessionID},
	})
}

func handleStopSession(c *gin.Context) {
	sessionID := c.Param("id")
	c.JSON(200, gin.H{
		"message": "停止会话",
		"status":  "success",
		"data":    gin.H{"session_id": sessionID, "stopped_at": time.Now().Format(time.RFC3339)},
	})
}

// 报告处理函数
func handleGetReports(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "获取报告列表",
		"status":  "success",
		"data": []gin.H{
			{
				"id":         "report-1",
				"type":       "weekly",
				"period":     "2024-W40",
				"created_at": time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
			},
		},
	})
}

func handleGenerateReport(c *gin.Context) {
	c.JSON(201, gin.H{
		"message": "生成报告",
		"status":  "success",
		"data": gin.H{
			"report_id":       "new-report-123",
			"total_sessions":  12,
			"total_focus_time": 300, // 分钟
			"completion_rate": 85.5,
			"productivity_trend": "increasing",
		},
	})
}

func handleGetAnalytics(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "获取分析数据",
		"status":  "success",
		"data": gin.H{
			"today": gin.H{
				"sessions_completed": 3,
				"focus_time":         75,
				"tasks_completed":    2,
			},
			"this_week": gin.H{
				"sessions_completed": 18,
				"focus_time":         450,
				"tasks_completed":    8,
			},
		},
	})
}

// 同步处理函数
func handleSync(c *gin.Context) {
	c.JSON(200, gin.H{
		"message":     "数据同步",
		"status":      "success",
		"sync_status": "completed",
		"last_sync":   time.Now().Format(time.RFC3339),
	})
}

func handleSyncStatus(c *gin.Context) {
	c.JSON(200, gin.H{
		"message": "同步状态",
		"status":  "success",
		"data": gin.H{
			"last_sync":    time.Now().Add(-5 * time.Minute).Format(time.RFC3339),
			"sync_status":  "up_to_date",
			"pending_items": 0,
		},
	})
}