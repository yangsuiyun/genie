package performance

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"backend/internal/handlers"
	"backend/internal/middleware"
	"backend/internal/models"
	"backend/tests/unit"
)

// PerformanceTestSuite runs performance tests for API endpoints
type PerformanceTestSuite struct {
	router     *gin.Engine
	testServer *httptest.Server
	client     *http.Client
}

// Performance thresholds
const (
	MaxAPIResponseTime    = 150 * time.Millisecond
	MaxDBQueryTime        = 50 * time.Millisecond
	MaxConcurrentUsers    = 100
	TestDuration          = 30 * time.Second
	WarmupDuration        = 5 * time.Second
	AcceptableErrorRate   = 0.01 // 1%
	MinThroughput         = 500   // requests per second
)

// TestResult stores performance test results
type TestResult struct {
	Endpoint        string
	Method          string
	ResponseTime    time.Duration
	StatusCode      int
	Error           error
	RequestSize     int
	ResponseSize    int
	Timestamp       time.Time
}

// PerformanceMetrics aggregates test results
type PerformanceMetrics struct {
	TotalRequests      int
	SuccessfulRequests int
	FailedRequests     int
	AverageResponse    time.Duration
	MinResponse        time.Duration
	MaxResponse        time.Duration
	P95Response        time.Duration
	P99Response        time.Duration
	Throughput         float64
	ErrorRate          float64
	RequestsPerSecond  []float64
}

