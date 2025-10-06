package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

type RateLimiter interface {
	Allow(key string) bool
	GetLimit(key string) RateLimit
	Reset(key string)
	GetStats(key string) RateLimitStats
}

type RateLimit struct {
	Requests   int           `json:"requests"`
	Window     time.Duration `json:"window"`
	Remaining  int           `json:"remaining"`
	ResetTime  time.Time     `json:"reset_time"`
	RetryAfter time.Duration `json:"retry_after,omitempty"`
}

type RateLimitStats struct {
	TotalRequests   int64     `json:"total_requests"`
	BlockedRequests int64     `json:"blocked_requests"`
	LastRequest     time.Time `json:"last_request"`
	FirstSeen       time.Time `json:"first_seen"`
}

type RateLimitConfig struct {
	Requests       int                       `json:"requests"`
	Window         time.Duration             `json:"window"`
	KeyGenerator   func(*gin.Context) string `json:"-"`
	SkipHandler    func(*gin.Context) bool   `json:"-"`
	ErrorHandler   func(*gin.Context)        `json:"-"`
	HeadersEnabled bool                      `json:"headers_enabled"`
	Message        string                    `json:"message"`
	MaxMemoryKeys  int                       `json:"max_memory_keys"`
	CleanupWindow  time.Duration             `json:"cleanup_window"`
}

type RateLimitTier struct {
	Name        string        `json:"name"`
	Requests    int           `json:"requests"`
	Window      time.Duration `json:"window"`
	Burst       int           `json:"burst,omitempty"`
	Description string        `json:"description,omitempty"`
}

type inMemoryStore struct {
	mu           sync.RWMutex
	clients      map[string]*clientInfo
	maxKeys      int
	cleanupInterval time.Duration
}

type clientInfo struct {
	limiter   *rate.Limiter
	firstSeen time.Time
	lastSeen  time.Time
	requests  int64
	blocked   int64
	window    time.Duration
	limit     int
}

func NewInMemoryStore(maxKeys int, cleanup time.Duration) RateLimiter {
	store := &inMemoryStore{
		clients: make(map[string]*clientInfo),
		maxKeys: maxKeys,
		cleanupInterval: cleanup,
	}

	go store.cleanupRoutine()
	return store
}

func (s *inMemoryStore) Allow(key string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	client, exists := s.clients[key]
	if !exists {
		if len(s.clients) >= s.maxKeys {
			s.evictOldest()
		}

		client = &clientInfo{
			limiter:   rate.NewLimiter(rate.Every(time.Minute), 60),
			firstSeen: time.Now(),
			lastSeen:  time.Now(),
			requests:  0,
			blocked:   0,
			window:    time.Minute,
			limit:     60,
		}
		s.clients[key] = client
	}

	client.lastSeen = time.Now()
	client.requests++

	if client.limiter.Allow() {
		return true
	}

	client.blocked++
	return false
}

func (s *inMemoryStore) GetLimit(key string) RateLimit {
	s.mu.RLock()
	defer s.mu.RUnlock()

	client, exists := s.clients[key]
	if !exists {
		return RateLimit{
			Requests:  60,
			Window:    time.Minute,
			Remaining: 60,
			ResetTime: time.Now().Add(time.Minute),
		}
	}

	reservation := client.limiter.Reserve()
	remaining := int(client.limiter.Burst()) - 1
	if remaining < 0 {
		remaining = 0
	}

	resetTime := time.Now().Add(client.window)
	var retryAfter time.Duration
	if remaining == 0 {
		retryAfter = time.Until(resetTime)
	}

	reservation.Cancel()

	return RateLimit{
		Requests:   client.limit,
		Window:     client.window,
		Remaining:  remaining,
		ResetTime:  resetTime,
		RetryAfter: retryAfter,
	}
}

func (s *inMemoryStore) Reset(key string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	delete(s.clients, key)
}

func (s *inMemoryStore) GetStats(key string) RateLimitStats {
	s.mu.RLock()
	defer s.mu.RUnlock()

	client, exists := s.clients[key]
	if !exists {
		return RateLimitStats{}
	}

	return RateLimitStats{
		TotalRequests:   client.requests,
		BlockedRequests: client.blocked,
		LastRequest:     client.lastSeen,
		FirstSeen:       client.firstSeen,
	}
}

func (s *inMemoryStore) evictOldest() {
	var oldestKey string
	var oldestTime time.Time

	for key, client := range s.clients {
		if oldestKey == "" || client.lastSeen.Before(oldestTime) {
			oldestKey = key
			oldestTime = client.lastSeen
		}
	}

	if oldestKey != "" {
		delete(s.clients, oldestKey)
	}
}

func (s *inMemoryStore) cleanupRoutine() {
	ticker := time.NewTicker(s.cleanupInterval)
	defer ticker.Stop()

	for range ticker.C {
		s.cleanup()
	}
}

func (s *inMemoryStore) cleanup() {
	s.mu.Lock()
	defer s.mu.Unlock()

	cutoff := time.Now().Add(-s.cleanupInterval)
	for key, client := range s.clients {
		if client.lastSeen.Before(cutoff) {
			delete(s.clients, key)
		}
	}
}

