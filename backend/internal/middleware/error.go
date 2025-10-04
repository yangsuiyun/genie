package middleware

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

type ErrorResponse struct {
	Error   ErrorDetail `json:"error"`
	Success bool        `json:"success"`
	Code    string      `json:"code"`
}

type ErrorDetail struct {
	Message    string                 `json:"message"`
	Type       string                 `json:"type"`
	Details    map[string]interface{} `json:"details,omitempty"`
	Timestamp  time.Time              `json:"timestamp"`
	RequestID  string                 `json:"request_id,omitempty"`
	Path       string                 `json:"path,omitempty"`
	Method     string                 `json:"method,omitempty"`
	StatusCode int                    `json:"status_code"`
}

type ValidationError struct {
	Field   string `json:"field"`
	Tag     string `json:"tag"`
	Value   string `json:"value"`
	Message string `json:"message"`
	Param   string `json:"param,omitempty"`
}

type ValidationErrors struct {
	Errors []ValidationError `json:"errors"`
}

const (
	ErrorTypeValidation      = "validation_error"
	ErrorTypeAuthentication  = "authentication_error"
	ErrorTypeAuthorization   = "authorization_error"
	ErrorTypeNotFound        = "not_found_error"
	ErrorTypeConflict        = "conflict_error"
	ErrorTypeRateLimit       = "rate_limit_error"
	ErrorTypeInternal        = "internal_error"
	ErrorTypeBadRequest      = "bad_request_error"
	ErrorTypeService         = "service_error"
	ErrorTypeDatabase        = "database_error"
	ErrorTypeExternal        = "external_service_error"
	ErrorTypeTimeout         = "timeout_error"
	ErrorTypeUnavailable     = "service_unavailable_error"
)

type ErrorHandlerConfig struct {
	EnableStackTrace bool
	EnableLogging    bool
	LogLevel         string
	MaxLogLength     int
	Environment      string
	CustomHandlers   map[string]func(*gin.Context, error) *ErrorResponse
}

func NewErrorHandler(config *ErrorHandlerConfig) gin.HandlerFunc {
	if config == nil {
		config = &ErrorHandlerConfig{
			EnableStackTrace: false,
			EnableLogging:    true,
			LogLevel:         "error",
			MaxLogLength:     1000,
			Environment:      "production",
			CustomHandlers:   make(map[string]func(*gin.Context, error) *ErrorResponse),
		}
	}

	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last()
			errorResponse := handleError(c, err.Err, config)

			if config.EnableLogging {
				logError(c, err.Err, errorResponse, config)
			}

			if !c.Writer.Written() {
				c.JSON(errorResponse.Error.StatusCode, errorResponse)
				c.Abort()
			}
		}
	}
}

func handleError(c *gin.Context, err error, config *ErrorHandlerConfig) *ErrorResponse {
	requestID := getRequestID(c)
	timestamp := time.Now()

	switch e := err.(type) {
	case validator.ValidationErrors:
		return handleValidationError(c, e, requestID, timestamp)
	case *json.UnmarshalTypeError:
		return handleJSONError(c, e, requestID, timestamp)
	case *json.SyntaxError:
		return handleJSONSyntaxError(c, e, requestID, timestamp)
	default:
		return handleGenericError(c, err, requestID, timestamp, config)
	}
}

func handleValidationError(c *gin.Context, errs validator.ValidationErrors, requestID string, timestamp time.Time) *ErrorResponse {
	var validationErrors []ValidationError

	for _, fieldError := range errs {
		validationError := ValidationError{
			Field: strings.ToLower(fieldError.Field()),
			Tag:   fieldError.Tag(),
			Value: fmt.Sprintf("%v", fieldError.Value()),
			Param: fieldError.Param(),
		}
		validationError.Message = generateValidationMessage(fieldError)
		validationErrors = append(validationErrors, validationError)
	}

	details := map[string]interface{}{
		"validation_errors": validationErrors,
		"error_count":       len(validationErrors),
	}

	return &ErrorResponse{
		Error: ErrorDetail{
			Message:    "Validation failed",
			Type:       ErrorTypeValidation,
			Details:    details,
			Timestamp:  timestamp,
			RequestID:  requestID,
			Path:       c.Request.URL.Path,
			Method:     c.Request.Method,
			StatusCode: http.StatusBadRequest,
		},
		Success: false,
		Code:    "VALIDATION_ERROR",
	}
}

