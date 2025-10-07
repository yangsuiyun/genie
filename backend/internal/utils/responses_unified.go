package utils

import (
	"encoding/json"
	"net/http"
)

// ========== UNIFIED RESPONSE STRUCTURES ==========
// This replaces duplicate ErrorResponse, SuccessResponse, and other response types
// scattered across handlers, middleware, and services

// UnifiedResponse is the canonical response structure for all API endpoints
type UnifiedResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo  `json:"error,omitempty"`
	Meta    *MetaInfo   `json:"meta,omitempty"`
	Message string      `json:"message,omitempty"`
}

// ErrorInfo replaces all duplicate ErrorResponse types
type ErrorInfo struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
	Type    string      `json:"type,omitempty"`     // for middleware compatibility
}

// MetaInfo contains metadata like pagination
type MetaInfo struct {
	Page       int `json:"page,omitempty"`
	Limit      int `json:"limit,omitempty"`
	Total      int `json:"total,omitempty"`
	TotalPages int `json:"total_pages,omitempty"`
	HasNext    bool `json:"has_next,omitempty"`
	HasPrev    bool `json:"has_prev,omitempty"`
}

// ========== FACTORY FUNCTIONS ==========

// NewSuccessResponse creates a successful response (replaces SuccessResponse)
func NewSuccessResponse(data interface{}, message ...string) UnifiedResponse {
	response := UnifiedResponse{
		Success: true,
		Data:    data,
	}
	if len(message) > 0 {
		response.Message = message[0]
	}
	return response
}

// NewErrorResponse creates an error response (replaces ErrorResponse)
func NewErrorResponse(code, message string, details interface{}) UnifiedResponse {
	return UnifiedResponse{
		Success: false,
		Error: &ErrorInfo{
			Code:    code,
			Message: message,
			Details: details,
		},
	}
}

// NewPaginatedResponse creates a paginated response
func NewPaginatedResponse(data interface{}, page, limit, total int, message ...string) UnifiedResponse {
	totalPages := (total + limit - 1) / limit
	if totalPages < 1 {
		totalPages = 1
	}

	response := UnifiedResponse{
		Success: true,
		Data:    data,
		Meta: &MetaInfo{
			Page:       page,
			Limit:      limit,
			Total:      total,
			TotalPages: totalPages,
			HasNext:    page < totalPages,
			HasPrev:    page > 1,
		},
	}
	if len(message) > 0 {
		response.Message = message[0]
	}
	return response
}

// ========== LEGACY COMPATIBILITY TYPES ==========
// These maintain compatibility with existing code during migration

// ErrorResponse (auth.go compatible)
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// MiddlewareErrorResponse (middleware/error.go compatible)
type MiddlewareErrorResponse struct {
	Error   ErrorDetail `json:"error"`
	Success bool        `json:"success"`
	Code    string      `json:"code"`
}

type ErrorDetail struct {
	Message    string                 `json:"message"`
	Type       string                 `json:"type"`
	Details    map[string]interface{} `json:"details,omitempty"`
}

// SuccessResponse (auth.go compatible)
type SuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// AuthResponse (services compatible)
type AuthResponse struct {
	User  interface{} `json:"user"`
	Token string      `json:"token"`
}

// TaskListResponse (services compatible)
type TaskListResponse struct {
	Tasks      interface{} `json:"tasks"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalPages int         `json:"total_pages"`
}

// PaginatedReportsResponse (handlers compatible)
type PaginatedReportsResponse struct {
	Reports    interface{} `json:"reports"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalPages int         `json:"total_pages"`
}

