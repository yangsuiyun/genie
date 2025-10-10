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

// MockPomodoroRepository is a mock implementation of PomodoroRepository
type MockPomodoroRepository struct {
	mock.Mock
}

func (m *MockPomodoroRepository) Create(session *models.PomodoroSession) (*models.PomodoroSession, error) {
	args := m.Called(session)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.PomodoroSession), args.Error(1)
}

func (m *MockPomodoroRepository) GetByID(id uuid.UUID) (*models.PomodoroSession, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.PomodoroSession), args.Error(1)
}

func (m *MockPomodoroRepository) GetByUserID(userID uuid.UUID, filter services.PomodoroFilter) ([]*models.PomodoroSession, int, error) {
	args := m.Called(userID, filter)
	return args.Get(0).([]*models.PomodoroSession), args.Int(1), args.Error(2)
}

func (m *MockPomodoroRepository) GetActiveSession(userID uuid.UUID) (*models.PomodoroSession, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.PomodoroSession), args.Error(1)
}

func (m *MockPomodoroRepository) Update(session *models.PomodoroSession) (*models.PomodoroSession, error) {
	args := m.Called(session)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.PomodoroSession), args.Error(1)
}

func (m *MockPomodoroRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockPomodoroRepository) GetSessionsByTaskID(taskID uuid.UUID) ([]*models.PomodoroSession, error) {
	args := m.Called(taskID)
	return args.Get(0).([]*models.PomodoroSession), args.Error(1)
}

func (m *MockPomodoroRepository) GetSessionStats(userID uuid.UUID, startDate, endDate time.Time) (*services.PomodoroStats, error) {
	args := m.Called(userID, startDate, endDate)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*services.PomodoroStats), args.Error(1)
}

func (m *MockPomodoroRepository) GetStreakData(userID uuid.UUID) (*services.StreakData, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*services.StreakData), args.Error(1)
}

// PomodoroServiceTestSuite defines the test suite for PomodoroService
type PomodoroServiceTestSuite struct {
	suite.Suite
	pomodoroService *services.PomodoroService
	mockRepo        *MockPomodoroRepository
	testUserID      uuid.UUID
	testTaskID      uuid.UUID
	testSession     *models.PomodoroSession
}

func (suite *PomodoroServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockPomodoroRepository)
	suite.pomodoroService = services.NewPomodoroService(suite.mockRepo)
	suite.testUserID = uuid.New()
	suite.testTaskID = uuid.New()

	// Set up a test session
	suite.testSession = &models.PomodoroSession{
		ID:              uuid.New(),
		UserID:          suite.testUserID,
		TaskID:          suite.testTaskID,
		SessionType:     models.SessionTypeWork,
		Status:          models.PomodoroStatusActive,
		PlannedDuration: 25 * 60, // 25 minutes
		ActualDuration:  0,
		StartedAt:       time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}
}