func setupPerformanceTestSuite() *PerformanceTestSuite {
	gin.SetMode(gin.TestMode)

	// Create router with middleware
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())
	router.Use(middleware.RateLimit())

	// Setup test routes
	authHandler := &handlers.AuthHandler{}
	taskHandler := &handlers.TaskHandler{}
	pomodoroHandler := &handlers.PomodoroHandler{}
	reportHandler := &handlers.ReportHandler{}

	// Auth routes
	auth := router.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.RefreshToken)
		auth.POST("/logout", authHandler.Logout)
	}

	// Protected routes
	api := router.Group("/api/v1")
	api.Use(middleware.Auth())
	{
		// Tasks
		tasks := api.Group("/tasks")
		{
			tasks.GET("", taskHandler.ListTasks)
			tasks.POST("", taskHandler.CreateTask)
			tasks.GET("/:id", taskHandler.GetTask)
			tasks.PUT("/:id", taskHandler.UpdateTask)
			tasks.DELETE("/:id", taskHandler.DeleteTask)
		}

		// Pomodoro sessions
		pomodoro := api.Group("/pomodoro")
		{
			pomodoro.POST("/sessions", pomodoroHandler.StartSession)
			pomodoro.PUT("/sessions/:id", pomodoroHandler.UpdateSession)
			pomodoro.GET("/sessions", pomodoroHandler.ListSessions)
			pomodoro.GET("/sessions/:id", pomodoroHandler.GetSession)
		}

		// Reports
		reports := api.Group("/reports")
		{
			reports.GET("", reportHandler.GenerateReport)
			reports.GET("/analytics", reportHandler.GetAnalytics)
		}
	}

	testServer := httptest.NewServer(router)

	return &PerformanceTestSuite{
		router:     router,
		testServer: testServer,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (s *PerformanceTestSuite) tearDown() {
	s.testServer.Close()
}

// TestAuthEndpointsPerformance tests authentication endpoints
func TestAuthEndpointsPerformance(t *testing.T) {
	suite := setupPerformanceTestSuite()
	defer suite.tearDown()

	t.Run("Register Performance", func(t *testing.T) {
		metrics := suite.testEndpointPerformance(t, "POST", "/auth/register", func(i int) []byte {
			user := map[string]interface{}{
				"name":     fmt.Sprintf("user%d", i),
				"email":    fmt.Sprintf("user%d@example.com", i),
				"password": "StrongPassword123!",
			}
			body, _ := json.Marshal(user)
			return body
		})

		suite.validatePerformanceMetrics(t, "Register", metrics)
	})

	t.Run("Login Performance", func(t *testing.T) {
		// First register some users for login testing
		suite.preCreateUsers(t, 10)

		metrics := suite.testEndpointPerformance(t, "POST", "/auth/login", func(i int) []byte {
			credentials := map[string]string{
				"email":    fmt.Sprintf("perfuser%d@example.com", i%10),
				"password": "StrongPassword123!",
			}
			body, _ := json.Marshal(credentials)
			return body
		})

		suite.validatePerformanceMetrics(t, "Login", metrics)
	})
}

// TestTaskEndpointsPerformance tests task management endpoints
func TestTaskEndpointsPerformance(t *testing.T) {
	suite := setupPerformanceTestSuite()
	defer suite.tearDown()

	// Setup authenticated context
	authToken := suite.getAuthToken(t)

	t.Run("List Tasks Performance", func(t *testing.T) {
		// Pre-create tasks for listing
		suite.preCreateTasks(t, authToken, 100)

		metrics := suite.testAuthenticatedEndpointPerformance(t, "GET", "/api/v1/tasks", authToken, func(i int) []byte {
			return nil // GET request with no body
		})

		suite.validatePerformanceMetrics(t, "List Tasks", metrics)
	})

	t.Run("Create Task Performance", func(t *testing.T) {
		metrics := suite.testAuthenticatedEndpointPerformance(t, "POST", "/api/v1/tasks", authToken, func(i int) []byte {
			task := map[string]interface{}{
				"title":                fmt.Sprintf("Performance Test Task %d", i),
				"description":          "Performance testing task",
				"priority":             "medium",
				"estimated_pomodoros":  3,
				"tags":                 []string{"performance", "test"},
			}
			body, _ := json.Marshal(task)
			return body
		})

		suite.validatePerformanceMetrics(t, "Create Task", metrics)
	})

	t.Run("Get Task Performance", func(t *testing.T) {
		// Pre-create tasks to fetch
		taskIDs := suite.preCreateTasksWithIDs(t, authToken, 50)

		metrics := suite.testAuthenticatedEndpointPerformance(t, "GET", "/api/v1/tasks/%s", authToken, func(i int) []byte {
			return nil // GET request with no body, URL will be formatted with task ID
		}, taskIDs...)

		suite.validatePerformanceMetrics(t, "Get Task", metrics)
	})
}

// TestPomodoroEndpointsPerformance tests pomodoro session endpoints
func TestPomodoroEndpointsPerformance(t *testing.T) {
	suite := setupPerformanceTestSuite()
	defer suite.tearDown()

	authToken := suite.getAuthToken(t)

	t.Run("Start Session Performance", func(t *testing.T) {
		// Pre-create tasks for sessions
		taskIDs := suite.preCreateTasksWithIDs(t, authToken, 20)

		metrics := suite.testAuthenticatedEndpointPerformance(t, "POST", "/api/v1/pomodoro/sessions", authToken, func(i int) []byte {
			session := map[string]interface{}{
				"task_id":          taskIDs[i%len(taskIDs)],
				"session_type":     "work",
				"planned_duration": 1500, // 25 minutes
			}
			body, _ := json.Marshal(session)
			return body
		})

		suite.validatePerformanceMetrics(t, "Start Session", metrics)
	})

	t.Run("List Sessions Performance", func(t *testing.T) {
		metrics := suite.testAuthenticatedEndpointPerformance(t, "GET", "/api/v1/pomodoro/sessions", authToken, func(i int) []byte {
			return nil
		})

		suite.validatePerformanceMetrics(t, "List Sessions", metrics)
	})
}

// TestConcurrentLoad tests system under concurrent load
func TestConcurrentLoad(t *testing.T) {
	suite := setupPerformanceTestSuite()
	defer suite.tearDown()

	authToken := suite.getAuthToken(t)

	t.Run("Concurrent Task Operations", func(t *testing.T) {
		results := make(chan TestResult, MaxConcurrentUsers*10)
		var wg sync.WaitGroup

		// Start concurrent workers
		for i := 0; i < MaxConcurrentUsers; i++ {
			wg.Add(1)
			go func(workerID int) {
				defer wg.Done()

				// Each worker performs multiple operations
				for j := 0; j < 10; j++ {
					// Create task
					createResult := suite.makeAuthenticatedRequest("POST", "/api/v1/tasks", authToken, func() []byte {
						task := map[string]interface{}{
							"title":       fmt.Sprintf("Concurrent Task %d-%d", workerID, j),
							"description": "Load test task",
							"priority":    "medium",
						}
						body, _ := json.Marshal(task)
						return body
					}())
					results <- createResult

					// List tasks
					listResult := suite.makeAuthenticatedRequest("GET", "/api/v1/tasks", authToken, nil)
					results <- listResult
				}
			}(i)
		}

		// Close results channel when all workers are done
		go func() {
			wg.Wait()
			close(results)
		}()

		// Collect results
		var allResults []TestResult
		for result := range results {
			allResults = append(allResults, result)
		}

		// Calculate metrics
		metrics := suite.calculateMetrics(allResults)

		// Validate concurrent load performance
		assert.Less(t, metrics.AverageResponse, MaxAPIResponseTime,
			"Average response time under concurrent load should be < %v", MaxAPIResponseTime)
		assert.Less(t, metrics.ErrorRate, AcceptableErrorRate,
			"Error rate under concurrent load should be < %v", AcceptableErrorRate)
		assert.Greater(t, metrics.Throughput, float64(MinThroughput),
			"Throughput under concurrent load should be > %v req/s", MinThroughput)

		t.Logf("Concurrent Load Test Results:")
		t.Logf("  Total Requests: %d", metrics.TotalRequests)
		t.Logf("  Success Rate: %.2f%%", (1-metrics.ErrorRate)*100)
		t.Logf("  Average Response: %v", metrics.AverageResponse)
		t.Logf("  P95 Response: %v", metrics.P95Response)
		t.Logf("  Throughput: %.2f req/s", metrics.Throughput)
	})
}

// TestSustainedLoad tests system performance over extended period
func TestSustainedLoad(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping sustained load test in short mode")
	}

	suite := setupPerformanceTestSuite()
	defer suite.tearDown()

	authToken := suite.getAuthToken(t)

	t.Run("Sustained API Load", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(context.Background(), TestDuration)
		defer cancel()

		results := make(chan TestResult, 10000)
		var wg sync.WaitGroup

		// Warmup period
		t.Log("Starting warmup period...")
		warmupCtx, warmupCancel := context.WithTimeout(context.Background(), WarmupDuration)
		suite.runLoadTest(warmupCtx, authToken, 10, results)
		warmupCancel()

		// Actual test
		t.Log("Starting sustained load test...")
		startTime := time.Now()

		// Start workers
		for i := 0; i < 20; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				suite.runLoadTest(ctx, authToken, 50, results)
			}()
		}

		// Monitor and collect results
		go func() {
			wg.Wait()
			close(results)
		}()

		var allResults []TestResult
		responseTimeSamples := make([]time.Duration, 0, 1000)

		for result := range results {
			allResults = append(allResults, result)
			if len(responseTimeSamples) < 1000 {
				responseTimeSamples = append(responseTimeSamples, result.ResponseTime)
			}

			// Log progress every 1000 requests
			if len(allResults)%1000 == 0 {
				elapsed := time.Since(startTime)
				currentThroughput := float64(len(allResults)) / elapsed.Seconds()
				t.Logf("Progress: %d requests, %.2f req/s", len(allResults), currentThroughput)
			}
		}

		// Calculate final metrics
		metrics := suite.calculateMetrics(allResults)

		// Validate sustained performance
		assert.Less(t, metrics.AverageResponse, MaxAPIResponseTime*2, // Allow 2x threshold for sustained load
			"Average response time under sustained load should be reasonable")
		assert.Less(t, metrics.ErrorRate, AcceptableErrorRate*2,
			"Error rate under sustained load should be acceptable")

		t.Logf("Sustained Load Test Results (%v):", TestDuration)
		t.Logf("  Total Requests: %d", metrics.TotalRequests)
		t.Logf("  Success Rate: %.2f%%", (1-metrics.ErrorRate)*100)
		t.Logf("  Average Response: %v", metrics.AverageResponse)
		t.Logf("  P95 Response: %v", metrics.P95Response)
		t.Logf("  P99 Response: %v", metrics.P99Response)
		t.Logf("  Throughput: %.2f req/s", metrics.Throughput)
	})
}

