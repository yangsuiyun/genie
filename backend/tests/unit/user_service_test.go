package unit

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"pomodoro-backend/internal/models"
	"pomodoro-backend/internal/services"
)

// MockUserRepository is a mock implementation of UserRepository
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(user *models.User) (*models.User, error) {
	args := m.Called(user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByID(id uuid.UUID) (*models.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByEmail(email string) (*models.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) Update(user *models.User) (*models.User, error) {
	args := m.Called(user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) List(filter services.UserFilter) ([]*models.User, int, error) {
	args := m.Called(filter)
	return args.Get(0).([]*models.User), args.Int(1), args.Error(2)
}

func (m *MockUserRepository) UpdateLastLogin(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) UpdatePreferences(id uuid.UUID, preferences models.UserPreferences) error {
	args := m.Called(id, preferences)
	return args.Error(0)
}

// UserServiceTestSuite defines the test suite for UserService
type UserServiceTestSuite struct {
	suite.Suite
	userService *services.UserService
	mockRepo    *MockUserRepository
	testUser    *models.User
}

func (suite *UserServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockUserRepository)
	suite.userService = services.NewUserService(suite.mockRepo)

	// Set up a test user
	suite.testUser = &models.User{
		ID:           uuid.New(),
		Email:        "test@example.com",
		PasswordHash: "hashed-password",
		IsVerified:   true,
		Preferences:  models.DefaultUserPreferences(),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
}

func (suite *UserServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

// Test Create method
func (suite *UserServiceTestSuite) TestCreate_Success() {
	newUser := &models.User{
		Email:        "newuser@example.com",
		PasswordHash: "hashed-password",
		IsVerified:   false,
	}

	// Mock expectations
	suite.mockRepo.On("GetByEmail", newUser.Email).Return(nil, models.ErrUserNotFound)
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.User")).Return(newUser, nil)

	// Execute
	createdUser, err := suite.userService.Create(newUser)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), createdUser)
	assert.Equal(suite.T(), newUser.Email, createdUser.Email)
}

func (suite *UserServiceTestSuite) TestCreate_EmailAlreadyExists() {
	newUser := &models.User{
		Email:        suite.testUser.Email,
		PasswordHash: "hashed-password",
	}

	// Mock expectations
	suite.mockRepo.On("GetByEmail", newUser.Email).Return(suite.testUser, nil)

	// Execute
	createdUser, err := suite.userService.Create(newUser)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdUser)
	assert.Equal(suite.T(), models.ErrEmailAlreadyExists, err)
}

func (suite *UserServiceTestSuite) TestCreate_ValidationError() {
	invalidUser := &models.User{
		Email: "invalid-email", // Invalid email format
	}

	// Execute
	createdUser, err := suite.userService.Create(invalidUser)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdUser)
	assert.Contains(suite.T(), err.Error(), "validation failed")
}

// Test GetByID method
func (suite *UserServiceTestSuite) TestGetByID_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(suite.testUser, nil)

	// Execute
	user, err := suite.userService.GetByID(suite.testUser.ID.String())

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), user)
	assert.Equal(suite.T(), suite.testUser.ID, user.ID)
	assert.Equal(suite.T(), suite.testUser.Email, user.Email)
}

func (suite *UserServiceTestSuite) TestGetByID_InvalidUUID() {
	// Execute
	user, err := suite.userService.GetByID("invalid-uuid")

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Contains(suite.T(), err.Error(), "invalid user ID format")
}

func (suite *UserServiceTestSuite) TestGetByID_UserNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(nil, models.ErrUserNotFound)

	// Execute
	user, err := suite.userService.GetByID(suite.testUser.ID.String())

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

// Test GetByEmail method
func (suite *UserServiceTestSuite) TestGetByEmail_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByEmail", suite.testUser.Email).Return(suite.testUser, nil)

	// Execute
	user, err := suite.userService.GetByEmail(suite.testUser.Email)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), user)
	assert.Equal(suite.T(), suite.testUser.Email, user.Email)
}

func (suite *UserServiceTestSuite) TestGetByEmail_EmptyEmail() {
	// Execute
	user, err := suite.userService.GetByEmail("")

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Equal(suite.T(), models.ErrEmailRequired, err)
}

func (suite *UserServiceTestSuite) TestGetByEmail_UserNotFound() {
	email := "nonexistent@example.com"

	// Mock expectations
	suite.mockRepo.On("GetByEmail", email).Return(nil, models.ErrUserNotFound)

	// Execute
	user, err := suite.userService.GetByEmail(email)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

// Test Update method
func (suite *UserServiceTestSuite) TestUpdate_Success() {
	updatedUser := *suite.testUser
	updatedUser.Email = "updated@example.com"

	// Mock expectations
	suite.mockRepo.On("GetByID", updatedUser.ID).Return(suite.testUser, nil)
	suite.mockRepo.On("GetByEmail", updatedUser.Email).Return(nil, models.ErrUserNotFound)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.User")).Return(&updatedUser, nil)

	// Execute
	result, err := suite.userService.Update(&updatedUser)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), updatedUser.Email, result.Email)
}