func (suite *PomodoroServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

// Test StartSession method
func (suite *PomodoroServiceTestSuite) TestStartSession_Success() {
	req := services.StartSessionRequest{
		TaskID:          suite.testTaskID,
		SessionType:     models.SessionTypeWork,
		PlannedDuration: 25 * 60,
		CustomMessage:   "Focus time!",
	}

	expectedSession := &models.PomodoroSession{
		ID:              uuid.New(),
		UserID:          suite.testUserID,
		TaskID:          req.TaskID,
		SessionType:     req.SessionType,
		Status:          models.PomodoroStatusActive,
		PlannedDuration: req.PlannedDuration,
		StartedAt:       time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// Mock expectations
	suite.mockRepo.On("GetActiveSession", suite.testUserID).Return(nil, models.ErrSessionNotFound)
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.PomodoroSession")).Return(expectedSession, nil)

	// Execute
	session, err := suite.pomodoroService.StartSession(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), req.TaskID, session.TaskID)
	assert.Equal(suite.T(), req.SessionType, session.SessionType)
	assert.Equal(suite.T(), models.PomodoroStatusActive, session.Status)
}

func (suite *PomodoroServiceTestSuite) TestStartSession_ActiveSessionExists() {
	req := services.StartSessionRequest{
		TaskID:          suite.testTaskID,
		SessionType:     models.SessionTypeWork,
		PlannedDuration: 25 * 60,
	}

	// Mock expectations - active session already exists
	suite.mockRepo.On("GetActiveSession", suite.testUserID).Return(suite.testSession, nil)

	// Execute
	session, err := suite.pomodoroService.StartSession(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrActiveSessionExists, err)
}

func (suite *PomodoroServiceTestSuite) TestStartSession_InvalidDuration() {
	req := services.StartSessionRequest{
		TaskID:          suite.testTaskID,
		SessionType:     models.SessionTypeWork,
		PlannedDuration: 30, // Too short (less than 1 minute)
	}

	// Execute
	session, err := suite.pomodoroService.StartSession(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrInvalidDuration, err)
}

// Test PauseSession method
func (suite *PomodoroServiceTestSuite) TestPauseSession_Success() {
	pausedSession := *suite.testSession
	pausedSession.Status = models.PomodoroStatusPaused
	pausedAt := time.Now()
	pausedSession.PausedAt = &pausedAt

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.PomodoroSession")).Return(&pausedSession, nil)

	// Execute
	session, err := suite.pomodoroService.PauseSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), models.PomodoroStatusPaused, session.Status)
	assert.NotNil(suite.T(), session.PausedAt)
}

func (suite *PomodoroServiceTestSuite) TestPauseSession_NotActive() {
	pausedSession := *suite.testSession
	pausedSession.Status = models.PomodoroStatusPaused

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(&pausedSession, nil)

	// Execute
	session, err := suite.pomodoroService.PauseSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrSessionNotActive, err)
}

// Test ResumeSession method
func (suite *PomodoroServiceTestSuite) TestResumeSession_Success() {
	pausedSession := *suite.testSession
	pausedSession.Status = models.PomodoroStatusPaused
	pausedAt := time.Now().Add(-5 * time.Minute)
	pausedSession.PausedAt = &pausedAt

	resumedSession := pausedSession
	resumedSession.Status = models.PomodoroStatusActive
	resumedSession.PausedAt = nil

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(&pausedSession, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.PomodoroSession")).Return(&resumedSession, nil)

	// Execute
	session, err := suite.pomodoroService.ResumeSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), models.PomodoroStatusActive, session.Status)
	assert.Nil(suite.T(), session.PausedAt)
}

func (suite *PomodoroServiceTestSuite) TestResumeSession_NotPaused() {
	// Mock expectations - session is active, not paused
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)

	// Execute
	session, err := suite.pomodoroService.ResumeSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrSessionNotPaused, err)
}

// Test CompleteSession method
func (suite *PomodoroServiceTestSuite) TestCompleteSession_Success() {
	completedSession := *suite.testSession
	completedSession.Status = models.SessionTaskStatusCompleted
	completedAt := time.Now()
	completedSession.CompletedAt = &completedAt
	completedSession.ActualDuration = 25 * 60 // Full duration

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.PomodoroSession")).Return(&completedSession, nil)

	// Execute
	session, err := suite.pomodoroService.CompleteSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), models.SessionTaskStatusCompleted, session.Status)
	assert.NotNil(suite.T(), session.CompletedAt)
	assert.Greater(suite.T(), session.ActualDuration, 0)
}

func (suite *PomodoroServiceTestSuite) TestCompleteSession_AlreadyCompleted() {
	completedSession := *suite.testSession
	completedSession.Status = models.SessionTaskStatusCompleted
	completedAt := time.Now().Add(-1 * time.Hour)
	completedSession.CompletedAt = &completedAt

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(&completedSession, nil)

	// Execute
	session, err := suite.pomodoroService.CompleteSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrSessionAlreadyCompleted, err)
}

