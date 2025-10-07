package utils

import (
	"encoding/json"
	"net/http"
)

// StandardResponse represents the standard API response format
type StandardResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo  `json:"error,omitempty"`
	Meta    *MetaInfo   `json:"meta,omitempty"`
}

// ErrorInfo contains error details
type ErrorInfo struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// MetaInfo contains metadata like pagination
type MetaInfo struct {
	Page       int `json:"page,omitempty"`
	Limit      int `json:"limit,omitempty"`
	Total      int `json:"total,omitempty"`
	TotalPages int `json:"total_pages,omitempty"`
}

// PaginationInfo represents pagination metadata
type PaginationInfo struct {
	Page       int  `json:"page"`
	Limit      int  `json:"limit"`
	Total      int  `json:"total"`
	TotalPages int  `json:"total_pages"`
	HasNext    bool `json:"has_next"`
	HasPrev    bool `json:"has_prev"`
}

// ResponseBuilder helps build standardized responses
type ResponseBuilder struct {
	response StandardResponse
	status   int
}

// NewResponse creates a new response builder
func NewResponse() *ResponseBuilder {
	return &ResponseBuilder{
		response: StandardResponse{Success: true},
		status:   http.StatusOK,
	}
}

// Success sets the response as successful with data
func (rb *ResponseBuilder) Success(data interface{}) *ResponseBuilder {
	rb.response.Success = true
	rb.response.Data = data
	rb.response.Error = nil
	return rb
}

// Error sets the response as error with details
func (rb *ResponseBuilder) Error(code, message string, details interface{}) *ResponseBuilder {
	rb.response.Success = false
	rb.response.Data = nil
	rb.response.Error = &ErrorInfo{
		Code:    code,
		Message: message,
		Details: details,
	}
	return rb
}

// Status sets the HTTP status code
func (rb *ResponseBuilder) Status(status int) *ResponseBuilder {
	rb.status = status
	return rb
}

// WithMeta adds metadata to the response
func (rb *ResponseBuilder) WithMeta(meta MetaInfo) *ResponseBuilder {
	rb.response.Meta = &meta
	return rb
}

// WithPagination adds pagination metadata
func (rb *ResponseBuilder) WithPagination(pagination PaginationInfo) *ResponseBuilder {
	rb.response.Meta = &MetaInfo{
		Page:       pagination.Page,
		Limit:      pagination.Limit,
		Total:      pagination.Total,
		TotalPages: pagination.TotalPages,
	}
	return rb
}

// Send writes the response to the HTTP response writer
func (rb *ResponseBuilder) Send(w http.ResponseWriter) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(rb.status)
	return json.NewEncoder(w).Encode(rb.response)
}

// JSON returns the response as JSON bytes
func (rb *ResponseBuilder) JSON() ([]byte, error) {
	return json.Marshal(rb.response)
}

// Convenience functions for common responses

// SendSuccess sends a successful response with data
func SendSuccess(w http.ResponseWriter, data interface{}) error {
	return NewResponse().Success(data).Send(w)
}

// SendCreated sends a 201 Created response with data
func SendCreated(w http.ResponseWriter, data interface{}) error {
	return NewResponse().Success(data).Status(http.StatusCreated).Send(w)
}

// SendNoContent sends a 204 No Content response
func SendNoContent(w http.ResponseWriter) error {
	return NewResponse().Status(http.StatusNoContent).Send(w)
}

// SendError sends an error response
func SendError(w http.ResponseWriter, status int, code, message string, details interface{}) error {
	return NewResponse().Error(code, message, details).Status(status).Send(w)
}

// SendValidationError sends a 400 Bad Request with validation errors
func SendValidationError(w http.ResponseWriter, errors ValidationErrors) error {
	return SendError(w, http.StatusBadRequest, "VALIDATION_ERROR", "Invalid input data", errors)
}

// SendNotFound sends a 404 Not Found response
func SendNotFound(w http.ResponseWriter, resource string) error {
	return SendError(w, http.StatusNotFound, "NOT_FOUND", resource+" not found", nil)
}

// SendUnauthorized sends a 401 Unauthorized response
func SendUnauthorized(w http.ResponseWriter, message string) error {
	if message == "" {
		message = "Authentication required"
	}
	return SendError(w, http.StatusUnauthorized, "UNAUTHORIZED", message, nil)
}

// SendForbidden sends a 403 Forbidden response
func SendForbidden(w http.ResponseWriter, message string) error {
	if message == "" {
		message = "Access denied"
	}
	return SendError(w, http.StatusForbidden, "FORBIDDEN", message, nil)
}

// SendConflict sends a 409 Conflict response
func SendConflict(w http.ResponseWriter, message string) error {
	return SendError(w, http.StatusConflict, "CONFLICT", message, nil)
}

// SendInternalError sends a 500 Internal Server Error response
func SendInternalError(w http.ResponseWriter, message string) error {
	if message == "" {
		message = "Internal server error"
	}
	return SendError(w, http.StatusInternalServerError, "INTERNAL_ERROR", message, nil)
}

// SendTooManyRequests sends a 429 Too Many Requests response
func SendTooManyRequests(w http.ResponseWriter, message string) error {
	if message == "" {
		message = "Rate limit exceeded"
	}
	return SendError(w, http.StatusTooManyRequests, "RATE_LIMIT_EXCEEDED", message, nil)
}

// CalculatePagination calculates pagination info
func CalculatePagination(page, limit, total int) PaginationInfo {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20 // default limit
	}

	totalPages := (total + limit - 1) / limit // ceiling division
	if totalPages < 1 {
		totalPages = 1
	}

	return PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
		HasNext:    page < totalPages,
		HasPrev:    page > 1,
	}
}

// SendPaginatedResponse sends a paginated response
func SendPaginatedResponse(w http.ResponseWriter, data interface{}, page, limit, total int) error {
	pagination := CalculatePagination(page, limit, total)
	return NewResponse().Success(data).WithPagination(pagination).Send(w)
}

// ErrorCodes contains common error codes
var ErrorCodes = struct {
	ValidationError      string
	NotFound            string
	Unauthorized        string
	Forbidden           string
	Conflict            string
	InternalError       string
	RateLimitExceeded   string
	BadRequest          string
	ServiceUnavailable  string
}{
	ValidationError:     "VALIDATION_ERROR",
	NotFound:           "NOT_FOUND",
	Unauthorized:       "UNAUTHORIZED",
	Forbidden:          "FORBIDDEN",
	Conflict:           "CONFLICT",
	InternalError:      "INTERNAL_ERROR",
	RateLimitExceeded:  "RATE_LIMIT_EXCEEDED",
	BadRequest:         "BAD_REQUEST",
	ServiceUnavailable: "SERVICE_UNAVAILABLE",
}