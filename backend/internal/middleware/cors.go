package middleware

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type CORSConfig struct {
	AllowOrigins     []string      `json:"allow_origins"`
	AllowMethods     []string      `json:"allow_methods"`
	AllowHeaders     []string      `json:"allow_headers"`
	ExposeHeaders    []string      `json:"expose_headers"`
	AllowCredentials bool          `json:"allow_credentials"`
	MaxAge           time.Duration `json:"max_age"`
	AllowWildcard    bool          `json:"allow_wildcard"`
	AllowBrowserExt  bool          `json:"allow_browser_extensions"`
	AllowWebSockets  bool          `json:"allow_websockets"`
	AllowFiles       bool          `json:"allow_files"`
	TrustedProxies   []string      `json:"trusted_proxies"`
}

type CORSOriginValidator func(origin string) bool

var (
	DefaultCORSConfig = CORSConfig{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodHead,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Length",
			"Content-Type",
			"Authorization",
			"Accept",
			"X-Requested-With",
			"X-Request-ID",
			"X-API-Key",
		},
		ExposeHeaders: []string{
			"Content-Length",
			"X-Request-ID",
			"X-RateLimit-Limit",
			"X-RateLimit-Remaining",
			"X-RateLimit-Reset",
		},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
		AllowWildcard:    true,
		AllowBrowserExt:  false,
		AllowWebSockets:  true,
		AllowFiles:       false,
	}

	ProductionCORSConfig = CORSConfig{
		AllowOrigins: []string{
			"https://app.pomodoro.com",
			"https://pomodoro.com",
			"https://www.pomodoro.com",
		},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Length",
			"Content-Type",
			"Authorization",
			"Accept",
			"X-Requested-With",
			"X-Request-ID",
			"X-API-Key",
		},
		ExposeHeaders: []string{
			"Content-Length",
			"X-Request-ID",
			"X-RateLimit-Limit",
			"X-RateLimit-Remaining",
			"X-RateLimit-Reset",
		},
		AllowCredentials: true,
		MaxAge:           6 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  false,
		AllowWebSockets:  true,
		AllowFiles:       false,
	}

	DevelopmentCORSConfig = CORSConfig{
		AllowOrigins: []string{
			"http://localhost:3000",
			"http://localhost:3001",
			"http://localhost:8080",
			"http://localhost:8081",
			"http://127.0.0.1:3000",
			"http://127.0.0.1:3001",
			"http://127.0.0.1:8080",
			"http://127.0.0.1:8081",
		},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodHead,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Length",
			"Content-Type",
			"Authorization",
			"Accept",
			"X-Requested-With",
			"X-Request-ID",
			"X-API-Key",
			"X-Developer-Mode",
		},
		ExposeHeaders: []string{
			"Content-Length",
			"X-Request-ID",
			"X-RateLimit-Limit",
			"X-RateLimit-Remaining",
			"X-RateLimit-Reset",
			"X-Debug-Info",
		},
		AllowCredentials: true,
		MaxAge:           1 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  true,
		AllowWebSockets:  true,
		AllowFiles:       true,
	}
)

func NewCORSMiddleware(config CORSConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		method := c.Request.Method

		if origin == "" {
			c.Next()
			return
		}

		if !isOriginAllowed(origin, config) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"message":     "Origin not allowed by CORS policy",
					"type":        "cors_error",
					"origin":      origin,
					"status_code": http.StatusForbidden,
				},
				"success": false,
				"code":    "CORS_ORIGIN_NOT_ALLOWED",
			})
			return
		}

		setAllowOriginHeader(c, origin, config)

		if config.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		if len(config.ExposeHeaders) > 0 {
			c.Header("Access-Control-Expose-Headers", strings.Join(config.ExposeHeaders, ", "))
		}

		if method == http.MethodOptions {
			handlePreflightRequest(c, config)
			return
		}

		c.Next()
	}
}

func isOriginAllowed(origin string, config CORSConfig) bool {
	if len(config.AllowOrigins) == 0 {
		return false
	}

	for _, allowedOrigin := range config.AllowOrigins {
		if allowedOrigin == "*" && config.AllowWildcard {
			return true
		}

		if allowedOrigin == origin {
			return true
		}

		if config.AllowBrowserExt && isBrowserExtension(origin) {
			return true
		}

		if config.AllowFiles && isFileProtocol(origin) {
			return true
		}

		if strings.HasPrefix(allowedOrigin, "*.") {
			domain := strings.TrimPrefix(allowedOrigin, "*.")
			if strings.HasSuffix(origin, "."+domain) || origin == "https://"+domain || origin == "http://"+domain {
				return true
			}
		}
	}

	return false
}

func isBrowserExtension(origin string) bool {
	return strings.HasPrefix(origin, "chrome-extension://") ||
		strings.HasPrefix(origin, "moz-extension://") ||
		strings.HasPrefix(origin, "safari-extension://") ||
		strings.HasPrefix(origin, "ms-browser-extension://")
}

