package services

import (
	"errors"
	"time"
	"crypto/rand"
	"encoding/hex"
	"sync"

	"github.com/golang-jwt/jwt/v5"
	"pomodoro-backend/internal/models"
)

var (
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrUserExists        = errors.New("user already exists")
	ErrUserNotFound      = errors.New("user not found")
	ErrInvalidToken      = errors.New("invalid or expired token")
)

// SimpleAuthService handles authentication operations with in-memory storage
type SimpleAuthService struct {
	jwtSecret   []byte
	tokenExpiry time.Duration
	users       map[string]*models.User // email -> user
	usersByID   map[string]*models.User // id -> user
	mutex       sync.RWMutex
}

// NewSimpleAuthService creates a new authentication service
func NewSimpleAuthService(jwtSecret string, tokenExpiry time.Duration) *SimpleAuthService {
	return &SimpleAuthService{
		jwtSecret:   []byte(jwtSecret),
		tokenExpiry: tokenExpiry,
		users:       make(map[string]*models.User),
		usersByID:   make(map[string]*models.User),
	}
}

// JWTClaims represents JWT token claims
type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// AuthResponse represents authentication response
type AuthResponse struct {
	AccessToken  string               `json:"access_token"`
	RefreshToken string               `json:"refresh_token"`
	User         models.UserResponse  `json:"user"`
	ExpiresIn    int64                `json:"expires_in"` // seconds
}

// Register creates a new user account
func (s *SimpleAuthService) Register(req models.UserCreateRequest) (*AuthResponse, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	// Check if user already exists
	if _, exists := s.users[req.Email]; exists {
		return nil, ErrUserExists
	}

	// Generate user ID
	userID, err := generateID()
	if err != nil {
		return nil, err
	}

	// Create new user
	user, err := models.NewUser(userID, req.Email, req.Name, req.Password)
	if err != nil {
		return nil, err
	}

	// Store user
	s.users[req.Email] = user
	s.usersByID[userID] = user

	// Generate tokens
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, err
	}

	refreshToken, err := generateID()
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user.ToResponse(),
		ExpiresIn:    int64(s.tokenExpiry.Seconds()),
	}, nil
}

// Login authenticates a user
func (s *SimpleAuthService) Login(req models.UserLoginRequest) (*AuthResponse, error) {
	s.mutex.RLock()
	user, exists := s.users[req.Email]
	s.mutex.RUnlock()

	if !exists {
		return nil, ErrInvalidCredentials
	}

	if !user.CheckPassword(req.Password) {
		return nil, ErrInvalidCredentials
	}

	// Generate tokens
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, err
	}

	refreshToken, err := generateID()
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user.ToResponse(),
		ExpiresIn:    int64(s.tokenExpiry.Seconds()),
	}, nil
}

// ValidateToken validates and parses JWT token
func (s *SimpleAuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		return nil, ErrInvalidToken
	}

	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, ErrInvalidToken
}

// GetUserByID retrieves user by ID
func (s *SimpleAuthService) GetUserByID(userID string) (*models.User, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	user, exists := s.usersByID[userID]
	if !exists {
		return nil, ErrUserNotFound
	}

	return user, nil
}

// generateAccessToken creates a new JWT access token
func (s *SimpleAuthService) generateAccessToken(user *models.User) (string, error) {
	claims := JWTClaims{
		UserID: user.ID,
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.tokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Subject:   user.ID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// generateID generates a random hex ID
func generateSimpleID() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}