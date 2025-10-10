package services

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"pomodoro-backend/internal/models"
)

// AuthService handles authentication and authorization
type AuthService struct {
	userService *UserService
	jwtSecret   []byte
	tokenTTL    time.Duration
}

// AuthRequest represents a login request
type AuthRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}

// RegisterRequest represents a registration request
type RegisterRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
	Name     string `json:"name,omitempty"`
}

// AuthResponse represents the authentication response
type AuthResponse struct {
	User        interface{} `json:"user"`
	AccessToken string      `json:"access_token"`
	ExpiresIn   int64       `json:"expires_in"`
	TokenType   string      `json:"token_type"`
}

// TokenClaims represents JWT token claims
type TokenClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// RefreshTokenData represents refresh token information
type RefreshTokenData struct {
	Token     string    `json:"token"`
	UserID    string    `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

// NewAuthService creates a new authentication service
func NewAuthService(userService *UserService, jwtSecret string) *AuthService {
	return &AuthService{
		userService: userService,
		jwtSecret:   []byte(jwtSecret),
		tokenTTL:    24 * time.Hour, // 24 hours default
	}
}

// Register creates a new user account
func (s *AuthService) Register(req RegisterRequest) (*AuthResponse, error) {
	// Validate password strength
	if !s.isPasswordValid(req.Password) {
		return nil, models.ErrPasswordRequired // Use a more specific error
	}

	// Check if user already exists
	existingUser, err := s.userService.GetByEmail(req.Email)
	if err != nil && !models.IsNotFoundError(err) {
		return nil, fmt.Errorf("failed to check existing user: %w", err)
	}
	if existingUser != nil {
		return nil, models.ErrEmailAlreadyExists
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &models.User{
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		Preferences:  models.DefaultUserPreferences(),
	}

	if req.Name != "" {
		// Set name if provided (assuming User model has a Name field)
		// user.Name = req.Name
	}

	createdUser, err := s.userService.Create(user)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate access token
	accessToken, err := s.generateAccessToken(createdUser)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Send verification email (TODO: implement email service)
	// err = s.emailService.SendVerificationEmail(createdUser.Email, verificationToken)

	return &AuthResponse{
		User: gin.H{
			"id":    createdUser.ID,
			"email": createdUser.Email,
			"name":  createdUser.Name,
		},
		AccessToken: accessToken,
		ExpiresIn:   int64(s.tokenTTL.Seconds()),
		TokenType:   "Bearer",
	}, nil
}

// Login authenticates a user and returns access token
func (s *AuthService) Login(req AuthRequest) (*AuthResponse, error) {
	// Get user by email
	user, err := s.userService.GetByEmail(req.Email)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrInvalidCredentials
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Check if user is active
	if !user.IsActive {
		return nil, models.ErrUserInactive
	}

	// Verify password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
	if err != nil {
		return nil, models.ErrInvalidCredentials
	}

	// Update last login time
	userUUID, err := uuid.Parse(user.ID)
	if err != nil {
		fmt.Printf("Warning: invalid user ID format: %v\n", err)
	} else {
		err = s.userService.UpdateLastLogin(userUUID)
		if err != nil {
			// Log error but don't fail the login
			fmt.Printf("Warning: failed to update last login time: %v\n", err)
		}
	}

	// Generate access token
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	return &AuthResponse{
		User: gin.H{
			"id":    user.ID,
			"email": user.Email,
			"name":  user.Name,
		},
		AccessToken: accessToken,
		ExpiresIn:   int64(s.tokenTTL.Seconds()),
		TokenType:   "Bearer",
	}, nil
}

// ValidateToken validates a JWT token and returns the user
func (s *AuthService) ValidateToken(tokenString string) (*models.User, error) {
	// Parse token
	token, err := jwt.ParseWithClaims(tokenString, &TokenClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		return nil, models.ErrInvalidToken
	}

	// Extract claims
	claims, ok := token.Claims.(*TokenClaims)
	if !ok || !token.Valid {
		return nil, models.ErrInvalidToken
	}

	// Check if token is expired
	if claims.ExpiresAt.Time.Before(time.Now()) {
		return nil, models.ErrTokenExpired
	}

	// Get user
	user, err := s.userService.GetByID(claims.UserID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user from token: %w", err)
	}

	return user, nil
}

// RefreshToken generates a new access token using a refresh token
func (s *AuthService) RefreshToken(refreshToken string) (*AuthResponse, error) {
	// TODO: Implement refresh token validation
	// For now, return error as refresh tokens are not implemented
	return nil, fmt.Errorf("refresh tokens not yet implemented")
}

// ChangePassword changes a user's password
func (s *AuthService) ChangePassword(userID, currentPassword, newPassword string) error {
	// Get user
	user, err := s.userService.GetByID(userID)
	if err != nil {
		return fmt.Errorf("failed to get user: %w", err)
	}

	// Verify current password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword))
	if err != nil {
		return models.ErrInvalidCredentials
	}

	// Validate new password
	if !s.isPasswordValid(newPassword) {
		return models.ErrPasswordRequired // Use a more specific error
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash new password: %w", err)
	}

	// Update password
	user.PasswordHash = string(hashedPassword)
	_, err = s.userService.Update(user)
	if err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}

	return nil
}

// RequestPasswordReset initiates a password reset process
func (s *AuthService) RequestPasswordReset(email string) error {
	// Get user by email
	user, err := s.userService.GetByEmail(email)
	if err != nil {
		if models.IsNotFoundError(err) {
			// Don't reveal if email exists or not
			return nil
		}
		return fmt.Errorf("failed to get user: %w", err)
	}

	// Generate reset token
	resetToken, err := s.generateResetToken()
	if err != nil {
		return fmt.Errorf("failed to generate reset token: %w", err)
	}

	// Store reset token with expiration (TODO: implement token storage)
	// err = s.tokenStore.StoreResetToken(user.ID, resetToken, time.Hour)

	// Send reset email (TODO: implement email service)
	// err = s.emailService.SendPasswordResetEmail(user.Email, resetToken)

	fmt.Printf("Password reset requested for user %s (token: %s)\n", user.Email, resetToken)
	return nil
}

// ResetPassword resets a user's password using a reset token
func (s *AuthService) ResetPassword(token, newPassword string) error {
	// TODO: Implement token validation and password reset
	return fmt.Errorf("password reset not yet implemented")
}

// VerifyEmail verifies a user's email address
func (s *AuthService) VerifyEmail(token string) error {
	// TODO: Implement email verification
	return fmt.Errorf("email verification not yet implemented")
}

// RevokeToken revokes an access token (add to blacklist)
func (s *AuthService) RevokeToken(tokenString string) error {
	// TODO: Implement token blacklist
	return fmt.Errorf("token revocation not yet implemented")
}

// generateAccessToken creates a JWT access token for a user
func (s *AuthService) generateAccessToken(user *models.User) (string, error) {
	now := time.Now()
	expiresAt := now.Add(s.tokenTTL)

	claims := TokenClaims{
		UserID: user.ID,
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    "pomodoro-app",
			Subject:   user.ID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// generateResetToken generates a secure random token for password reset
func (s *AuthService) generateResetToken() (string, error) {
	bytes := make([]byte, 32)
	_, err := rand.Read(bytes)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(bytes), nil
}

// isPasswordValid validates password strength
func (s *AuthService) isPasswordValid(password string) bool {
	// Basic validation - in production, use more sophisticated rules
	if len(password) < 8 {
		return false
	}

	// Check for at least one uppercase, lowercase, and number
	hasUpper := false
	hasLower := false
	hasNumber := false

	for _, char := range password {
		switch {
		case char >= 'A' && char <= 'Z':
			hasUpper = true
		case char >= 'a' && char <= 'z':
			hasLower = true
		case char >= '0' && char <= '9':
			hasNumber = true
		}
	}

	return hasUpper && hasLower && hasNumber
}

// SetTokenTTL sets the token time-to-live duration
func (s *AuthService) SetTokenTTL(ttl time.Duration) {
	s.tokenTTL = ttl
}

// GetTokenTTL returns the current token time-to-live duration
func (s *AuthService) GetTokenTTL() time.Duration {
	return s.tokenTTL
}

// Logout performs logout operations (primarily for refresh token cleanup)
func (s *AuthService) Logout(userID string) error {
	// TODO: Implement refresh token cleanup and token blacklisting
	fmt.Printf("User %s logged out\n", userID)
	return nil
}