func (suite *UserServiceTestSuite) TestUpdate_UserNotFound() {
	updatedUser := *suite.testUser

	// Mock expectations
	suite.mockRepo.On("GetByID", updatedUser.ID).Return(nil, models.ErrUserNotFound)

	// Execute
	result, err := suite.userService.Update(&updatedUser)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

func (suite *UserServiceTestSuite) TestUpdate_EmailAlreadyTaken() {
	updatedUser := *suite.testUser
	updatedUser.Email = "taken@example.com"

	existingUserWithTakenEmail := &models.User{
		ID:    uuid.New(),
		Email: updatedUser.Email,
	}

	// Mock expectations
	suite.mockRepo.On("GetByID", updatedUser.ID).Return(suite.testUser, nil)
	suite.mockRepo.On("GetByEmail", updatedUser.Email).Return(existingUserWithTakenEmail, nil)

	// Execute
	result, err := suite.userService.Update(&updatedUser)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrEmailAlreadyExists, err)
}

// Test Delete method
func (suite *UserServiceTestSuite) TestDelete_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(suite.testUser, nil)
	suite.mockRepo.On("Delete", suite.testUser.ID).Return(nil)

	// Execute
	err := suite.userService.Delete(suite.testUser.ID.String())

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *UserServiceTestSuite) TestDelete_InvalidUUID() {
	// Execute
	err := suite.userService.Delete("invalid-uuid")

	// Assert
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "invalid user ID format")
}

func (suite *UserServiceTestSuite) TestDelete_UserNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(nil, models.ErrUserNotFound)

	// Execute
	err := suite.userService.Delete(suite.testUser.ID.String())

	// Assert
	assert.Error(suite.T(), err)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

// Test List method
func (suite *UserServiceTestSuite) TestList_Success() {
	users := []*models.User{suite.testUser}
	filter := services.UserFilter{
		Limit:  10,
		Offset: 0,
	}

	// Mock expectations
	suite.mockRepo.On("List", mock.AnythingOfType("services.UserFilter")).Return(users, 1, nil)

	// Execute
	result, total, err := suite.userService.List(filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), users, result)
	assert.Equal(suite.T(), 1, total)
}

func (suite *UserServiceTestSuite) TestList_DefaultValues() {
	users := []*models.User{}
	filter := services.UserFilter{} // Empty filter to test defaults

	// Mock expectations
	suite.mockRepo.On("List", mock.MatchedBy(func(f services.UserFilter) bool {
		return f.Limit == 20 && f.Offset == 0 && f.SortBy == "created_at" && f.SortOrder == "desc"
	})).Return(users, 0, nil)

	// Execute
	result, total, err := suite.userService.List(filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), users, result)
	assert.Equal(suite.T(), 0, total)
}

func (suite *UserServiceTestSuite) TestList_MaxLimit() {
	users := []*models.User{}
	filter := services.UserFilter{
		Limit: 200, // Exceeds max limit
	}

	// Mock expectations
	suite.mockRepo.On("List", mock.MatchedBy(func(f services.UserFilter) bool {
		return f.Limit == 100 // Should be capped at 100
	})).Return(users, 0, nil)

	// Execute
	result, total, err := suite.userService.List(filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), users, result)
	assert.Equal(suite.T(), 0, total)
}

// Test UpdateLastLogin method
func (suite *UserServiceTestSuite) TestUpdateLastLogin_Success() {
	// Mock expectations
	suite.mockRepo.On("UpdateLastLogin", suite.testUser.ID).Return(nil)

	// Execute
	err := suite.userService.UpdateLastLogin(suite.testUser.ID)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *UserServiceTestSuite) TestUpdateLastLogin_Error() {
	// Mock expectations
	suite.mockRepo.On("UpdateLastLogin", suite.testUser.ID).Return(errors.New("database error"))

	// Execute
	err := suite.userService.UpdateLastLogin(suite.testUser.ID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "failed to update last login")
}

// Test UpdatePreferences method
func (suite *UserServiceTestSuite) TestUpdatePreferences_Success() {
	newPreferences := models.UserPreferences{
		Pomodoro: models.PomodoroPreferences{
			WorkDuration:      25 * 60,
			ShortBreakDuration: 5 * 60,
			LongBreakDuration:  15 * 60,
			LongBreakInterval:  4,
		},
	}

	updatedUser := *suite.testUser
	updatedUser.Preferences = newPreferences

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(suite.testUser, nil)
	suite.mockRepo.On("UpdatePreferences", suite.testUser.ID, newPreferences).Return(nil)
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(&updatedUser, nil)

	// Execute
	result, err := suite.userService.UpdatePreferences(suite.testUser.ID.String(), newPreferences)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), newPreferences, result.Preferences)
}

func (suite *UserServiceTestSuite) TestUpdatePreferences_InvalidUUID() {
	preferences := models.DefaultUserPreferences()

	// Execute
	result, err := suite.userService.UpdatePreferences("invalid-uuid", preferences)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "invalid user ID format")
}