// Helper methods

func (s *PerformanceTestSuite) testEndpointPerformance(t *testing.T, method, endpoint string, bodyGenerator func(int) []byte) *PerformanceMetrics {
	const numRequests = 100
	results := make([]TestResult, numRequests)

	for i := 0; i < numRequests; i++ {
		body := bodyGenerator(i)
		url := s.testServer.URL + endpoint

		start := time.Now()
		req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
		require.NoError(t, err)

		if body != nil {
			req.Header.Set("Content-Type", "application/json")
		}

		resp, err := s.client.Do(req)
		duration := time.Since(start)

		result := TestResult{
			Endpoint:     endpoint,
			Method:       method,
			ResponseTime: duration,
			Timestamp:    start,
			RequestSize:  len(body),
		}

		if err != nil {
			result.Error = err
		} else {
			result.StatusCode = resp.StatusCode
			resp.Body.Close()
		}

		results[i] = result
	}

	return s.calculateMetrics(results)
}

func (s *PerformanceTestSuite) testAuthenticatedEndpointPerformance(t *testing.T, method, endpoint, authToken string, bodyGenerator func(int) []byte, pathParams ...string) *PerformanceMetrics {
	const numRequests = 100
	results := make([]TestResult, numRequests)

	for i := 0; i < numRequests; i++ {
		body := bodyGenerator(i)

		// Handle path parameters (e.g., task IDs)
		url := s.testServer.URL + endpoint
		if len(pathParams) > 0 && i < len(pathParams) {
			url = s.testServer.URL + fmt.Sprintf(endpoint, pathParams[i])
		}

		result := s.makeAuthenticatedRequest(method, url, authToken, body)
		results[i] = result
	}

	return s.calculateMetrics(results)
}

