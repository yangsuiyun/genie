package unit

import (
	"errors"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"
	"golang.org/x/crypto/bcrypt"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/services"
)

// MockUserService is a mock implementation of UserService
type MockUserService struct {
	mock.Mock
}

func (m *MockUserService) Create(user *models.User) (*models.User, error) {
	args := m.Called(user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserService) GetByID(id string) (*models.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserService) GetByEmail(email string) (*models.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserService) Update(user *models.User) (*models.User, error) {
	args := m.Called(user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserService) UpdateLastLogin(userID string) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockUserService) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserService) List(page, limit int) ([]*models.User, int, error) {
	args := m.Called(page, limit)
	return args.Get(0).([]*models.User), args.Int(1), args.Error(2)
}

// AuthServiceTestSuite defines the test suite for AuthService
type AuthServiceTestSuite struct {
	suite.Suite
	authService    *services.AuthService
	mockUserService *MockUserService
	testUser       *models.User
	jwtSecret      string
}

func (suite *AuthServiceTestSuite) SetupTest() {
	suite.mockUserService = new(MockUserService)
	suite.jwtSecret = "test-secret-key-for-jwt-signing"
	suite.authService = services.NewAuthService(suite.mockUserService, suite.jwtSecret)

	// Set up a test user
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("TestPassword123"), bcrypt.DefaultCost)
	suite.testUser = &models.User{
		ID:           models.NewUUID(),
		Email:        "test@example.com",
		PasswordHash: string(hashedPassword),
		IsVerified:   true,
		Preferences:  models.DefaultUserPreferences(),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
}

func (suite *AuthServiceTestSuite) TearDownTest() {
	suite.mockUserService.AssertExpectations(suite.T())
}

