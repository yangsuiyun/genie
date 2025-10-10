package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/services"
)

// AuthHandler handles authentication-related HTTP requests
type AuthHandler struct {
	authService *services.AuthService
	validator   *validator.Validate
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		validator:   validator.New(),
	}
}

// RegisterRoutes registers authentication routes
func (h *AuthHandler) RegisterRoutes(router *gin.RouterGroup) {
	auth := router.Group("/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
		auth.POST("/refresh", h.RefreshToken)
		auth.POST("/logout", h.Logout)
		auth.POST("/change-password", h.RequireAuth(), h.ChangePassword)
		auth.POST("/forgot-password", h.ForgotPassword)
		auth.POST("/reset-password", h.ResetPassword)
		auth.POST("/verify-email", h.VerifyEmail)
	}
}

// Register handles user registration
// @Summary Register a new user
// @Description Create a new user account with email and password
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body services.RegisterRequest true "Registration request"
// @Success 201 {object} services.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req services.RegisterRequest

	// Bind JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Validate request
	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	// Register user
	response, err := h.authService.Register(req)
	if err != nil {
		if models.IsValidationError(err) || err == models.ErrEmailAlreadyExists {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "registration_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to register user",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, response)
}

// Login handles user authentication
// @Summary Authenticate user
// @Description Authenticate user with email and password
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body services.AuthRequest true "Login request"
// @Success 200 {object} services.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req services.AuthRequest

	// Bind JSON request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Validate request
	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	// Authenticate user
	response, err := h.authService.Login(req)
	if err != nil {
		if models.IsAuthenticationError(err) {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error:   "authentication_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to authenticate user",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// RefreshToken handles token refresh
// @Summary Refresh access token
// @Description Refresh access token using refresh token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body RefreshTokenRequest true "Refresh token request"
// @Success 200 {object} services.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	response, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		if models.IsAuthenticationError(err) {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error:   "invalid_token",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to refresh token",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// Logout handles user logout
// @Summary Logout user
// @Description Logout user and invalidate tokens
// @Tags Authentication
// @Security BearerAuth
// @Produce json
// @Success 200 {object} SuccessResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	userID := h.GetUserIDFromContext(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	err := h.authService.Logout(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to logout",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Successfully logged out",
	})
}

// ChangePassword handles password change
// @Summary Change user password
// @Description Change user password with current password verification
// @Tags Authentication
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body ChangePasswordRequest true "Change password request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/change-password [post]
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	var req ChangePasswordRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	userID := h.GetUserIDFromContext(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error:   "unauthorized",
			Message: "User not authenticated",
		})
		return
	}

	err := h.authService.ChangePassword(userID, req.CurrentPassword, req.NewPassword)
	if err != nil {
		if models.IsAuthenticationError(err) || models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "password_change_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to change password",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Password changed successfully",
	})
}

// ForgotPassword handles password reset requests
// @Summary Request password reset
// @Description Send password reset email to user
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body ForgotPasswordRequest true "Forgot password request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req ForgotPasswordRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	err := h.authService.RequestPasswordReset(req.Email)
	if err != nil {
		// Don't reveal if email exists - always return success
		// Log error for debugging but don't expose to client
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "If an account exists with this email, a password reset link has been sent",
	})
}

// ResetPassword handles password reset with token
// @Summary Reset password with token
// @Description Reset password using reset token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body ResetPasswordRequest true "Reset password request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/reset-password [post]
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	err := h.authService.ResetPassword(req.Token, req.NewPassword)
	if err != nil {
		if models.IsAuthenticationError(err) || models.IsValidationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "password_reset_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to reset password",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Password reset successfully",
	})
}

// VerifyEmail handles email verification
// @Summary Verify email address
// @Description Verify user email address with verification token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body VerifyEmailRequest true "Email verification request"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /auth/verify-email [post]
func (h *AuthHandler) VerifyEmail(c *gin.Context) {
	var req VerifyEmailRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "invalid_request",
			Message: "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	if err := h.validator.Struct(req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "validation_failed",
			Message: "Request validation failed",
			Details: err.Error(),
		})
		return
	}

	err := h.authService.VerifyEmail(req.Token)
	if err != nil {
		if models.IsAuthenticationError(err) {
			c.JSON(http.StatusBadRequest, ErrorResponse{
				Error:   "verification_failed",
				Message: err.Error(),
			})
			return
		}

		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "internal_error",
			Message: "Failed to verify email",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Email verified successfully",
	})
}

// RequireAuth middleware for protected routes
func (h *AuthHandler) RequireAuth() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// Get authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error:   "unauthorized",
				Message: "Authorization header required",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>" format
		if len(authHeader) < 7 || authHeader[:7] != "Bearer " {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error:   "unauthorized",
				Message: "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		token := authHeader[7:]

		// Validate token
		user, err := h.authService.ValidateToken(token)
		if err != nil {
			if models.IsAuthenticationError(err) {
				c.JSON(http.StatusUnauthorized, ErrorResponse{
					Error:   "unauthorized",
					Message: err.Error(),
				})
			} else {
				c.JSON(http.StatusInternalServerError, ErrorResponse{
					Error:   "internal_error",
					Message: "Failed to validate token",
				})
			}
			c.Abort()
			return
		}

		// Set user in context
		c.Set("user", user)
		c.Set("user_id", user.ID.String())

		c.Next()
	})
}

// GetUserFromContext extracts user from Gin context
func (h *AuthHandler) GetUserFromContext(c *gin.Context) *models.User {
	user, exists := c.Get("user")
	if !exists {
		return nil
	}
	return user.(*models.User)
}

// GetUserIDFromContext extracts user ID from Gin context
func (h *AuthHandler) GetUserIDFromContext(c *gin.Context) string {
	userID, exists := c.Get("user_id")
	if !exists {
		return ""
	}
	return userID.(string)
}

// Request/Response types

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required,min=8"`
	NewPassword     string `json:"new_password" validate:"required,min=8"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}

type VerifyEmailRequest struct {
	Token string `json:"token" validate:"required"`
}

// Common response types

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

type SuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}
