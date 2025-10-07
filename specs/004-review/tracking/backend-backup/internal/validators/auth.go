package validators

import (
	"regexp"
	"strings"

	"github.com/go-playground/validator/v10"
)

// AuthValidators contains validation rules for authentication
type AuthValidators struct {
	validate *validator.Validate
}

// NewAuthValidators creates a new instance of auth validators
func NewAuthValidators() *AuthValidators {
	validate := validator.New()

	// Register custom validators
	validate.RegisterValidation("strong_password", validateStrongPassword)
	validate.RegisterValidation("valid_email", validateEmail)

	return &AuthValidators{
		validate: validate,
	}
}

// LoginRequest validation struct
type LoginRequest struct {
	Email      string `json:"email" validate:"required,valid_email"`
	Password   string `json:"password" validate:"required,min=8"`
	RememberMe bool   `json:"remember_me"`
}

// RegisterRequest validation struct
type RegisterRequest struct {
	Email               string `json:"email" validate:"required,valid_email"`
	Password            string `json:"password" validate:"required,strong_password"`
	Name                string `json:"name" validate:"required,min=1,max=100"`
	AcceptTerms         bool   `json:"accept_terms" validate:"required,eq=true"`
	SubscribeNewsletter bool   `json:"subscribe_newsletter"`
}

// RefreshTokenRequest validation struct
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required,min=20"`
}

// ChangePasswordRequest validation struct
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required,min=8"`
	NewPassword     string `json:"new_password" validate:"required,strong_password"`
}

// ResetPasswordRequest validation struct
type ResetPasswordRequest struct {
	Email string `json:"email" validate:"required,valid_email"`
}

// ConfirmResetPasswordRequest validation struct
type ConfirmResetPasswordRequest struct {
	Token           string `json:"token" validate:"required,min=20"`
	NewPassword     string `json:"new_password" validate:"required,strong_password"`
	ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=NewPassword"`
}

// ValidateLogin validates login request
func (av *AuthValidators) ValidateLogin(req *LoginRequest) error {
	return av.validate.Struct(req)
}

// ValidateRegister validates registration request
func (av *AuthValidators) ValidateRegister(req *RegisterRequest) error {
	return av.validate.Struct(req)
}

// ValidateRefreshToken validates refresh token request
func (av *AuthValidators) ValidateRefreshToken(req *RefreshTokenRequest) error {
	return av.validate.Struct(req)
}

// ValidateChangePassword validates change password request
func (av *AuthValidators) ValidateChangePassword(req *ChangePasswordRequest) error {
	return av.validate.Struct(req)
}

// ValidateResetPassword validates reset password request
func (av *AuthValidators) ValidateResetPassword(req *ResetPasswordRequest) error {
	return av.validate.Struct(req)
}

// ValidateConfirmResetPassword validates confirm reset password request
func (av *AuthValidators) ValidateConfirmResetPassword(req *ConfirmResetPasswordRequest) error {
	return av.validate.Struct(req)
}

// Custom validation functions

// validateStrongPassword validates password strength
func validateStrongPassword(fl validator.FieldLevel) bool {
	password := fl.Field().String()

	// Minimum 8 characters
	if len(password) < 8 {
		return false
	}

	// Maximum 128 characters
	if len(password) > 128 {
		return false
	}

	// Must contain at least one lowercase letter
	hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
	if !hasLower {
		return false
	}

	// Must contain at least one uppercase letter
	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
	if !hasUpper {
		return false
	}

	// Must contain at least one digit
	hasDigit := regexp.MustCompile(`\d`).MatchString(password)
	if !hasDigit {
		return false
	}

	// Must contain at least one special character
	hasSpecial := regexp.MustCompile(`[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]`).MatchString(password)
	if !hasSpecial {
		return false
	}

	// Must not contain common patterns
	commonPatterns := []string{
		"123456", "password", "qwerty", "abc123", "12345678",
		"123456789", "password123", "admin", "letmein", "welcome",
	}

	lowerPassword := strings.ToLower(password)
	for _, pattern := range commonPatterns {
		if strings.Contains(lowerPassword, pattern) {
			return false
		}
	}

	return true
}