// Test InterruptSession method
func (suite *PomodoroServiceTestSuite) TestInterruptSession_Success() {
	reason := "Urgent meeting"
	interruptedSession := *suite.testSession
	interruptedSession.Status = models.PomodoroStatusInterrupted
	interruptedSession.InterruptionCount = 1
	interruptedSession.InterruptionReason = &reason
	interruptedAt := time.Now()
	interruptedSession.InterruptedAt = &interruptedAt

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.PomodoroSession")).Return(&interruptedSession, nil)

	// Execute
	session, err := suite.pomodoroService.InterruptSession(suite.testSession.ID.String(), suite.testUserID, reason)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), models.PomodoroStatusInterrupted, session.Status)
	assert.Equal(suite.T(), 1, session.InterruptionCount)
	assert.Equal(suite.T(), &reason, session.InterruptionReason)
}

// Test GetActiveSession method
func (suite *PomodoroServiceTestSuite) TestGetActiveSession_Success() {
	// Mock expectations
	suite.mockRepo.On("GetActiveSession", suite.testUserID).Return(suite.testSession, nil)

	// Execute
	session, err := suite.pomodoroService.GetActiveSession(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), suite.testSession.ID, session.ID)
	assert.Equal(suite.T(), models.PomodoroStatusActive, session.Status)
}

func (suite *PomodoroServiceTestSuite) TestGetActiveSession_NoActiveSession() {
	// Mock expectations
	suite.mockRepo.On("GetActiveSession", suite.testUserID).Return(nil, models.ErrSessionNotFound)

	// Execute
	session, err := suite.pomodoroService.GetActiveSession(suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrSessionNotFound, err)
}

// Test GetSessionByID method
func (suite *PomodoroServiceTestSuite) TestGetSessionByID_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)

	// Execute
	session, err := suite.pomodoroService.GetSessionByID(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), session)
	assert.Equal(suite.T(), suite.testSession.ID, session.ID)
}

func (suite *PomodoroServiceTestSuite) TestGetSessionByID_InvalidUUID() {
	// Execute
	session, err := suite.pomodoroService.GetSessionByID("invalid-uuid", suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Contains(suite.T(), err.Error(), "invalid session ID format")
}

func (suite *PomodoroServiceTestSuite) TestGetSessionByID_NotOwned() {
	differentUserID := uuid.New()
	sessionOwnedByDifferentUser := *suite.testSession
	sessionOwnedByDifferentUser.UserID = differentUserID

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(&sessionOwnedByDifferentUser, nil)

	// Execute
	session, err := suite.pomodoroService.GetSessionByID(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), session)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

// Test ListSessions method
func (suite *PomodoroServiceTestSuite) TestListSessions_Success() {
	sessions := []*models.PomodoroSession{suite.testSession}
	filter := services.PomodoroFilter{
		SessionType: &models.SessionTypeWork,
		Limit:       10,
		Offset:      0,
	}

	// Mock expectations
	suite.mockRepo.On("GetByUserID", suite.testUserID, mock.AnythingOfType("services.PomodoroFilter")).Return(sessions, 1, nil)

	// Execute
	result, total, err := suite.pomodoroService.ListSessions(suite.testUserID, filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), sessions, result)
	assert.Equal(suite.T(), 1, total)
}

// Test GetSessionsByTask method
func (suite *PomodoroServiceTestSuite) TestGetSessionsByTask_Success() {
	sessions := []*models.PomodoroSession{suite.testSession}

	// Mock expectations
	suite.mockRepo.On("GetSessionsByTaskID", suite.testTaskID).Return(sessions, nil)

	// Execute
	result, err := suite.pomodoroService.GetSessionsByTask(suite.testTaskID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), sessions, result)
}

// Test GetSessionStats method
func (suite *PomodoroServiceTestSuite) TestGetSessionStats_Success() {
	startDate := time.Now().AddDate(0, 0, -7)
	endDate := time.Now()
	stats := &services.PomodoroStats{
		TotalSessions:     10,
		CompletedSessions: 8,
		TotalFocusTime:    4 * time.Hour,
		CompletionRate:    0.8,
	}

	// Mock expectations
	suite.mockRepo.On("GetSessionStats", suite.testUserID, startDate, endDate).Return(stats, nil)

	// Execute
	result, err := suite.pomodoroService.GetSessionStats(suite.testUserID, startDate, endDate)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), stats, result)
}

