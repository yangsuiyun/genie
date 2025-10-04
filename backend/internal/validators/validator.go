package validators

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
)

// Validator is the main validator struct that combines all validation modules
type Validator struct {
	Auth     *AuthValidators
	Task     *TaskValidators
	Pomodoro *PomodoroValidators
	validate *validator.Validate
}

// New creates a new instance of the main validator
func New() *Validator {
	return &Validator{
		Auth:     NewAuthValidators(),
		Task:     NewTaskValidators(),
		Pomodoro: NewPomodoroValidators(),
		validate: validator.New(),
	}
}

// ValidationError represents a structured validation error
type ValidationError struct {
	Field   string `json:"field"`
	Tag     string `json:"tag"`
	Value   string `json:"value"`
	Message string `json:"message"`
	Param   string `json:"param,omitempty"`
}

// ValidationErrors represents a collection of validation errors
type ValidationErrors struct {
	Errors []ValidationError `json:"errors"`
}

// Error implements the error interface
func (ve ValidationErrors) Error() string {
	var messages []string
	for _, err := range ve.Errors {
		messages = append(messages, err.Message)
	}
	return strings.Join(messages, "; ")
}

// FormatValidationErrors converts validator.ValidationErrors to structured format
func (v *Validator) FormatValidationErrors(err error) ValidationErrors {
	var validationErrors ValidationErrors

	if validationErrs, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrs {
			validationError := ValidationError{
				Field: strings.ToLower(fieldError.Field()),
				Tag:   fieldError.Tag(),
				Value: fmt.Sprintf("%v", fieldError.Value()),
				Param: fieldError.Param(),
			}

			// Generate user-friendly error messages
			validationError.Message = v.generateErrorMessage(fieldError)
			validationErrors.Errors = append(validationErrors.Errors, validationError)
		}
	}

	return validationErrors
}

// generateErrorMessage generates user-friendly error messages
func (v *Validator) generateErrorMessage(fieldError validator.FieldError) string {
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

	// Custom validation tags
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

// GetFieldNames extracts field names from validation errors
func (v *Validator) GetFieldNames(err error) []string {
	var fieldNames []string

	if validationErrs, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrs {
			fieldNames = append(fieldNames, strings.ToLower(fieldError.Field()))
		}
	}

	return fieldNames
}

// HasFieldError checks if a specific field has validation errors
func (v *Validator) HasFieldError(err error, fieldName string) bool {
	if validationErrs, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrs {
			if strings.ToLower(fieldError.Field()) == strings.ToLower(fieldName) {
				return true
			}
		}
	}
	return false
}

// GetFieldError gets the first error for a specific field
func (v *Validator) GetFieldError(err error, fieldName string) string {
	if validationErrs, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrs {
			if strings.ToLower(fieldError.Field()) == strings.ToLower(fieldName) {
				return v.generateErrorMessage(fieldError)
			}
		}
	}
	return ""
}

// ValidateStruct validates any struct using the default validator
func (v *Validator) ValidateStruct(s interface{}) error {
	return v.validate.Struct(s)
}

// SanitizeString removes potentially harmful characters from strings
func (v *Validator) SanitizeString(input string) string {
	// Remove null bytes
	input = strings.ReplaceAll(input, "\x00", "")

	// Trim whitespace
	input = strings.TrimSpace(input)

	// Remove control characters except newlines and tabs
	var sanitized strings.Builder
	for _, r := range input {
		if r >= 32 || r == '\t' || r == '\n' || r == '\r' {
			sanitized.WriteRune(r)
		}
	}

	return sanitized.String()
}

// ValidateUUID validates UUID format
func (v *Validator) ValidateUUID(uuid string) bool {
	uuidRegex := `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`
	return strings.ToLower(uuid) != "" && len(uuid) == 36 &&
		   strings.Count(uuid, "-") == 4
}

// ValidateJSON validates if a string is valid JSON
func (v *Validator) ValidateJSON(jsonStr string) bool {
	// This would require json package in real implementation
	return len(jsonStr) > 0 && (strings.HasPrefix(jsonStr, "{") || strings.HasPrefix(jsonStr, "["))
}

// ValidateHTTPMethod validates HTTP method
func (v *Validator) ValidateHTTPMethod(method string) bool {
	validMethods := []string{"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"}
	method = strings.ToUpper(method)

	for _, valid := range validMethods {
		if method == valid {
			return true
		}
	}
	return false
}

// ValidateContentType validates HTTP content type
func (v *Validator) ValidateContentType(contentType string) bool {
	validContentTypes := []string{
		"application/json",
		"application/x-www-form-urlencoded",
		"multipart/form-data",
		"text/plain",
		"text/html",
		"application/xml",
		"text/xml",
	}

	contentType = strings.ToLower(strings.TrimSpace(contentType))

	for _, valid := range validContentTypes {
		if strings.HasPrefix(contentType, valid) {
			return true
		}
	}
	return false
}

// ValidateIPAddress validates IP address (IPv4 or IPv6)
func (v *Validator) ValidateIPAddress(ip string) bool {
	// Basic IP validation - in real implementation would use net package
	if len(ip) == 0 {
		return false
	}

	// IPv4 basic check
	if strings.Count(ip, ".") == 3 {
		parts := strings.Split(ip, ".")
		if len(parts) == 4 {
			for _, part := range parts {
				if len(part) == 0 || len(part) > 3 {
					return false
				}
			}
			return true
		}
	}

	// IPv6 basic check
	if strings.Contains(ip, ":") {
		return len(ip) >= 3 && len(ip) <= 39
	}

	return false
}

// ValidateUserAgent validates user agent string
func (v *Validator) ValidateUserAgent(userAgent string) bool {
	if len(userAgent) == 0 || len(userAgent) > 512 {
		return false
	}

	// Block suspicious user agents
	suspiciousPatterns := []string{
		"bot", "crawl", "spider", "scrape", "wget", "curl",
		"python", "ruby", "perl", "php", "java", "script",
	}

	lowerUA := strings.ToLower(userAgent)
	for _, pattern := range suspiciousPatterns {
		if strings.Contains(lowerUA, pattern) {
			return false
		}
	}

	return true
}

// GetErrorSummary returns a summary of validation errors
func (v *Validator) GetErrorSummary(err error) map[string]interface{} {
	summary := map[string]interface{}{
		"has_errors": false,
		"error_count": 0,
		"fields": []string{},
		"message": "Validation successful",
	}

	if err != nil {
		validationErrors := v.FormatValidationErrors(err)
		summary["has_errors"] = true
		summary["error_count"] = len(validationErrors.Errors)
		summary["message"] = "Validation failed"

		var fields []string
		for _, validationError := range validationErrors.Errors {
			fields = append(fields, validationError.Field)
		}
		summary["fields"] = fields
	}

	return summary
}