// Test Register method
func (suite *AuthServiceTestSuite) TestRegister_Success() {
	req := services.RegisterRequest{
		Email:    "newuser@example.com",
		Password: "StrongPassword123",
		Name:     "Test User",
	}

	// Mock expectations
	suite.mockUserService.On("GetByEmail", req.Email).Return(nil, models.ErrUserNotFound)

	// Create a new user that will be returned by Create
	newUser := &models.User{
		ID:           models.NewUUID(),
		Email:        req.Email,
		PasswordHash: "hashed-password",
		IsVerified:   false,
		Preferences:  models.DefaultUserPreferences(),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	suite.mockUserService.On("Create", mock.AnythingOfType("*models.User")).Return(newUser, nil)

	// Execute
	response, err := suite.authService.Register(req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.Equal(suite.T(), req.Email, response.User.Email)
	assert.NotEmpty(suite.T(), response.AccessToken)
	assert.Equal(suite.T(), "Bearer", response.TokenType)
	assert.Greater(suite.T(), response.ExpiresIn, int64(0))
}

func (suite *AuthServiceTestSuite) TestRegister_EmailAlreadyExists() {
	req := services.RegisterRequest{
		Email:    "existing@example.com",
		Password: "StrongPassword123",
	}

	// Mock expectations - user already exists
	suite.mockUserService.On("GetByEmail", req.Email).Return(suite.testUser, nil)

	// Execute
	response, err := suite.authService.Register(req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Equal(suite.T(), models.ErrEmailAlreadyExists, err)
}

func (suite *AuthServiceTestSuite) TestRegister_WeakPassword() {
	req := services.RegisterRequest{
		Email:    "newuser@example.com",
		Password: "weak",
	}

	// Execute
	response, err := suite.authService.Register(req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
}

// Test Login method
func (suite *AuthServiceTestSuite) TestLogin_Success() {
	req := services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "TestPassword123",
	}

	// Mock expectations
	suite.mockUserService.On("GetByEmail", req.Email).Return(suite.testUser, nil)
	suite.mockUserService.On("UpdateLastLogin", suite.testUser.ID.String()).Return(nil)

	// Execute
	response, err := suite.authService.Login(req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.Equal(suite.T(), suite.testUser.Email, response.User.Email)
	assert.NotEmpty(suite.T(), response.AccessToken)
	assert.Equal(suite.T(), "Bearer", response.TokenType)
}

func (suite *AuthServiceTestSuite) TestLogin_InvalidEmail() {
	req := services.AuthRequest{
		Email:    "nonexistent@example.com",
		Password: "TestPassword123",
	}

	// Mock expectations
	suite.mockUserService.On("GetByEmail", req.Email).Return(nil, models.ErrUserNotFound)

	// Execute
	response, err := suite.authService.Login(req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Equal(suite.T(), models.ErrInvalidCredentials, err)
}

func (suite *AuthServiceTestSuite) TestLogin_InvalidPassword() {
	req := services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "WrongPassword",
	}

	// Mock expectations
	suite.mockUserService.On("GetByEmail", req.Email).Return(suite.testUser, nil)

	// Execute
	response, err := suite.authService.Login(req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Equal(suite.T(), models.ErrInvalidCredentials, err)
}

func (suite *AuthServiceTestSuite) TestLogin_UnverifiedUser() {
	// Create unverified user
	unverifiedUser := *suite.testUser
	unverifiedUser.IsVerified = false

	req := services.AuthRequest{
		Email:    unverifiedUser.Email,
		Password: "TestPassword123",
	}

	// Mock expectations
	suite.mockUserService.On("GetByEmail", req.Email).Return(&unverifiedUser, nil)

	// Execute
	response, err := suite.authService.Login(req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Equal(suite.T(), models.ErrUserNotVerified, err)
}

// Test ValidateToken method
func (suite *AuthServiceTestSuite) TestValidateToken_Success() {
	// Generate a valid token
	token, err := suite.authService.Login(services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "TestPassword123",
	})

	// Setup mock for login first
	suite.mockUserService.On("GetByEmail", suite.testUser.Email).Return(suite.testUser, nil)
	suite.mockUserService.On("UpdateLastLogin", suite.testUser.ID.String()).Return(nil)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), token)

	// Now test validation
	suite.mockUserService.On("GetByID", suite.testUser.ID.String()).Return(suite.testUser, nil)

	// Execute
	user, err := suite.authService.ValidateToken(token.AccessToken)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), user)
	assert.Equal(suite.T(), suite.testUser.ID, user.ID)
	assert.Equal(suite.T(), suite.testUser.Email, user.Email)
}

func (suite *AuthServiceTestSuite) TestValidateToken_InvalidToken() {
	invalidToken := "invalid.jwt.token"

	// Execute
	user, err := suite.authService.ValidateToken(invalidToken)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Equal(suite.T(), models.ErrInvalidToken, err)
}

func (suite *AuthServiceTestSuite) TestValidateToken_ExpiredToken() {
	// Create a short-lived token
	suite.authService.SetTokenTTL(1 * time.Nanosecond)

	// Setup mocks
	suite.mockUserService.On("GetByEmail", suite.testUser.Email).Return(suite.testUser, nil)
	suite.mockUserService.On("UpdateLastLogin", suite.testUser.ID.String()).Return(nil)

	response, err := suite.authService.Login(services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "TestPassword123",
	})
	assert.NoError(suite.T(), err)

	// Wait for token to expire
	time.Sleep(1 * time.Millisecond)

	// Execute
	user, err := suite.authService.ValidateToken(response.AccessToken)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Equal(suite.T(), models.ErrTokenExpired, err)
}

// Test ChangePassword method
func (suite *AuthServiceTestSuite) TestChangePassword_Success() {
	currentPassword := "TestPassword123"
	newPassword := "NewStrongPassword456"

	// Mock expectations
	suite.mockUserService.On("GetByID", suite.testUser.ID.String()).Return(suite.testUser, nil)
	suite.mockUserService.On("Update", mock.AnythingOfType("*models.User")).Return(suite.testUser, nil)

	// Execute
	err := suite.authService.ChangePassword(suite.testUser.ID.String(), currentPassword, newPassword)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *AuthServiceTestSuite) TestChangePassword_InvalidCurrentPassword() {
	currentPassword := "WrongPassword"
	newPassword := "NewStrongPassword456"

	// Mock expectations
	suite.mockUserService.On("GetByID", suite.testUser.ID.String()).Return(suite.testUser, nil)

	// Execute
	err := suite.authService.ChangePassword(suite.testUser.ID.String(), currentPassword, newPassword)

	// Assert
	assert.Error(suite.T(), err)
	assert.Equal(suite.T(), models.ErrInvalidCredentials, err)
}