func (s *PerformanceTestSuite) makeAuthenticatedRequest(method, url, authToken string, body []byte) TestResult {
	start := time.Now()

	req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
	if err != nil {
		return TestResult{
			Method:       method,
			ResponseTime: time.Since(start),
			Error:        err,
			Timestamp:    start,
		}
	}

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Authorization", "Bearer "+authToken)

	resp, err := s.client.Do(req)
	duration := time.Since(start)

	result := TestResult{
		Method:       method,
		ResponseTime: duration,
		Timestamp:    start,
		RequestSize:  len(body),
	}

	if err != nil {
		result.Error = err
	} else {
		result.StatusCode = resp.StatusCode
		resp.Body.Close()
	}

	return result
}

func (s *PerformanceTestSuite) validatePerformanceMetrics(t *testing.T, testName string, metrics *PerformanceMetrics) {
	t.Helper()

	assert.Less(t, metrics.AverageResponse, MaxAPIResponseTime,
		"%s: Average response time should be < %v, got %v", testName, MaxAPIResponseTime, metrics.AverageResponse)

	assert.Less(t, metrics.P95Response, MaxAPIResponseTime*2,
		"%s: P95 response time should be < %v, got %v", testName, MaxAPIResponseTime*2, metrics.P95Response)

	assert.Less(t, metrics.ErrorRate, AcceptableErrorRate,
		"%s: Error rate should be < %v, got %v", testName, AcceptableErrorRate, metrics.ErrorRate)

	t.Logf("%s Performance Metrics:", testName)
	t.Logf("  Requests: %d (Success: %d, Failed: %d)", metrics.TotalRequests, metrics.SuccessfulRequests, metrics.FailedRequests)
	t.Logf("  Response Times - Avg: %v, Min: %v, Max: %v", metrics.AverageResponse, metrics.MinResponse, metrics.MaxResponse)
	t.Logf("  Percentiles - P95: %v, P99: %v", metrics.P95Response, metrics.P99Response)
	t.Logf("  Error Rate: %.2f%%, Throughput: %.2f req/s", metrics.ErrorRate*100, metrics.Throughput)
}

func (s *PerformanceTestSuite) calculateMetrics(results []TestResult) *PerformanceMetrics {
	if len(results) == 0 {
		return &PerformanceMetrics{}
	}

	metrics := &PerformanceMetrics{
		TotalRequests: len(results),
		MinResponse:   time.Hour, // Initialize to high value
	}

	var totalDuration time.Duration
	var responseTimes []time.Duration
	startTime := results[0].Timestamp
	var endTime time.Time

	for _, result := range results {
		responseTimes = append(responseTimes, result.ResponseTime)
		totalDuration += result.ResponseTime

		if result.ResponseTime < metrics.MinResponse {
			metrics.MinResponse = result.ResponseTime
		}
		if result.ResponseTime > metrics.MaxResponse {
			metrics.MaxResponse = result.ResponseTime
		}

		if result.Timestamp.After(endTime) {
			endTime = result.Timestamp.Add(result.ResponseTime)
		}

		if result.Error != nil || result.StatusCode >= 400 {
			metrics.FailedRequests++
		} else {
			metrics.SuccessfulRequests++
		}
	}

	// Calculate average
	metrics.AverageResponse = totalDuration / time.Duration(len(results))

	// Calculate percentiles
	metrics.P95Response = calculatePercentile(responseTimes, 0.95)
	metrics.P99Response = calculatePercentile(responseTimes, 0.99)

	// Calculate error rate
	metrics.ErrorRate = float64(metrics.FailedRequests) / float64(metrics.TotalRequests)

	// Calculate throughput
	testDuration := endTime.Sub(startTime)
	if testDuration > 0 {
		metrics.Throughput = float64(metrics.TotalRequests) / testDuration.Seconds()
	}

	return metrics
}