func handleJSONError(c *gin.Context, err *json.UnmarshalTypeError, requestID string, timestamp time.Time) *ErrorResponse {
	details := map[string]interface{}{
		"field":    err.Field,
		"expected": err.Type.String(),
		"got":      err.Value,
		"offset":   err.Offset,
	}

	return &ErrorResponse{
		Error: ErrorDetail{
			Message:    fmt.Sprintf("Invalid JSON: expected %s for field '%s'", err.Type.String(), err.Field),
			Type:       ErrorTypeBadRequest,
			Details:    details,
			Timestamp:  timestamp,
			RequestID:  requestID,
			Path:       c.Request.URL.Path,
			Method:     c.Request.Method,
			StatusCode: http.StatusBadRequest,
		},
		Success: false,
		Code:    "JSON_TYPE_ERROR",
	}
}

func handleJSONSyntaxError(c *gin.Context, err *json.SyntaxError, requestID string, timestamp time.Time) *ErrorResponse {
	details := map[string]interface{}{
		"offset": err.Offset,
	}

	return &ErrorResponse{
		Error: ErrorDetail{
			Message:    "Invalid JSON syntax",
			Type:       ErrorTypeBadRequest,
			Details:    details,
			Timestamp:  timestamp,
			RequestID:  requestID,
			Path:       c.Request.URL.Path,
			Method:     c.Request.Method,
			StatusCode: http.StatusBadRequest,
		},
		Success: false,
		Code:    "JSON_SYNTAX_ERROR",
	}
}

func handleGenericError(c *gin.Context, err error, requestID string, timestamp time.Time, config *ErrorHandlerConfig) *ErrorResponse {
	errorMessage := err.Error()
	statusCode := http.StatusInternalServerError
	errorType := ErrorTypeInternal
	code := "INTERNAL_ERROR"

	if strings.Contains(strings.ToLower(errorMessage), "not found") {
		statusCode = http.StatusNotFound
		errorType = ErrorTypeNotFound
		code = "NOT_FOUND"
	} else if strings.Contains(strings.ToLower(errorMessage), "unauthorized") {
		statusCode = http.StatusUnauthorized
		errorType = ErrorTypeAuthentication
		code = "UNAUTHORIZED"
	} else if strings.Contains(strings.ToLower(errorMessage), "forbidden") {
		statusCode = http.StatusForbidden
		errorType = ErrorTypeAuthorization
		code = "FORBIDDEN"
	} else if strings.Contains(strings.ToLower(errorMessage), "conflict") {
		statusCode = http.StatusConflict
		errorType = ErrorTypeConflict
		code = "CONFLICT"
	} else if strings.Contains(strings.ToLower(errorMessage), "timeout") {
		statusCode = http.StatusRequestTimeout
		errorType = ErrorTypeTimeout
		code = "TIMEOUT"
	} else if strings.Contains(strings.ToLower(errorMessage), "rate limit") {
		statusCode = http.StatusTooManyRequests
		errorType = ErrorTypeRateLimit
		code = "RATE_LIMIT_EXCEEDED"
	} else if strings.Contains(strings.ToLower(errorMessage), "service unavailable") {
		statusCode = http.StatusServiceUnavailable
		errorType = ErrorTypeUnavailable
		code = "SERVICE_UNAVAILABLE"
	}

	details := map[string]interface{}{}

	if config.Environment == "development" && config.EnableStackTrace {
		details["stack_trace"] = string(debug.Stack())
	}

	if config.Environment == "development" {
		details["original_error"] = errorMessage
	} else {
		if statusCode >= 500 {
			errorMessage = "An internal server error occurred"
		}
	}

	return &ErrorResponse{
		Error: ErrorDetail{
			Message:    errorMessage,
			Type:       errorType,
			Details:    details,
			Timestamp:  timestamp,
			RequestID:  requestID,
			Path:       c.Request.URL.Path,
			Method:     c.Request.Method,
			StatusCode: statusCode,
		},
		Success: false,
		Code:    code,
	}
}