// Test GetStreakData method
func (suite *PomodoroServiceTestSuite) TestGetStreakData_Success() {
	streakData := &services.StreakData{
		CurrentStreak:  5,
		LongestStreak:  12,
		LastActiveDate: time.Now(),
		StreakGoal:     7,
	}

	// Mock expectations
	suite.mockRepo.On("GetStreakData", suite.testUserID).Return(streakData, nil)

	// Execute
	result, err := suite.pomodoroService.GetStreakData(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), streakData, result)
}

// Test GetSessionTimerInfo method
func (suite *PomodoroServiceTestSuite) TestGetSessionTimerInfo_Success() {
	// Mock expectations
	suite.mockRepo.On("GetActiveSession", suite.testUserID).Return(suite.testSession, nil)

	// Execute
	result, err := suite.pomodoroService.GetSessionTimerInfo(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), suite.testSession.ID, result.SessionID)
	assert.Equal(suite.T(), suite.testSession.TaskID, result.TaskID)
	assert.Equal(suite.T(), suite.testSession.SessionType, result.SessionType)
	assert.Equal(suite.T(), suite.testSession.Status, result.Status)
}

// Test DeleteSession method
func (suite *PomodoroServiceTestSuite) TestDeleteSession_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(suite.testSession, nil)
	suite.mockRepo.On("Delete", suite.testSession.ID).Return(nil)

	// Execute
	err := suite.pomodoroService.DeleteSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *PomodoroServiceTestSuite) TestDeleteSession_SessionNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testSession.ID).Return(nil, models.ErrSessionNotFound)

	// Execute
	err := suite.pomodoroService.DeleteSession(suite.testSession.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Equal(suite.T(), models.ErrSessionNotFound, err)
}

// Run the test suite
func TestPomodoroServiceSuite(t *testing.T) {
	suite.Run(t, new(PomodoroServiceTestSuite))
}

// Additional individual tests for edge cases
func TestPomodoroService_EdgeCases(t *testing.T) {
	mockRepo := new(MockPomodoroRepository)
	pomodoroService := services.NewPomodoroService(mockRepo)
	userID := uuid.New()

	t.Run("StartSession_DatabaseError", func(t *testing.T) {
		req := services.StartSessionRequest{
			TaskID:          uuid.New(),
			SessionType:     models.SessionTypeWork,
			PlannedDuration: 25 * 60,
		}

		mockRepo.On("GetActiveSession", userID).Return(nil, models.ErrSessionNotFound)
		mockRepo.On("Create", mock.AnythingOfType("*models.PomodoroSession")).Return(nil, errors.New("database error"))

		result, err := pomodoroService.StartSession(userID, req)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to create session")

		mockRepo.AssertExpectations(t)
	})

	t.Run("UpdateSession_Success", func(t *testing.T) {
		sessionID := uuid.New()
		testSession := &models.PomodoroSession{
			ID:     sessionID,
			UserID: userID,
			Status: models.PomodoroStatusActive,
		}

		notes := "Good session"
		req := services.UpdateSessionRequest{
			Notes: &notes,
		}

		updatedSession := *testSession
		updatedSession.Notes = &notes

		mockRepo.On("GetByID", sessionID).Return(testSession, nil)
		mockRepo.On("Update", mock.AnythingOfType("*models.PomodoroSession")).Return(&updatedSession, nil)

		result, err := pomodoroService.UpdateSession(sessionID.String(), userID, req)
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, &notes, result.Notes)

		mockRepo.AssertExpectations(t)
	})

	t.Run("GetTodaysSessions_Success", func(t *testing.T) {
		sessions := []*models.PomodoroSession{}

		mockRepo.On("GetByUserID", userID, mock.AnythingOfType("services.PomodoroFilter")).Return(sessions, 0, nil)

		result, err := pomodoroService.GetTodaysSessions(userID)
		assert.NoError(t, err)
		assert.Equal(t, sessions, result)

		mockRepo.AssertExpectations(t)
	})
}