func NewRateLimitMiddleware(config RateLimitConfig) gin.HandlerFunc {
	if config.Requests <= 0 {
		config.Requests = 100
	}
	if config.Window <= 0 {
		config.Window = time.Minute
	}
	if config.MaxMemoryKeys <= 0 {
		config.MaxMemoryKeys = 10000
	}
	if config.CleanupWindow <= 0 {
		config.CleanupWindow = 10 * time.Minute
	}
	if config.KeyGenerator == nil {
		config.KeyGenerator = defaultKeyGenerator
	}
	if config.Message == "" {
		config.Message = "Rate limit exceeded"
	}

	limiter := NewInMemoryStore(config.MaxMemoryKeys, config.CleanupWindow)

	return func(c *gin.Context) {
		if config.SkipHandler != nil && config.SkipHandler(c) {
			c.Next()
			return
		}

		key := config.KeyGenerator(c)
		if !limiter.Allow(key) {
			limit := limiter.GetLimit(key)

			if config.HeadersEnabled {
				setRateLimitHeaders(c, limit)
			}

			if config.ErrorHandler != nil {
				config.ErrorHandler(c)
			} else {
				c.JSON(http.StatusTooManyRequests, gin.H{
					"error": gin.H{
						"message":     config.Message,
						"type":        "rate_limit_error",
						"status_code": http.StatusTooManyRequests,
						"retry_after": int(limit.RetryAfter.Seconds()),
					},
					"success": false,
					"code":    "RATE_LIMIT_EXCEEDED",
				})
			}
			c.Abort()
			return
		}

		if config.HeadersEnabled {
			limit := limiter.GetLimit(key)
			setRateLimitHeaders(c, limit)
		}

		c.Next()
	}
}

func setRateLimitHeaders(c *gin.Context, limit RateLimit) {
	c.Header("X-RateLimit-Limit", strconv.Itoa(limit.Requests))
	c.Header("X-RateLimit-Remaining", strconv.Itoa(limit.Remaining))
	c.Header("X-RateLimit-Reset", strconv.FormatInt(limit.ResetTime.Unix(), 10))
	c.Header("X-RateLimit-Window", limit.Window.String())

	if limit.RetryAfter > 0 {
		c.Header("Retry-After", strconv.Itoa(int(limit.RetryAfter.Seconds())))
	}
}

func defaultKeyGenerator(c *gin.Context) string {
	return getClientIP(c)
}

func IPKeyGenerator(c *gin.Context) string {
	return "ip:" + getClientIP(c)
}

func UserKeyGenerator(c *gin.Context) string {
	userID := c.GetString("user_id")
	if userID == "" {
		return "ip:" + getClientIP(c)
	}
	return "user:" + userID
}

func EndpointKeyGenerator(c *gin.Context) string {
	ip := getClientIP(c)
	endpoint := c.Request.Method + ":" + c.FullPath()
	return fmt.Sprintf("endpoint:%s:%s", ip, endpoint)
}

func AuthenticatedUserKeyGenerator(c *gin.Context) string {
	userID := c.GetString("user_id")
	if userID == "" {
		return ""
	}
	return "auth_user:" + userID
}

func CombinedKeyGenerator(c *gin.Context) string {
	userID := c.GetString("user_id")
	ip := getClientIP(c)
	endpoint := c.Request.Method + ":" + c.FullPath()

	if userID != "" {
		return fmt.Sprintf("combined:user:%s:%s", userID, endpoint)
	}
	return fmt.Sprintf("combined:ip:%s:%s", ip, endpoint)
}

func getClientIP(c *gin.Context) string {
	if xff := c.GetHeader("X-Forwarded-For"); xff != "" {
		return xff
	}
	if xri := c.GetHeader("X-Real-IP"); xri != "" {
		return xri
	}
	return c.ClientIP()
}

func NewTieredRateLimitMiddleware(tiers map[string]RateLimitTier, tierSelector func(*gin.Context) string) gin.HandlerFunc {
	limiters := make(map[string]gin.HandlerFunc)

	for tierName, tier := range tiers {
		config := RateLimitConfig{
			Requests:       tier.Requests,
			Window:         tier.Window,
			KeyGenerator:   defaultKeyGenerator,
			HeadersEnabled: true,
			Message:        fmt.Sprintf("Rate limit exceeded for %s tier", tierName),
			MaxMemoryKeys:  10000,
			CleanupWindow:  10 * time.Minute,
		}
		limiters[tierName] = NewRateLimitMiddleware(config)
	}

	return func(c *gin.Context) {
		tierName := tierSelector(c)
		if limiter, exists := limiters[tierName]; exists {
			limiter(c)
		} else {
			c.Next()
		}
	}
}

func GlobalRateLimitMiddleware(requests int, window time.Duration) gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       requests,
		Window:         window,
		KeyGenerator:   func(c *gin.Context) string { return "global" },
		HeadersEnabled: true,
		Message:        "Global rate limit exceeded",
		MaxMemoryKeys:  1,
		CleanupWindow:  time.Hour,
	}
	return NewRateLimitMiddleware(config)
}