func (suite *UserServiceTestSuite) TestUpdatePreferences_UserNotFound() {
	preferences := models.DefaultUserPreferences()

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(nil, models.ErrUserNotFound)

	// Execute
	result, err := suite.userService.UpdatePreferences(suite.testUser.ID.String(), preferences)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

// Test VerifyEmail method
func (suite *UserServiceTestSuite) TestVerifyEmail_Success() {
	unverifiedUser := *suite.testUser
	unverifiedUser.IsVerified = false

	verifiedUser := unverifiedUser
	verifiedUser.IsVerified = true

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(&unverifiedUser, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.User")).Return(&verifiedUser, nil)

	// Execute
	err := suite.userService.VerifyEmail(suite.testUser.ID.String())

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *UserServiceTestSuite) TestVerifyEmail_AlreadyVerified() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(suite.testUser, nil) // Already verified

	// Execute
	err := suite.userService.VerifyEmail(suite.testUser.ID.String())

	// Assert
	assert.NoError(suite.T(), err) // Should not return error if already verified
}

// Test SearchUsers method
func (suite *UserServiceTestSuite) TestSearchUsers_Success() {
	users := []*models.User{suite.testUser}
	query := "test"

	// Mock expectations
	suite.mockRepo.On("List", mock.AnythingOfType("services.UserFilter")).Return(users, 1, nil)

	// Execute
	result, err := suite.userService.SearchUsers(query, 10)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), users, result)
}

func (suite *UserServiceTestSuite) TestSearchUsers_EmptyQuery() {
	// Execute
	result, err := suite.userService.SearchUsers("", 10)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Empty(suite.T(), result)
}

func (suite *UserServiceTestSuite) TestSearchUsers_MaxLimit() {
	users := []*models.User{}

	// Mock expectations
	suite.mockRepo.On("List", mock.MatchedBy(func(f services.UserFilter) bool {
		return f.Limit == 50 // Should be capped at 50 for search
	})).Return(users, 0, nil)

	// Execute
	result, err := suite.userService.SearchUsers("test", 100) // Exceeds max

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), users, result)
}

// Test GetUserStats method
func (suite *UserServiceTestSuite) TestGetUserStats() {
	// Execute
	stats, err := suite.userService.GetUserStats()

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), stats)
	assert.Equal(suite.T(), 0, stats.TotalUsers) // Default implementation returns zeros
}

// Test GetUserPreferences method
func (suite *UserServiceTestSuite) TestGetUserPreferences_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(suite.testUser, nil)

	// Execute
	preferences, err := suite.userService.GetUserPreferences(suite.testUser.ID.String())

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), preferences)
	assert.Equal(suite.T(), &suite.testUser.Preferences, preferences)
}

func (suite *UserServiceTestSuite) TestGetUserPreferences_UserNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testUser.ID).Return(nil, models.ErrUserNotFound)

	// Execute
	preferences, err := suite.userService.GetUserPreferences(suite.testUser.ID.String())

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), preferences)
	assert.Equal(suite.T(), models.ErrUserNotFound, err)
}

// Run the test suite
func TestUserServiceSuite(t *testing.T) {
	suite.Run(t, new(UserServiceTestSuite))
}

// Additional individual tests
func TestUserService_EdgeCases(t *testing.T) {
	mockRepo := new(MockUserRepository)
	userService := services.NewUserService(mockRepo)

	t.Run("Create_DatabaseError", func(t *testing.T) {
		newUser := &models.User{
			Email:        "test@example.com",
			PasswordHash: "hashed",
		}

		mockRepo.On("GetByEmail", newUser.Email).Return(nil, models.ErrUserNotFound)
		mockRepo.On("Create", mock.AnythingOfType("*models.User")).Return(nil, errors.New("database error"))

		result, err := userService.Create(newUser)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to create user")

		mockRepo.AssertExpectations(t)
	})

	t.Run("Update_DatabaseError", func(t *testing.T) {
		testUser := &models.User{
			ID:           uuid.New(),
			Email:        "test@example.com",
			PasswordHash: "hashed",
		}

		mockRepo.On("GetByID", testUser.ID).Return(testUser, nil)
		mockRepo.On("Update", mock.AnythingOfType("*models.User")).Return(nil, errors.New("database error"))

		result, err := userService.Update(testUser)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to update user")

		mockRepo.AssertExpectations(t)
	})

	t.Run("GetRecentUsers_Success", func(t *testing.T) {
		users := []*models.User{}

		mockRepo.On("List", mock.AnythingOfType("services.UserFilter")).Return(users, 0, nil)

		result, err := userService.GetRecentUsers(5)
		assert.NoError(t, err)
		assert.Equal(t, users, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("DeactivateUser_Success", func(t *testing.T) {
		testUser := &models.User{
			ID:    uuid.New(),
			Email: "test@example.com",
		}

		mockRepo.On("GetByID", testUser.ID).Return(testUser, nil)
		mockRepo.On("Update", mock.AnythingOfType("*models.User")).Return(testUser, nil)

		err := userService.DeactivateUser(testUser.ID.String())
		assert.NoError(t, err)

		mockRepo.AssertExpectations(t)
	})
}