func generateValidationMessage(fieldError validator.FieldError) string {
	fieldName := strings.ToLower(fieldError.Field())

	switch fieldError.Tag() {
	case "required":
		return fmt.Sprintf("%s is required", fieldName)
	case "min":
		return fmt.Sprintf("%s must be at least %s characters long", fieldName, fieldError.Param())
	case "max":
		return fmt.Sprintf("%s must be at most %s characters long", fieldName, fieldError.Param())
	case "email":
		return "Please enter a valid email address"
	case "url":
		return "Please enter a valid URL"
	case "uuid4":
		return fmt.Sprintf("%s must be a valid UUID", fieldName)
	case "alpha":
		return fmt.Sprintf("%s must contain only letters", fieldName)
	case "alphanum":
		return fmt.Sprintf("%s must contain only letters and numbers", fieldName)
	case "numeric":
		return fmt.Sprintf("%s must be numeric", fieldName)
	case "eq":
		return fmt.Sprintf("%s must be equal to %s", fieldName, fieldError.Param())
	case "ne":
		return fmt.Sprintf("%s must not be equal to %s", fieldName, fieldError.Param())
	case "gt":
		return fmt.Sprintf("%s must be greater than %s", fieldName, fieldError.Param())
	case "gte":
		return fmt.Sprintf("%s must be greater than or equal to %s", fieldName, fieldError.Param())
	case "lt":
		return fmt.Sprintf("%s must be less than %s", fieldName, fieldError.Param())
	case "lte":
		return fmt.Sprintf("%s must be less than or equal to %s", fieldName, fieldError.Param())
	case "oneof":
		return fmt.Sprintf("%s must be one of: %s", fieldName, fieldError.Param())
	case "eqfield":
		return fmt.Sprintf("%s must match %s", fieldName, fieldError.Param())
	case "nefield":
		return fmt.Sprintf("%s must not match %s", fieldName, fieldError.Param())

	case "valid_email":
		return "Please enter a valid email address"
	case "strong_password":
		return "Password must contain at least 8 characters, including uppercase, lowercase, numbers, and special characters"
	case "valid_priority":
		return "Priority must be one of: low, medium, high, urgent"
	case "valid_status":
		return "Status must be one of: pending, in_progress, completed, cancelled"
	case "valid_session_type":
		return "Session type must be one of: work, short_break, long_break"
	case "valid_session_state":
		return "Session state must be one of: ready, running, paused, completed"
	case "valid_duration":
		return "Duration must be between 1 minute and 3 hours"
	case "valid_rating":
		return "Rating must be between 1 and 5 stars"
	case "valid_tag":
		return "Tag must contain only letters, numbers, hyphens, and underscores"
	case "valid_sort":
		return "Sort field must be one of the allowed values"
	case "future_date":
		return "Date must be in the future"

	default:
		return fmt.Sprintf("%s is invalid", fieldName)
	}
}

func logError(c *gin.Context, err error, errorResponse *ErrorResponse, config *ErrorHandlerConfig) {
	logMessage := fmt.Sprintf(
		"[ERROR] %s %s - %s - RequestID: %s - Status: %d",
		c.Request.Method,
		c.Request.URL.Path,
		err.Error(),
		errorResponse.Error.RequestID,
		errorResponse.Error.StatusCode,
	)

	if config.MaxLogLength > 0 && len(logMessage) > config.MaxLogLength {
		logMessage = logMessage[:config.MaxLogLength] + "..."
	}

	if errorResponse.Error.StatusCode >= 500 {
		log.Printf("CRITICAL: %s", logMessage)
		if config.EnableStackTrace {
			log.Printf("Stack trace: %s", string(debug.Stack()))
		}
	} else if errorResponse.Error.StatusCode >= 400 {
		log.Printf("WARNING: %s", logMessage)
	} else {
		log.Printf("INFO: %s", logMessage)
	}
}

func getRequestID(c *gin.Context) string {
	if requestID := c.GetHeader("X-Request-ID"); requestID != "" {
		return requestID
	}
	if requestID := c.GetString("request_id"); requestID != "" {
		return requestID
	}
	return generateRequestID()
}

func generateRequestID() string {
	return fmt.Sprintf("req_%d", time.Now().UnixNano())
}

func AbortWithError(c *gin.Context, statusCode int, err error) {
	c.Error(err)
	c.Abort()
}

func AbortWithValidationError(c *gin.Context, err error) {
	c.Error(err)
	c.Abort()
}

func AbortWithCustomError(c *gin.Context, statusCode int, errorType, message, code string) {
	customErr := &CustomError{
		StatusCode: statusCode,
		Type:       errorType,
		Message:    message,
		Code:       code,
	}
	c.Error(customErr)
	c.Abort()
}

