package unit

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"backend/internal/models"
	"backend/internal/services"
)

// Mock repositories for remaining services
type MockReportRepository struct {
	mock.Mock
}

func (m *MockReportRepository) Create(report *models.Report) (*models.Report, error) {
	args := m.Called(report)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Report), args.Error(1)
}

func (m *MockReportRepository) GetByID(id uuid.UUID) (*models.Report, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Report), args.Error(1)
}

func (m *MockReportRepository) GetByUserID(userID uuid.UUID, filter services.ReportFilter) ([]*models.Report, int, error) {
	args := m.Called(userID, filter)
	return args.Get(0).([]*models.Report), args.Int(1), args.Error(2)
}

func (m *MockReportRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

type MockNotificationRepository struct {
	mock.Mock
}

func (m *MockNotificationRepository) Create(notification *models.Notification) (*models.Notification, error) {
	args := m.Called(notification)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Notification), args.Error(1)
}

func (m *MockNotificationRepository) GetByUserID(userID uuid.UUID, filter services.NotificationFilter) ([]*models.Notification, int, error) {
	args := m.Called(userID, filter)
	return args.Get(0).([]*models.Notification), args.Int(1), args.Error(2)
}

func (m *MockNotificationRepository) MarkAsRead(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockNotificationRepository) MarkAllAsRead(userID uuid.UUID) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockNotificationRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

type MockSyncRepository struct {
	mock.Mock
}

func (m *MockSyncRepository) GetLastSyncTime(userID uuid.UUID, deviceID string) (*time.Time, error) {
	args := m.Called(userID, deviceID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*time.Time), args.Error(1)
}

func (m *MockSyncRepository) UpdateSyncTime(userID uuid.UUID, deviceID string, syncTime time.Time) error {
	args := m.Called(userID, deviceID, syncTime)
	return args.Error(0)
}

func (m *MockSyncRepository) GetChangedEntities(userID uuid.UUID, since time.Time, entityTypes []string) ([]services.SyncEntity, error) {
	args := m.Called(userID, since, entityTypes)
	return args.Get(0).([]services.SyncEntity), args.Error(1)
}

func (m *MockSyncRepository) ApplyChanges(userID uuid.UUID, entities []services.SyncEntity) ([]services.SyncConflict, error) {
	args := m.Called(userID, entities)
	return args.Get(0).([]services.SyncConflict), args.Error(1)
}

// ReportService Tests
type ReportServiceTestSuite struct {
	suite.Suite
	reportService *services.ReportService
	mockRepo      *MockReportRepository
	testUserID    uuid.UUID
	testReport    *models.Report
}

func (suite *ReportServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockReportRepository)
	suite.reportService = services.NewReportService(suite.mockRepo)
	suite.testUserID = uuid.New()

	suite.testReport = &models.Report{
		ID:         uuid.New(),
		UserID:     suite.testUserID,
		ReportType: models.ReportTypeWeekly,
		StartDate:  time.Now().AddDate(0, 0, -7),
		EndDate:    time.Now(),
		GeneratedAt: time.Now(),
		Data: models.ReportData{
			TasksCompleted:      15,
			PomodoroCompleted:   30,
			TotalFocusTime:      12 * time.Hour,
			ProductivityScore:   85.5,
		},
	}
}

func (suite *ReportServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

func (suite *ReportServiceTestSuite) TestGenerateReport_Success() {
	req := services.GenerateReportRequest{
		ReportType: models.ReportTypeWeekly,
		StartDate:  time.Now().AddDate(0, 0, -7),
		EndDate:    time.Now(),
	}

	// Mock expectations
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.Report")).Return(suite.testReport, nil)

	// Execute
	report, err := suite.reportService.GenerateReport(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), report)
	assert.Equal(suite.T(), req.ReportType, report.ReportType)
}

func (suite *ReportServiceTestSuite) TestGenerateReport_InvalidDateRange() {
	req := services.GenerateReportRequest{
		ReportType: models.ReportTypeWeekly,
		StartDate:  time.Now(),
		EndDate:    time.Now().AddDate(0, 0, -7), // End before start
	}

	// Execute
	report, err := suite.reportService.GenerateReport(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), report)
	assert.Equal(suite.T(), models.ErrInvalidDateRange, err)
}