func PerIPRateLimitMiddleware(requests int, window time.Duration) gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       requests,
		Window:         window,
		KeyGenerator:   IPKeyGenerator,
		HeadersEnabled: true,
		Message:        "Rate limit exceeded for your IP address",
		MaxMemoryKeys:  10000,
		CleanupWindow:  10 * time.Minute,
	}
	return NewRateLimitMiddleware(config)
}

func PerUserRateLimitMiddleware(requests int, window time.Duration) gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       requests,
		Window:         window,
		KeyGenerator:   UserKeyGenerator,
		HeadersEnabled: true,
		Message:        "Rate limit exceeded for your account",
		MaxMemoryKeys:  50000,
		CleanupWindow:  30 * time.Minute,
	}
	return NewRateLimitMiddleware(config)
}

func PerEndpointRateLimitMiddleware(requests int, window time.Duration) gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       requests,
		Window:         window,
		KeyGenerator:   EndpointKeyGenerator,
		HeadersEnabled: true,
		Message:        "Rate limit exceeded for this endpoint",
		MaxMemoryKeys:  20000,
		CleanupWindow:  15 * time.Minute,
	}
	return NewRateLimitMiddleware(config)
}

func ConditionalRateLimitMiddleware(condition func(*gin.Context) bool, requests int, window time.Duration) gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       requests,
		Window:         window,
		KeyGenerator:   defaultKeyGenerator,
		SkipHandler:    func(c *gin.Context) bool { return !condition(c) },
		HeadersEnabled: true,
		Message:        "Rate limit exceeded",
		MaxMemoryKeys:  10000,
		CleanupWindow:  10 * time.Minute,
	}
	return NewRateLimitMiddleware(config)
}

func AuthRateLimitMiddleware() gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:       5,
		Window:         15 * time.Minute,
		KeyGenerator:   IPKeyGenerator,
		HeadersEnabled: true,
		Message:        "Too many authentication attempts. Please try again later.",
		MaxMemoryKeys:  5000,
		CleanupWindow:  30 * time.Minute,
		ErrorHandler: func(c *gin.Context) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"message":     "Too many authentication attempts",
					"type":        "rate_limit_error",
					"status_code": http.StatusTooManyRequests,
					"retry_after": 900,
				},
				"success": false,
				"code":    "AUTH_RATE_LIMIT_EXCEEDED",
			})
		},
	}
	return NewRateLimitMiddleware(config)
}

func APIKeyRateLimitMiddleware() gin.HandlerFunc {
	config := RateLimitConfig{
		Requests:      1000,
		Window:        time.Hour,
		KeyGenerator:  func(c *gin.Context) string { return "api_key:" + c.GetHeader("X-API-Key") },
		HeadersEnabled: true,
		Message:       "API key rate limit exceeded",
		MaxMemoryKeys: 10000,
		CleanupWindow: time.Hour,
	}
	return NewRateLimitMiddleware(config)
}

func BurstRateLimitMiddleware(requests int, window time.Duration, burst int) gin.HandlerFunc {
	store := &burstStore{
		limiters: make(map[string]*rate.Limiter),
		requests: requests,
		window:   window,
		burst:    burst,
	}

	return func(c *gin.Context) {
		key := defaultKeyGenerator(c)
		if !store.Allow(key) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"message":     "Burst rate limit exceeded",
					"type":        "rate_limit_error",
					"status_code": http.StatusTooManyRequests,
				},
				"success": false,
				"code":    "BURST_RATE_LIMIT_EXCEEDED",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

type burstStore struct {
	mu       sync.RWMutex
	limiters map[string]*rate.Limiter
	requests int
	window   time.Duration
	burst    int
}

func (s *burstStore) Allow(key string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	limiter, exists := s.limiters[key]
	if !exists {
		limiter = rate.NewLimiter(rate.Every(s.window/time.Duration(s.requests)), s.burst)
		s.limiters[key] = limiter
	}

	return limiter.Allow()
}

func CustomRateLimitKeyGenerator(keyFunc func(*gin.Context) string) func(*gin.Context) string {
	return keyFunc
}

func CompositeRateLimitMiddleware(middlewares ...gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		for _, middleware := range middlewares {
			middleware(c)
			if c.IsAborted() {
				return
			}
		}
		c.Next()
	}
}

func GetRateLimitInfo(c *gin.Context) map[string]interface{} {
	info := map[string]interface{}{
		"limit":      c.GetHeader("X-RateLimit-Limit"),
		"remaining":  c.GetHeader("X-RateLimit-Remaining"),
		"reset":      c.GetHeader("X-RateLimit-Reset"),
		"window":     c.GetHeader("X-RateLimit-Window"),
		"retry_after": c.GetHeader("Retry-After"),
	}

	return info
}

func IsRateLimited(c *gin.Context) bool {
	return c.GetHeader("X-RateLimit-Remaining") == "0"
}

func GetRetryAfter(c *gin.Context) string {
	return c.GetHeader("Retry-After")
}