type CustomError struct {
	StatusCode int
	Type       string
	Message    string
	Code       string
	Details    map[string]interface{}
}

func (e *CustomError) Error() string {
	return e.Message
}

func NewCustomError(statusCode int, errorType, message, code string) *CustomError {
	return &CustomError{
		StatusCode: statusCode,
		Type:       errorType,
		Message:    message,
		Code:       code,
		Details:    make(map[string]interface{}),
	}
}

func (e *CustomError) WithDetails(details map[string]interface{}) *CustomError {
	e.Details = details
	return e
}

func NewValidationError(message string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusBadRequest,
		Type:       ErrorTypeValidation,
		Message:    message,
		Code:       "VALIDATION_ERROR",
	}
}

func NewAuthenticationError(message string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusUnauthorized,
		Type:       ErrorTypeAuthentication,
		Message:    message,
		Code:       "AUTHENTICATION_ERROR",
	}
}

func NewAuthorizationError(message string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusForbidden,
		Type:       ErrorTypeAuthorization,
		Message:    message,
		Code:       "AUTHORIZATION_ERROR",
	}
}

func NewNotFoundError(resource string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusNotFound,
		Type:       ErrorTypeNotFound,
		Message:    fmt.Sprintf("%s not found", resource),
		Code:       "NOT_FOUND",
	}
}

func NewConflictError(message string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusConflict,
		Type:       ErrorTypeConflict,
		Message:    message,
		Code:       "CONFLICT_ERROR",
	}
}

func NewRateLimitError() *CustomError {
	return &CustomError{
		StatusCode: http.StatusTooManyRequests,
		Type:       ErrorTypeRateLimit,
		Message:    "Rate limit exceeded",
		Code:       "RATE_LIMIT_EXCEEDED",
	}
}

func NewInternalError(message string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusInternalServerError,
		Type:       ErrorTypeInternal,
		Message:    message,
		Code:       "INTERNAL_ERROR",
	}
}

func NewServiceUnavailableError(service string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusServiceUnavailable,
		Type:       ErrorTypeUnavailable,
		Message:    fmt.Sprintf("%s service is currently unavailable", service),
		Code:       "SERVICE_UNAVAILABLE",
	}
}

func NewTimeoutError(operation string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusRequestTimeout,
		Type:       ErrorTypeTimeout,
		Message:    fmt.Sprintf("%s operation timed out", operation),
		Code:       "TIMEOUT_ERROR",
	}
}

func NewDatabaseError(operation string) *CustomError {
	return &CustomError{
		StatusCode: http.StatusInternalServerError,
		Type:       ErrorTypeDatabase,
		Message:    fmt.Sprintf("Database %s failed", operation),
		Code:       "DATABASE_ERROR",
	}
}

func NewExternalServiceError(service string, err error) *CustomError {
	return &CustomError{
		StatusCode: http.StatusBadGateway,
		Type:       ErrorTypeExternal,
		Message:    fmt.Sprintf("External service %s error: %v", service, err),
		Code:       "EXTERNAL_SERVICE_ERROR",
	}
}

func RecoveryMiddleware() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		if err, ok := recovered.(string); ok {
			c.Error(fmt.Errorf("panic: %s", err))
		} else if err, ok := recovered.(error); ok {
			c.Error(fmt.Errorf("panic: %v", err))
		} else {
			c.Error(fmt.Errorf("panic: %v", recovered))
		}

		c.AbortWithStatus(http.StatusInternalServerError)
	})
}

func ErrorSummary(c *gin.Context) map[string]interface{} {
	summary := map[string]interface{}{
		"has_errors":  false,
		"error_count": 0,
		"errors":      []string{},
		"request_id":  getRequestID(c),
		"timestamp":   time.Now(),
		"path":        c.Request.URL.Path,
		"method":      c.Request.Method,
	}

	if len(c.Errors) > 0 {
		summary["has_errors"] = true
		summary["error_count"] = len(c.Errors)

		var errorMessages []string
		for _, err := range c.Errors {
			errorMessages = append(errorMessages, err.Error())
		}
		summary["errors"] = errorMessages
	}

	return summary
}

func GetLastError(c *gin.Context) error {
	if len(c.Errors) > 0 {
		return c.Errors.Last().Err
	}
	return nil
}

func HasErrors(c *gin.Context) bool {
	return len(c.Errors) > 0
}

func ClearErrors(c *gin.Context) {
	c.Errors = c.Errors[:0]
}