func (suite *ReportServiceTestSuite) TestGetReportByID_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testReport.ID).Return(suite.testReport, nil)

	// Execute
	report, err := suite.reportService.GetReportByID(suite.testReport.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), report)
	assert.Equal(suite.T(), suite.testReport.ID, report.ID)
}

func (suite *ReportServiceTestSuite) TestGetReportByID_NotOwned() {
	differentUserID := uuid.New()
	reportOwnedByDifferentUser := *suite.testReport
	reportOwnedByDifferentUser.UserID = differentUserID

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testReport.ID).Return(&reportOwnedByDifferentUser, nil)

	// Execute
	report, err := suite.reportService.GetReportByID(suite.testReport.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), report)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

func (suite *ReportServiceTestSuite) TestListReports_Success() {
	reports := []*models.Report{suite.testReport}
	filter := services.ReportFilter{
		ReportType: &models.ReportTypeWeekly,
		Limit:      10,
		Offset:     0,
	}

	// Mock expectations
	suite.mockRepo.On("GetByUserID", suite.testUserID, mock.AnythingOfType("services.ReportFilter")).Return(reports, 1, nil)

	// Execute
	result, total, err := suite.reportService.ListReports(suite.testUserID, filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), reports, result)
	assert.Equal(suite.T(), 1, total)
}

func (suite *ReportServiceTestSuite) TestDeleteReport_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testReport.ID).Return(suite.testReport, nil)
	suite.mockRepo.On("Delete", suite.testReport.ID).Return(nil)

	// Execute
	err := suite.reportService.DeleteReport(suite.testReport.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
}

// NotificationService Tests
type NotificationServiceTestSuite struct {
	suite.Suite
	notificationService *services.NotificationService
	mockRepo            *MockNotificationRepository
	testUserID          uuid.UUID
	testNotification    *models.Notification
}

func (suite *NotificationServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockNotificationRepository)
	suite.notificationService = services.NewNotificationService(suite.mockRepo)
	suite.testUserID = uuid.New()

	suite.testNotification = &models.Notification{
		ID:      uuid.New(),
		UserID:  suite.testUserID,
		Type:    models.NotificationTypeTaskReminder,
		Title:   "Task Reminder",
		Message: "Don't forget about your important task!",
		IsRead:  false,
		CreatedAt: time.Now(),
	}
}

func (suite *NotificationServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

func (suite *NotificationServiceTestSuite) TestSendNotification_Success() {
	req := services.SendNotificationRequest{
		Type:    models.NotificationTypeTaskReminder,
		Title:   "Test Notification",
		Message: "This is a test",
	}

	// Mock expectations
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.Notification")).Return(suite.testNotification, nil)

	// Execute
	notification, err := suite.notificationService.SendNotification(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), notification)
	assert.Equal(suite.T(), req.Type, notification.Type)
}

func (suite *NotificationServiceTestSuite) TestSendNotification_EmptyTitle() {
	req := services.SendNotificationRequest{
		Type:    models.NotificationTypeTaskReminder,
		Title:   "", // Empty title
		Message: "This is a test",
	}

	// Execute
	notification, err := suite.notificationService.SendNotification(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), notification)
	assert.Equal(suite.T(), models.ErrNotificationTitleRequired, err)
}

func (suite *NotificationServiceTestSuite) TestListNotifications_Success() {
	notifications := []*models.Notification{suite.testNotification}
	filter := services.NotificationFilter{
		IsRead: func(b bool) *bool { return &b }(false),
		Limit:  10,
		Offset: 0,
	}

	// Mock expectations
	suite.mockRepo.On("GetByUserID", suite.testUserID, mock.AnythingOfType("services.NotificationFilter")).Return(notifications, 1, nil)

	// Execute
	result, total, err := suite.notificationService.ListNotifications(suite.testUserID, filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), notifications, result)
	assert.Equal(suite.T(), 1, total)
}