func isFileProtocol(origin string) bool {
	return strings.HasPrefix(origin, "file://")
}

func setAllowOriginHeader(c *gin.Context, origin string, config CORSConfig) {
	if config.AllowWildcard && len(config.AllowOrigins) == 1 && config.AllowOrigins[0] == "*" {
		if config.AllowCredentials {
			c.Header("Access-Control-Allow-Origin", origin)
		} else {
			c.Header("Access-Control-Allow-Origin", "*")
		}
	} else {
		c.Header("Access-Control-Allow-Origin", origin)
	}
}

func handlePreflightRequest(c *gin.Context, config CORSConfig) {
	requestMethod := c.GetHeader("Access-Control-Request-Method")
	requestHeaders := c.GetHeader("Access-Control-Request-Headers")

	if !isMethodAllowed(requestMethod, config.AllowMethods) {
		c.AbortWithStatusJSON(http.StatusMethodNotAllowed, gin.H{
			"error": gin.H{
				"message":     "Method not allowed by CORS policy",
				"type":        "cors_error",
				"method":      requestMethod,
				"status_code": http.StatusMethodNotAllowed,
			},
			"success": false,
			"code":    "CORS_METHOD_NOT_ALLOWED",
		})
		return
	}

	if requestHeaders != "" && !areHeadersAllowed(requestHeaders, config.AllowHeaders) {
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error": gin.H{
				"message":     "Headers not allowed by CORS policy",
				"type":        "cors_error",
				"headers":     requestHeaders,
				"status_code": http.StatusForbidden,
			},
			"success": false,
			"code":    "CORS_HEADERS_NOT_ALLOWED",
		})
		return
	}

	c.Header("Access-Control-Allow-Methods", strings.Join(config.AllowMethods, ", "))

	if len(config.AllowHeaders) > 0 {
		c.Header("Access-Control-Allow-Headers", strings.Join(config.AllowHeaders, ", "))
	}

	if config.MaxAge > 0 {
		c.Header("Access-Control-Max-Age", strconv.Itoa(int(config.MaxAge.Seconds())))
	}

	c.Status(http.StatusNoContent)
	c.Abort()
}

func isMethodAllowed(method string, allowedMethods []string) bool {
	if method == "" {
		return false
	}

	for _, allowedMethod := range allowedMethods {
		if allowedMethod == method {
			return true
		}
	}
	return false
}

func areHeadersAllowed(requestHeaders string, allowedHeaders []string) bool {
	if requestHeaders == "" {
		return true
	}

	requestHeaderList := strings.Split(requestHeaders, ",")
	for _, header := range requestHeaderList {
		header = strings.TrimSpace(strings.ToLower(header))
		if !isHeaderAllowed(header, allowedHeaders) {
			return false
		}
	}
	return true
}

func isHeaderAllowed(header string, allowedHeaders []string) bool {
	header = strings.ToLower(header)

	for _, allowedHeader := range allowedHeaders {
		if strings.ToLower(allowedHeader) == header {
			return true
		}
		if allowedHeader == "*" {
			return true
		}
	}

	switch header {
	case "accept", "accept-language", "content-language", "content-type":
		return true
	}

	return false
}

func DefaultCORS() gin.HandlerFunc {
	return NewCORSMiddleware(DefaultCORSConfig)
}

func ProductionCORS() gin.HandlerFunc {
	return NewCORSMiddleware(ProductionCORSConfig)
}

func DevelopmentCORS() gin.HandlerFunc {
	return NewCORSMiddleware(DevelopmentCORSConfig)
}

func CustomCORS(config CORSConfig) gin.HandlerFunc {
	return NewCORSMiddleware(config)
}

func AllowOrigins(origins ...string) gin.HandlerFunc {
	config := DefaultCORSConfig
	config.AllowOrigins = origins
	config.AllowWildcard = false
	return NewCORSMiddleware(config)
}

func AllowAllOrigins() gin.HandlerFunc {
	config := DefaultCORSConfig
	config.AllowOrigins = []string{"*"}
	config.AllowWildcard = true
	config.AllowCredentials = false
	return NewCORSMiddleware(config)
}

func AllowCredentials() gin.HandlerFunc {
	config := DefaultCORSConfig
	config.AllowCredentials = true
	config.AllowWildcard = false
	return NewCORSMiddleware(config)
}

func StrictCORS(allowedOrigins []string) gin.HandlerFunc {
	config := CORSConfig{
		AllowOrigins: allowedOrigins,
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Type",
			"Authorization",
			"Accept",
		},
		ExposeHeaders: []string{
			"Content-Length",
		},
		AllowCredentials: true,
		MaxAge:           1 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  false,
		AllowWebSockets:  false,
		AllowFiles:       false,
	}
	return NewCORSMiddleware(config)
}

