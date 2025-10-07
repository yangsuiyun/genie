package utils

import (
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ValidationError represents a validation error with field and message
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

func (e ValidationError) Error() string {
	return fmt.Sprintf("%s: %s", e.Field, e.Message)
}

// ValidationErrors represents multiple validation errors
type ValidationErrors []ValidationError

func (e ValidationErrors) Error() string {
	if len(e) == 0 {
		return "validation failed"
	}

	messages := make([]string, len(e))
	for i, err := range e {
		messages[i] = err.Error()
	}
	return strings.Join(messages, "; ")
}

// Validator provides common validation functions
type Validator struct {
	errors ValidationErrors
}

// NewValidator creates a new validator instance
func NewValidator() *Validator {
	return &Validator{
		errors: make(ValidationErrors, 0),
	}
}

// AddError adds a validation error
func (v *Validator) AddError(field, message string) {
	v.errors = append(v.errors, ValidationError{
		Field:   field,
		Message: message,
	})
}

// AddErrorf adds a formatted validation error
func (v *Validator) AddErrorf(field, format string, args ...interface{}) {
	v.AddError(field, fmt.Sprintf(format, args...))
}

// HasErrors returns true if there are validation errors
func (v *Validator) HasErrors() bool {
	return len(v.errors) > 0
}

// Errors returns all validation errors
func (v *Validator) Errors() ValidationErrors {
	return v.errors
}

// Error implements the error interface
func (v *Validator) Error() error {
	if len(v.errors) == 0 {
		return nil
	}
	return v.errors
}

// Common validation functions

// ValidateRequired validates that a string field is not empty
func (v *Validator) ValidateRequired(field, value string) {
	if strings.TrimSpace(value) == "" {
		v.AddError(field, "is required")
	}
}

// ValidateMinLength validates minimum string length
func (v *Validator) ValidateMinLength(field, value string, minLength int) {
	if len(value) < minLength {
		v.AddErrorf(field, "must be at least %d characters", minLength)
	}
}

// ValidateMaxLength validates maximum string length
func (v *Validator) ValidateMaxLength(field, value string, maxLength int) {
	if len(value) > maxLength {
		v.AddErrorf(field, "must be at most %d characters", maxLength)
	}
}

// ValidateLength validates string length range
func (v *Validator) ValidateLength(field, value string, minLength, maxLength int) {
	v.ValidateMinLength(field, value, minLength)
	v.ValidateMaxLength(field, value, maxLength)
}

// ValidateEmail validates email format
func (v *Validator) ValidateEmail(field, email string) {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		v.AddError(field, "must be a valid email address")
	}
}

// ValidateUUID validates UUID format
func (v *Validator) ValidateUUID(field, id string) {
	if _, err := uuid.Parse(id); err != nil {
		v.AddError(field, "must be a valid UUID")
	}
}

// ValidatePositiveInt validates that an integer is positive
func (v *Validator) ValidatePositiveInt(field string, value int) {
	if value <= 0 {
		v.AddError(field, "must be positive")
	}
}

// ValidateRange validates that an integer is within a range
func (v *Validator) ValidateRange(field string, value, min, max int) {
	if value < min || value > max {
		v.AddErrorf(field, "must be between %d and %d", min, max)
	}
}

// ValidateIn validates that a string is in a list of allowed values
func (v *Validator) ValidateIn(field, value string, allowed []string) {
	for _, allowedValue := range allowed {
		if value == allowedValue {
			return
		}
	}
	v.AddErrorf(field, "must be one of: %s", strings.Join(allowed, ", "))
}

// ValidateURL validates URL format
func (v *Validator) ValidateURL(field, url string) {
	urlRegex := regexp.MustCompile(`^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$`)
	if !urlRegex.MatchString(url) {
		v.AddError(field, "must be a valid URL")
	}
}

// ValidateDate validates that a time is not zero and optionally in the future
func (v *Validator) ValidateDate(field string, date time.Time, mustBeFuture bool) {
	if date.IsZero() {
		v.AddError(field, "is required")
		return
	}

	if mustBeFuture && date.Before(time.Now()) {
		v.AddError(field, "must be in the future")
	}
}

// ValidatePassword validates password strength
func (v *Validator) ValidatePassword(field, password string) {
	if len(password) < 8 {
		v.AddError(field, "must be at least 8 characters")
		return
	}

	if len(password) > 128 {
		v.AddError(field, "must be at most 128 characters")
		return
	}

	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
	hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
	hasDigit := regexp.MustCompile(`\d`).MatchString(password)
	hasSpecial := regexp.MustCompile(`[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~` + "`" + `]`).MatchString(password)

	if !hasUpper {
		v.AddError(field, "must contain at least one uppercase letter")
	}
	if !hasLower {
		v.AddError(field, "must contain at least one lowercase letter")
	}
	if !hasDigit {
		v.AddError(field, "must contain at least one digit")
	}
	if !hasSpecial {
		v.AddError(field, "must contain at least one special character")
	}
}

// ValidateArrayNotEmpty validates that an array is not empty
func (v *Validator) ValidateArrayNotEmpty(field string, arr interface{}) {
	switch a := arr.(type) {
	case []string:
		if len(a) == 0 {
			v.AddError(field, "cannot be empty")
		}
	case []int:
		if len(a) == 0 {
			v.AddError(field, "cannot be empty")
		}
	default:
		v.AddError(field, "invalid array type")
	}
}

// ValidateArrayMaxLength validates maximum array length
func (v *Validator) ValidateArrayMaxLength(field string, arr []string, maxLength int) {
	if len(arr) > maxLength {
		v.AddErrorf(field, "cannot have more than %d items", maxLength)
	}
}

// ValidateConditional validates a field only if a condition is true
func (v *Validator) ValidateConditional(condition bool, validationFunc func()) {
	if condition {
		validationFunc()
	}
}

// Utility functions for common validations

// IsValidEmail checks if an email is valid
func IsValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// IsValidUUID checks if a string is a valid UUID
func IsValidUUID(id string) bool {
	_, err := uuid.Parse(id)
	return err == nil
}

// IsValidPassword checks if a password meets strength requirements
func IsValidPassword(password string) bool {
	if len(password) < 8 || len(password) > 128 {
		return false
	}

	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
	hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
	hasDigit := regexp.MustCompile(`\d`).MatchString(password)
	hasSpecial := regexp.MustCompile(`[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~` + "`" + `]`).MatchString(password)

	return hasUpper && hasLower && hasDigit && hasSpecial
}

// SanitizeString removes potentially harmful characters from a string
func SanitizeString(input string) string {
	// Remove null bytes and control characters
	sanitized := regexp.MustCompile(`[\x00-\x1f\x7f]`).ReplaceAllString(input, "")
	// Trim whitespace
	return strings.TrimSpace(sanitized)
}

// ValidateAndSanitizeString validates and sanitizes a string field
func (v *Validator) ValidateAndSanitizeString(field string, value *string, required bool, minLen, maxLen int) {
	if value == nil {
		if required {
			v.AddError(field, "is required")
		}
		return
	}

	*value = SanitizeString(*value)

	if required {
		v.ValidateRequired(field, *value)
	}

	if *value != "" {
		v.ValidateLength(field, *value, minLen, maxLen)
	}
}