func (suite *NotificationServiceTestSuite) TestMarkAsRead_Success() {
	// Mock expectations
	suite.mockRepo.On("MarkAsRead", suite.testNotification.ID).Return(nil)

	// Execute
	err := suite.notificationService.MarkAsRead(suite.testNotification.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *NotificationServiceTestSuite) TestMarkAllAsRead_Success() {
	// Mock expectations
	suite.mockRepo.On("MarkAllAsRead", suite.testUserID).Return(nil)

	// Execute
	err := suite.notificationService.MarkAllAsRead(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
}

// SyncService Tests
type SyncServiceTestSuite struct {
	suite.Suite
	syncService *services.SyncService
	mockRepo    *MockSyncRepository
	testUserID  uuid.UUID
	deviceID    string
}

func (suite *SyncServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockSyncRepository)
	suite.syncService = services.NewSyncService(suite.mockRepo)
	suite.testUserID = uuid.New()
	suite.deviceID = "test-device-123"
}

func (suite *SyncServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

func (suite *SyncServiceTestSuite) TestSync_Success() {
	lastSyncTime := time.Now().Add(-1 * time.Hour)
	entities := []services.SyncEntity{
		{
			EntityType: "task",
			EntityID:   uuid.New().String(),
			Action:     "update",
			Data:       []byte(`{"title": "Updated Task"}`),
			UpdatedAt:  time.Now(),
		},
	}

	req := services.SyncRequest{
		DeviceID:     suite.deviceID,
		LastSyncTime: &lastSyncTime,
		Entities:     entities,
	}

	changedEntities := []services.SyncEntity{
		{
			EntityType: "task",
			EntityID:   uuid.New().String(),
			Action:     "create",
			Data:       []byte(`{"title": "New Task"}`),
			UpdatedAt:  time.Now(),
		},
	}

	conflicts := []services.SyncConflict{}

	// Mock expectations
	suite.mockRepo.On("GetLastSyncTime", suite.testUserID, suite.deviceID).Return(&lastSyncTime, nil)
	suite.mockRepo.On("ApplyChanges", suite.testUserID, entities).Return(conflicts, nil)
	suite.mockRepo.On("GetChangedEntities", suite.testUserID, lastSyncTime, mock.AnythingOfType("[]string")).Return(changedEntities, nil)
	suite.mockRepo.On("UpdateSyncTime", suite.testUserID, suite.deviceID, mock.AnythingOfType("time.Time")).Return(nil)

	// Execute
	response, err := suite.syncService.Sync(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.True(suite.T(), response.Success)
	assert.Equal(suite.T(), changedEntities, response.Entities)
	assert.Empty(suite.T(), response.Conflicts)
}

func (suite *SyncServiceTestSuite) TestSync_FirstSync() {
	entities := []services.SyncEntity{}

	req := services.SyncRequest{
		DeviceID:     suite.deviceID,
		LastSyncTime: nil, // First sync
		Entities:     entities,
	}

	changedEntities := []services.SyncEntity{}

	// Mock expectations
	suite.mockRepo.On("GetLastSyncTime", suite.testUserID, suite.deviceID).Return(nil, models.ErrSyncNotFound)
	suite.mockRepo.On("ApplyChanges", suite.testUserID, entities).Return([]services.SyncConflict{}, nil)
	suite.mockRepo.On("GetChangedEntities", suite.testUserID, mock.AnythingOfType("time.Time"), mock.AnythingOfType("[]string")).Return(changedEntities, nil)
	suite.mockRepo.On("UpdateSyncTime", suite.testUserID, suite.deviceID, mock.AnythingOfType("time.Time")).Return(nil)

	// Execute
	response, err := suite.syncService.Sync(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.True(suite.T(), response.Success)
}

func (suite *SyncServiceTestSuite) TestSync_WithConflicts() {
	lastSyncTime := time.Now().Add(-1 * time.Hour)
	entities := []services.SyncEntity{
		{
			EntityType: "task",
			EntityID:   uuid.New().String(),
			Action:     "update",
			Data:       []byte(`{"title": "Updated Task"}`),
			UpdatedAt:  time.Now(),
		},
	}

	req := services.SyncRequest{
		DeviceID:     suite.deviceID,
		LastSyncTime: &lastSyncTime,
		Entities:     entities,
	}

	conflicts := []services.SyncConflict{
		{
			EntityType:        "task",
			EntityID:          entities[0].EntityID,
			LocalData:         entities[0].Data,
			RemoteData:        []byte(`{"title": "Different Update"}`),
			LocalUpdatedAt:    entities[0].UpdatedAt,
			RemoteUpdatedAt:   time.Now().Add(1 * time.Minute),
			Resolution:        "remote_wins",
		},
	}

	// Mock expectations
	suite.mockRepo.On("GetLastSyncTime", suite.testUserID, suite.deviceID).Return(&lastSyncTime, nil)
	suite.mockRepo.On("ApplyChanges", suite.testUserID, entities).Return(conflicts, nil)
	suite.mockRepo.On("GetChangedEntities", suite.testUserID, lastSyncTime, mock.AnythingOfType("[]string")).Return([]services.SyncEntity{}, nil)
	suite.mockRepo.On("UpdateSyncTime", suite.testUserID, suite.deviceID, mock.AnythingOfType("time.Time")).Return(nil)

	// Execute
	response, err := suite.syncService.Sync(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.True(suite.T(), response.Success)
	assert.Equal(suite.T(), conflicts, response.Conflicts)
}

func (suite *SyncServiceTestSuite) TestGetSyncStatus_Success() {
	lastSyncTime := time.Now().Add(-30 * time.Minute)

	// Mock expectations
	suite.mockRepo.On("GetLastSyncTime", suite.testUserID, suite.deviceID).Return(&lastSyncTime, nil)

	// Execute
	status, err := suite.syncService.GetSyncStatus(suite.testUserID, suite.deviceID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), status)
	assert.Equal(suite.T(), &lastSyncTime, status.LastSyncTime)
	assert.False(suite.T(), status.HasPendingChanges) // Assuming no changes for this test
}

func (suite *SyncServiceTestSuite) TestGetSyncStatus_NeverSynced() {
	// Mock expectations
	suite.mockRepo.On("GetLastSyncTime", suite.testUserID, suite.deviceID).Return(nil, models.ErrSyncNotFound)

	// Execute
	status, err := suite.syncService.GetSyncStatus(suite.testUserID, suite.deviceID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), status)
	assert.Nil(suite.T(), status.LastSyncTime)
	assert.False(suite.T(), status.HasPendingChanges)
}

// Run all test suites
func TestReportServiceSuite(t *testing.T) {
	suite.Run(t, new(ReportServiceTestSuite))
}

func TestNotificationServiceSuite(t *testing.T) {
	suite.Run(t, new(NotificationServiceTestSuite))
}

func TestSyncServiceSuite(t *testing.T) {
	suite.Run(t, new(SyncServiceTestSuite))
}

// Additional edge case tests
func TestRemainingServices_EdgeCases(t *testing.T) {
	t.Run("ReportService_DatabaseError", func(t *testing.T) {
		mockRepo := new(MockReportRepository)
		reportService := services.NewReportService(mockRepo)
		userID := uuid.New()

		req := services.GenerateReportRequest{
			ReportType: models.ReportTypeDaily,
			StartDate:  time.Now().AddDate(0, 0, -1),
			EndDate:    time.Now(),
		}

		mockRepo.On("Create", mock.AnythingOfType("*models.Report")).Return(nil, errors.New("database error"))

		result, err := reportService.GenerateReport(userID, req)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to create report")

		mockRepo.AssertExpectations(t)
	})

	t.Run("NotificationService_SendPushNotification", func(t *testing.T) {
		mockRepo := new(MockNotificationRepository)
		notificationService := services.NewNotificationService(mockRepo)
		userID := uuid.New()

		deviceToken := "test-device-token"
		title := "Push Test"
		message := "Push notification test"

		// Mock expectations - assuming push notification succeeds
		err := notificationService.SendPushNotification(userID, deviceToken, title, message)

		// For now, this should return no error (implementation may vary)
		assert.NoError(t, err)

		mockRepo.AssertExpectations(t)
	})

	t.Run("SyncService_ResolveConflict", func(t *testing.T) {
		mockRepo := new(MockSyncRepository)
		syncService := services.NewSyncService(mockRepo)

		conflict := services.SyncConflict{
			EntityType:        "task",
			EntityID:          uuid.New().String(),
			LocalData:         []byte(`{"title": "Local"}`),
			RemoteData:        []byte(`{"title": "Remote"}`),
			LocalUpdatedAt:    time.Now().Add(-1 * time.Minute),
			RemoteUpdatedAt:   time.Now(),
			Resolution:        "",
		}

		resolvedConflict := syncService.ResolveConflict(conflict, "remote_wins")
		assert.Equal(t, "remote_wins", resolvedConflict.Resolution)
		assert.Equal(t, conflict.RemoteData, resolvedConflict.ResolvedData)

		mockRepo.AssertExpectations(t)
	})
}