func calculatePercentile(durations []time.Duration, percentile float64) time.Duration {
	if len(durations) == 0 {
		return 0
	}

	// Simple percentile calculation (would use sort for accuracy in production)
	index := int(float64(len(durations)) * percentile)
	if index >= len(durations) {
		index = len(durations) - 1
	}

	// Find the value at the percentile index (simplified)
	max := time.Duration(0)
	count := 0
	for _, d := range durations {
		if count <= index {
			if d > max {
				max = d
			}
		}
		count++
	}

	return max
}

// Test data setup helpers

func (s *PerformanceTestSuite) getAuthToken(t *testing.T) string {
	// Register a test user
	user := map[string]string{
		"name":     "Performance Test User",
		"email":    "perftest@example.com",
		"password": "StrongPassword123!",
	}
	userJSON, _ := json.Marshal(user)

	req, _ := http.NewRequest("POST", s.testServer.URL+"/auth/register", bytes.NewBuffer(userJSON))
	req.Header.Set("Content-Type", "application/json")
	s.client.Do(req)

	// Login to get token
	credentials := map[string]string{
		"email":    "perftest@example.com",
		"password": "StrongPassword123!",
	}
	credJSON, _ := json.Marshal(credentials)

	req, _ = http.NewRequest("POST", s.testServer.URL+"/auth/login", bytes.NewBuffer(credJSON))
	req.Header.Set("Content-Type", "application/json")
	resp, _ := s.client.Do(req)
	defer resp.Body.Close()

	var loginResp struct {
		AccessToken string `json:"access_token"`
	}
	json.NewDecoder(resp.Body).Decode(&loginResp)

	return loginResp.AccessToken
}

func (s *PerformanceTestSuite) preCreateUsers(t *testing.T, count int) {
	for i := 0; i < count; i++ {
		user := map[string]string{
			"name":     fmt.Sprintf("Perf User %d", i),
			"email":    fmt.Sprintf("perfuser%d@example.com", i),
			"password": "StrongPassword123!",
		}
		userJSON, _ := json.Marshal(user)

		req, _ := http.NewRequest("POST", s.testServer.URL+"/auth/register", bytes.NewBuffer(userJSON))
		req.Header.Set("Content-Type", "application/json")
		s.client.Do(req)
	}
}

func (s *PerformanceTestSuite) preCreateTasks(t *testing.T, authToken string, count int) {
	for i := 0; i < count; i++ {
		task := map[string]interface{}{
			"title":       fmt.Sprintf("Pre-created Task %d", i),
			"description": "Task for performance testing",
			"priority":    "medium",
		}
		taskJSON, _ := json.Marshal(task)

		req, _ := http.NewRequest("POST", s.testServer.URL+"/api/v1/tasks", bytes.NewBuffer(taskJSON))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		s.client.Do(req)
	}
}

func (s *PerformanceTestSuite) preCreateTasksWithIDs(t *testing.T, authToken string, count int) []string {
	var taskIDs []string

	for i := 0; i < count; i++ {
		task := map[string]interface{}{
			"title":       fmt.Sprintf("Task with ID %d", i),
			"description": "Task for ID-based testing",
			"priority":    "medium",
		}
		taskJSON, _ := json.Marshal(task)

		req, _ := http.NewRequest("POST", s.testServer.URL+"/api/v1/tasks", bytes.NewBuffer(taskJSON))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+authToken)
		resp, _ := s.client.Do(req)

		if resp.StatusCode == 201 {
			var createdTask struct {
				ID string `json:"id"`
			}
			json.NewDecoder(resp.Body).Decode(&createdTask)
			taskIDs = append(taskIDs, createdTask.ID)
		}
		resp.Body.Close()
	}

	return taskIDs
}

func (s *PerformanceTestSuite) runLoadTest(ctx context.Context, authToken string, requestsPerWorker int, results chan<- TestResult) {
	endpoints := []struct {
		method string
		path   string
		body   func() []byte
	}{
		{"GET", "/api/v1/tasks", func() []byte { return nil }},
		{"POST", "/api/v1/tasks", func() []byte {
			task := map[string]interface{}{
				"title":       fmt.Sprintf("Load Test Task %d", time.Now().UnixNano()),
				"description": "Generated during load test",
				"priority":    "medium",
			}
			body, _ := json.Marshal(task)
			return body
		}},
	}

	for i := 0; i < requestsPerWorker; i++ {
		select {
		case <-ctx.Done():
			return
		default:
			endpoint := endpoints[i%len(endpoints)]
			body := endpoint.body()
			result := s.makeAuthenticatedRequest(endpoint.method, s.testServer.URL+endpoint.path, authToken, body)
			results <- result
		}
	}
}