func (suite *AuthServiceTestSuite) TestChangePassword_WeakNewPassword() {
	currentPassword := "TestPassword123"
	newPassword := "weak"

	// Mock expectations
	suite.mockUserService.On("GetByID", suite.testUser.ID.String()).Return(suite.testUser, nil)

	// Execute
	err := suite.authService.ChangePassword(suite.testUser.ID.String(), currentPassword, newPassword)

	// Assert
	assert.Error(suite.T(), err)
}

// Test RequestPasswordReset method
func (suite *AuthServiceTestSuite) TestRequestPasswordReset_Success() {
	email := suite.testUser.Email

	// Mock expectations
	suite.mockUserService.On("GetByEmail", email).Return(suite.testUser, nil)

	// Execute
	err := suite.authService.RequestPasswordReset(email)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *AuthServiceTestSuite) TestRequestPasswordReset_NonexistentEmail() {
	email := "nonexistent@example.com"

	// Mock expectations
	suite.mockUserService.On("GetByEmail", email).Return(nil, models.ErrUserNotFound)

	// Execute - should not return error for security reasons
	err := suite.authService.RequestPasswordReset(email)

	// Assert
	assert.NoError(suite.T(), err)
}

// Test password validation
func (suite *AuthServiceTestSuite) TestIsPasswordValid() {
	testCases := []struct {
		password string
		expected bool
		name     string
	}{
		{"StrongPassword123", true, "valid strong password"},
		{"password123", false, "missing uppercase"},
		{"PASSWORD123", false, "missing lowercase"},
		{"StrongPassword", false, "missing number"},
		{"Strong1", false, "too short"},
		{"", false, "empty password"},
	}

	for _, tc := range testCases {
		suite.T().Run(tc.name, func(t *testing.T) {
			// Use reflection or create a helper method to test private method
			// For now, we'll test it indirectly through Register
			if tc.expected {
				req := services.RegisterRequest{
					Email:    "test" + tc.name + "@example.com",
					Password: tc.password,
				}

				suite.mockUserService.On("GetByEmail", req.Email).Return(nil, models.ErrUserNotFound).Maybe()

				if tc.expected {
					newUser := &models.User{
						ID:           models.NewUUID(),
						Email:        req.Email,
						PasswordHash: "hashed",
						IsVerified:   false,
						Preferences:  models.DefaultUserPreferences(),
						CreatedAt:    time.Now(),
						UpdatedAt:    time.Now(),
					}
					suite.mockUserService.On("Create", mock.AnythingOfType("*models.User")).Return(newUser, nil).Maybe()
				}

				_, err := suite.authService.Register(req)
				if tc.expected {
					assert.NoError(t, err, "Expected valid password: %s", tc.password)
				} else {
					assert.Error(t, err, "Expected invalid password: %s", tc.password)
				}
			}
		})
	}
}

// Test JWT token generation and validation
func (suite *AuthServiceTestSuite) TestTokenGeneration() {
	// Setup mocks
	suite.mockUserService.On("GetByEmail", suite.testUser.Email).Return(suite.testUser, nil)
	suite.mockUserService.On("UpdateLastLogin", suite.testUser.ID.String()).Return(nil)
	suite.mockUserService.On("GetByID", suite.testUser.ID.String()).Return(suite.testUser, nil)

	// Login to get token
	response, err := suite.authService.Login(services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "TestPassword123",
	})
	assert.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), response.AccessToken)

	// Parse token manually to verify structure
	token, err := jwt.ParseWithClaims(response.AccessToken, &services.TokenClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(suite.jwtSecret), nil
	})
	assert.NoError(suite.T(), err)
	assert.True(suite.T(), token.Valid)

	claims, ok := token.Claims.(*services.TokenClaims)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), suite.testUser.ID.String(), claims.UserID)
	assert.Equal(suite.T(), suite.testUser.Email, claims.Email)
	assert.Equal(suite.T(), "pomodoro-app", claims.Issuer)

	// Validate token through service
	user, err := suite.authService.ValidateToken(response.AccessToken)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), suite.testUser.ID, user.ID)
}