func APIOnlyCORS(allowedOrigins []string) gin.HandlerFunc {
	config := CORSConfig{
		AllowOrigins: allowedOrigins,
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Content-Type",
			"Authorization",
			"X-API-Key",
			"X-Request-ID",
		},
		ExposeHeaders: []string{
			"X-Request-ID",
			"X-RateLimit-Limit",
			"X-RateLimit-Remaining",
			"X-RateLimit-Reset",
		},
		AllowCredentials: false,
		MaxAge:           24 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  false,
		AllowWebSockets:  false,
		AllowFiles:       false,
	}
	return NewCORSMiddleware(config)
}

func ConditionalCORS(condition func(*gin.Context) bool, config CORSConfig) gin.HandlerFunc {
	corsMiddleware := NewCORSMiddleware(config)

	return func(c *gin.Context) {
		if condition(c) {
			corsMiddleware(c)
		} else {
			c.Next()
		}
	}
}

func OriginValidatorCORS(validator CORSOriginValidator) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if origin == "" {
			c.Next()
			return
		}

		if !validator(origin) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"message":     "Origin not allowed by CORS policy",
					"type":        "cors_error",
					"origin":      origin,
					"status_code": http.StatusForbidden,
				},
				"success": false,
				"code":    "CORS_ORIGIN_NOT_ALLOWED",
			})
			return
		}

		config := DefaultCORSConfig
		config.AllowOrigins = []string{origin}
		config.AllowWildcard = false

		corsMiddleware := NewCORSMiddleware(config)
		corsMiddleware(c)
	}
}

func WebSocketCORS(allowedOrigins []string) gin.HandlerFunc {
	config := CORSConfig{
		AllowOrigins: allowedOrigins,
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Type",
			"Authorization",
			"Sec-WebSocket-Key",
			"Sec-WebSocket-Version",
			"Sec-WebSocket-Extensions",
			"Sec-WebSocket-Protocol",
			"Connection",
			"Upgrade",
		},
		ExposeHeaders: []string{
			"Sec-WebSocket-Accept",
			"Sec-WebSocket-Protocol",
		},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  false,
		AllowWebSockets:  true,
		AllowFiles:       false,
	}
	return NewCORSMiddleware(config)
}

func MobileCORS() gin.HandlerFunc {
	config := CORSConfig{
		AllowOrigins: []string{
			"capacitor://localhost",
			"ionic://localhost",
			"http://localhost",
			"https://localhost",
			"file://",
		},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowHeaders: []string{
			"Origin",
			"Content-Type",
			"Authorization",
			"Accept",
			"X-Requested-With",
			"X-Request-ID",
			"X-Platform",
			"X-App-Version",
		},
		ExposeHeaders: []string{
			"Content-Length",
			"X-Request-ID",
		},
		AllowCredentials: true,
		MaxAge:           6 * time.Hour,
		AllowWildcard:    false,
		AllowBrowserExt:  false,
		AllowWebSockets:  true,
		AllowFiles:       true,
	}
	return NewCORSMiddleware(config)
}

func DynamicOriginCORS(originProvider func() []string) gin.HandlerFunc {
	return func(c *gin.Context) {
		allowedOrigins := originProvider()
		config := DefaultCORSConfig
		config.AllowOrigins = allowedOrigins
		config.AllowWildcard = false

		corsMiddleware := NewCORSMiddleware(config)
		corsMiddleware(c)
	}
}

func GetCORSInfo(c *gin.Context) map[string]interface{} {
	return map[string]interface{}{
		"origin":                c.GetHeader("Origin"),
		"access_control_origin": c.GetHeader("Access-Control-Allow-Origin"),
		"methods":               c.GetHeader("Access-Control-Allow-Methods"),
		"headers":               c.GetHeader("Access-Control-Allow-Headers"),
		"credentials":           c.GetHeader("Access-Control-Allow-Credentials"),
		"max_age":               c.GetHeader("Access-Control-Max-Age"),
		"expose_headers":        c.GetHeader("Access-Control-Expose-Headers"),
	}
}

func SetCORSHeaders(c *gin.Context, config CORSConfig) {
	origin := c.GetHeader("Origin")
	if origin != "" && isOriginAllowed(origin, config) {
		setAllowOriginHeader(c, origin, config)

		if config.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		if len(config.ExposeHeaders) > 0 {
			c.Header("Access-Control-Expose-Headers", strings.Join(config.ExposeHeaders, ", "))
		}
	}
}

func CORSValidationMiddleware(config CORSConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if origin != "" {
			if !isOriginAllowed(origin, config) {
				c.Set("cors_validation_failed", true)
				c.Set("cors_invalid_origin", origin)
			}
		}

		c.Next()
	}
}