// PaginatedSessionsResponse (handlers compatible)
type PaginatedSessionsResponse struct {
	Sessions   interface{} `json:"sessions"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalPages int         `json:"total_pages"`
}

// ========== UNIFIED HTTP HELPER FUNCTIONS ==========

// SendUnifiedResponse sends a unified response
func SendUnifiedResponse(w http.ResponseWriter, response UnifiedResponse, statusCode int) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	return json.NewEncoder(w).Encode(response)
}

// SendUnifiedSuccess sends a successful unified response
func SendUnifiedSuccess(w http.ResponseWriter, data interface{}, message ...string) error {
	return SendUnifiedResponse(w, NewSuccessResponse(data, message...), http.StatusOK)
}

// SendUnifiedError sends an error unified response
func SendUnifiedError(w http.ResponseWriter, statusCode int, code, message string, details interface{}) error {
	return SendUnifiedResponse(w, NewErrorResponse(code, message, details), statusCode)
}

// SendUnifiedPaginated sends a paginated unified response
func SendUnifiedPaginated(w http.ResponseWriter, data interface{}, page, limit, total int, message ...string) error {
	return SendUnifiedResponse(w, NewPaginatedResponse(data, page, limit, total, message...), http.StatusOK)
}

// ========== MIGRATION HELPER FUNCTIONS ==========
// These help convert legacy response types to unified format

// ConvertErrorResponse converts legacy ErrorResponse to UnifiedResponse
func ConvertErrorResponse(er ErrorResponse) UnifiedResponse {
	return NewErrorResponse("ERROR", er.Message, er.Details)
}

// ConvertSuccessResponse converts legacy SuccessResponse to UnifiedResponse
func ConvertSuccessResponse(sr SuccessResponse) UnifiedResponse {
	return NewSuccessResponse(sr.Data, sr.Message)
}

// ConvertMiddlewareErrorResponse converts middleware ErrorResponse to UnifiedResponse
func ConvertMiddlewareErrorResponse(mer MiddlewareErrorResponse) UnifiedResponse {
	return UnifiedResponse{
		Success: mer.Success,
		Error: &ErrorInfo{
			Code:    mer.Code,
			Message: mer.Error.Message,
			Type:    mer.Error.Type,
			Details: mer.Error.Details,
		},
	}
}

// ConvertTaskListResponse converts TaskListResponse to UnifiedResponse
func ConvertTaskListResponse(tlr TaskListResponse) UnifiedResponse {
	return NewPaginatedResponse(tlr.Tasks, tlr.Page, tlr.Limit, tlr.Total)
}

// ConvertAuthResponse converts AuthResponse to UnifiedResponse
func ConvertAuthResponse(ar AuthResponse) UnifiedResponse {
	return NewSuccessResponse(map[string]interface{}{
		"user":  ar.User,
		"token": ar.Token,
	}, "Authentication successful")
}

// ========== COMMON ERROR CODES ==========
var UnifiedErrorCodes = struct {
	ValidationError      string
	NotFound            string
	Unauthorized        string
	Forbidden           string
	Conflict            string
	InternalError       string
	RateLimitExceeded   string
	BadRequest          string
	ServiceUnavailable  string
	DatabaseError       string
	AuthenticationFailed string
	TokenExpired        string
	InvalidInput        string
}{
	ValidationError:      "VALIDATION_ERROR",
	NotFound:           "NOT_FOUND",
	Unauthorized:       "UNAUTHORIZED",
	Forbidden:          "FORBIDDEN",
	Conflict:           "CONFLICT",
	InternalError:      "INTERNAL_ERROR",
	RateLimitExceeded:  "RATE_LIMIT_EXCEEDED",
	BadRequest:         "BAD_REQUEST",
	ServiceUnavailable: "SERVICE_UNAVAILABLE",
	DatabaseError:      "DATABASE_ERROR",
	AuthenticationFailed: "AUTHENTICATION_FAILED",
	TokenExpired:       "TOKEN_EXPIRED",
	InvalidInput:       "INVALID_INPUT",
}

// ========== QUICK RESPONSE FUNCTIONS ==========

// QuickSuccess sends immediate success response
func QuickSuccess(w http.ResponseWriter, data interface{}) error {
	return SendUnifiedSuccess(w, data)
}

// QuickError sends immediate error response
func QuickError(w http.ResponseWriter, statusCode int, message string) error {
	return SendUnifiedError(w, statusCode, UnifiedErrorCodes.InternalError, message, nil)
}

// QuickValidationError sends immediate validation error
func QuickValidationError(w http.ResponseWriter, details interface{}) error {
	return SendUnifiedError(w, http.StatusBadRequest, UnifiedErrorCodes.ValidationError, "Invalid input data", details)
}

// QuickNotFound sends immediate not found error
func QuickNotFound(w http.ResponseWriter, resource string) error {
	return SendUnifiedError(w, http.StatusNotFound, UnifiedErrorCodes.NotFound, resource+" not found", nil)
}

// QuickUnauthorized sends immediate unauthorized error
func QuickUnauthorized(w http.ResponseWriter) error {
	return SendUnifiedError(w, http.StatusUnauthorized, UnifiedErrorCodes.Unauthorized, "Authentication required", nil)
}