// Test token TTL functionality
func (suite *AuthServiceTestSuite) TestTokenTTL() {
	originalTTL := suite.authService.GetTokenTTL()
	newTTL := 2 * time.Hour

	// Set new TTL
	suite.authService.SetTokenTTL(newTTL)
	assert.Equal(suite.T(), newTTL, suite.authService.GetTokenTTL())

	// Setup mocks
	suite.mockUserService.On("GetByEmail", suite.testUser.Email).Return(suite.testUser, nil)
	suite.mockUserService.On("UpdateLastLogin", suite.testUser.ID.String()).Return(nil)

	// Login with new TTL
	response, err := suite.authService.Login(services.AuthRequest{
		Email:    suite.testUser.Email,
		Password: "TestPassword123",
	})
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), int64(newTTL.Seconds()), response.ExpiresIn)

	// Restore original TTL
	suite.authService.SetTokenTTL(originalTTL)
}

// Test Logout method
func (suite *AuthServiceTestSuite) TestLogout() {
	err := suite.authService.Logout(suite.testUser.ID.String())
	assert.NoError(suite.T(), err)
}

// Test service initialization
func (suite *AuthServiceTestSuite) TestNewAuthService() {
	userService := new(MockUserService)
	jwtSecret := "test-secret"

	authService := services.NewAuthService(userService, jwtSecret)

	assert.NotNil(suite.T(), authService)
	assert.Equal(suite.T(), 24*time.Hour, authService.GetTokenTTL()) // Default TTL
}

// Test error handling in various scenarios
func (suite *AuthServiceTestSuite) TestErrorHandling() {
	// Test database error during registration
	req := services.RegisterRequest{
		Email:    "newuser@example.com",
		Password: "StrongPassword123",
	}

	suite.mockUserService.On("GetByEmail", req.Email).Return(nil, errors.New("database error"))

	response, err := suite.authService.Register(req)
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Contains(suite.T(), err.Error(), "failed to check existing user")
}

// Run the test suite
func TestAuthServiceSuite(t *testing.T) {
	suite.Run(t, new(AuthServiceTestSuite))
}

// Additional individual tests for edge cases
func TestAuthService_EdgeCases(t *testing.T) {
	mockUserService := new(MockUserService)
	authService := services.NewAuthService(mockUserService, "test-secret")

	t.Run("ValidateToken_UserNotFound", func(t *testing.T) {
		// Create a valid token structure but for non-existent user
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("TestPassword123"), bcrypt.DefaultCost)
		testUser := &models.User{
			ID:           models.NewUUID(),
			Email:        "test@example.com",
			PasswordHash: string(hashedPassword),
			IsVerified:   true,
		}

		// Generate token first
		mockUserService.On("GetByEmail", testUser.Email).Return(testUser, nil)
		mockUserService.On("UpdateLastLogin", testUser.ID.String()).Return(nil)

		response, err := authService.Login(services.AuthRequest{
			Email:    testUser.Email,
			Password: "TestPassword123",
		})
		assert.NoError(t, err)

		// Now test validation with user not found
		mockUserService.On("GetByID", testUser.ID.String()).Return(nil, models.ErrUserNotFound)

		user, err := authService.ValidateToken(response.AccessToken)
		assert.Error(t, err)
		assert.Nil(t, user)
		assert.Equal(t, models.ErrUserNotFound, err)

		mockUserService.AssertExpectations(t)
	})

	t.Run("RefreshToken_NotImplemented", func(t *testing.T) {
		response, err := authService.RefreshToken("some-refresh-token")
		assert.Error(t, err)
		assert.Nil(t, response)
		assert.Contains(t, err.Error(), "not yet implemented")
	})

	t.Run("ResetPassword_NotImplemented", func(t *testing.T) {
		err := authService.ResetPassword("token", "newpassword")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not yet implemented")
	})

	t.Run("VerifyEmail_NotImplemented", func(t *testing.T) {
		err := authService.VerifyEmail("token")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not yet implemented")
	})

	t.Run("RevokeToken_NotImplemented", func(t *testing.T) {
		err := authService.RevokeToken("token")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not yet implemented")
	})
}