// validateEmail validates email format and domain
func validateEmail(fl validator.FieldLevel) bool {
	email := fl.Field().String()

	// Basic email format validation
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return false
	}

	// Check email length
	if len(email) > 254 {
		return false
	}

	// Check local part length (before @)
	parts := strings.Split(email, "@")
	if len(parts[0]) > 64 {
		return false
	}

	// Validate domain part
	domain := parts[1]
	if len(domain) > 253 {
		return false
	}

	// Domain should not start or end with hyphen
	if strings.HasPrefix(domain, "-") || strings.HasSuffix(domain, "-") {
		return false
	}

	// Blocked domains (disposable email providers)
	blockedDomains := []string{
		"10minutemail.com", "guerrillamail.com", "mailinator.com",
		"tempmail.org", "trash-mail.com", "yopmail.com",
		"temp-mail.org", "mohmal.com", "sharklasers.com",
	}

	lowerDomain := strings.ToLower(domain)
	for _, blocked := range blockedDomains {
		if lowerDomain == blocked || strings.HasSuffix(lowerDomain, "."+blocked) {
			return false
		}
	}

	return true
}

// GetValidationErrors returns formatted validation errors
func (av *AuthValidators) GetValidationErrors(err error) map[string]string {
	errors := make(map[string]string)

	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrors {
			fieldName := strings.ToLower(fieldError.Field())

			switch fieldError.Tag() {
			case "required":
				errors[fieldName] = fieldName + " is required"
			case "min":
				errors[fieldName] = fieldName + " must be at least " + fieldError.Param() + " characters"
			case "max":
				errors[fieldName] = fieldName + " must be at most " + fieldError.Param() + " characters"
			case "valid_email":
				errors[fieldName] = "Please enter a valid email address"
			case "strong_password":
				errors[fieldName] = "Password must contain at least 8 characters, including uppercase, lowercase, numbers, and special characters"
			case "eq":
				errors[fieldName] = fieldName + " must be " + fieldError.Param()
			case "eqfield":
				errors[fieldName] = fieldName + " must match " + fieldError.Param()
			default:
				errors[fieldName] = fieldName + " is invalid"
			}
		}
	}

	return errors
}

// ValidatePasswordComplexity checks password complexity requirements
func (av *AuthValidators) ValidatePasswordComplexity(password string) []string {
	var issues []string

	if len(password) < 8 {
		issues = append(issues, "Password must be at least 8 characters long")
	}

	if len(password) > 128 {
		issues = append(issues, "Password must be at most 128 characters long")
	}

	if !regexp.MustCompile(`[a-z]`).MatchString(password) {
		issues = append(issues, "Password must contain at least one lowercase letter")
	}

	if !regexp.MustCompile(`[A-Z]`).MatchString(password) {
		issues = append(issues, "Password must contain at least one uppercase letter")
	}

	if !regexp.MustCompile(`\d`).MatchString(password) {
		issues = append(issues, "Password must contain at least one number")
	}

	if !regexp.MustCompile(`[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]`).MatchString(password) {
		issues = append(issues, "Password must contain at least one special character")
	}

	// Check for common patterns
	commonPatterns := []string{
		"123456", "password", "qwerty", "abc123", "12345678",
		"123456789", "password123", "admin", "letmein", "welcome",
	}

	lowerPassword := strings.ToLower(password)
	for _, pattern := range commonPatterns {
		if strings.Contains(lowerPassword, pattern) {
			issues = append(issues, "Password contains common patterns and is too weak")
			break
		}
	}

	return issues
}

// ValidateEmailDomain checks if email domain is acceptable
func (av *AuthValidators) ValidateEmailDomain(email string) bool {
	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return false
	}

	domain := strings.ToLower(parts[1])

	// List of blocked domains
	blockedDomains := []string{
		"10minutemail.com", "guerrillamail.com", "mailinator.com",
		"tempmail.org", "trash-mail.com", "yopmail.com",
		"temp-mail.org", "mohmal.com", "sharklasers.com",
		"throwaway.email", "getnada.com", "maildrop.cc",
	}

	for _, blocked := range blockedDomains {
		if domain == blocked || strings.HasSuffix(domain, "."+blocked) {
			return false
		}
	}

	return true
}

// SanitizeInput sanitizes user input to prevent XSS and injection attacks
func (av *AuthValidators) SanitizeInput(input string) string {
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

// IsValidUserAgent checks if the user agent is valid
func (av *AuthValidators) IsValidUserAgent(userAgent string) bool {
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