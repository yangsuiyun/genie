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

// MockTaskRepository is a mock implementation of TaskRepository
type MockTaskRepository struct {
	mock.Mock
}

func (m *MockTaskRepository) Create(task *models.Task) (*models.Task, error) {
	args := m.Called(task)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetByID(id uuid.UUID) (*models.Task, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetByUserID(userID uuid.UUID, filter models.TaskFilter) ([]*models.Task, int, error) {
	args := m.Called(userID, filter)
	return args.Get(0).([]*models.Task), args.Int(1), args.Error(2)
}

func (m *MockTaskRepository) Update(task *models.Task) (*models.Task, error) {
	args := m.Called(task)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Task), args.Error(1)
}

func (m *MockTaskRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockTaskRepository) SoftDelete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockTaskRepository) GetSubtasks(parentID uuid.UUID) ([]*models.Task, error) {
	args := m.Called(parentID)
	return args.Get(0).([]*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetTaskStats(userID uuid.UUID) (*models.TaskStats, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.TaskStats), args.Error(1)
}

func (m *MockTaskRepository) BulkUpdate(tasks []*models.Task) error {
	args := m.Called(tasks)
	return args.Error(0)
}

func (m *MockTaskRepository) SearchTasks(userID uuid.UUID, query string, limit int) ([]*models.Task, error) {
	args := m.Called(userID, query, limit)
	return args.Get(0).([]*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetOverdueTasks(userID uuid.UUID) ([]*models.Task, error) {
	args := m.Called(userID)
	return args.Get(0).([]*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetTasksDueToday(userID uuid.UUID) ([]*models.Task, error) {
	args := m.Called(userID)
	return args.Get(0).([]*models.Task), args.Error(1)
}

func (m *MockTaskRepository) GetTasksDueThisWeek(userID uuid.UUID) ([]*models.Task, error) {
	args := m.Called(userID)
	return args.Get(0).([]*models.Task), args.Error(1)
}

// TaskServiceTestSuite defines the test suite for TaskService
type TaskServiceTestSuite struct {
	suite.Suite
	taskService *services.TaskService
	mockRepo    *MockTaskRepository
	testUserID  uuid.UUID
	testTask    *models.Task
}

func (suite *TaskServiceTestSuite) SetupTest() {
	suite.mockRepo = new(MockTaskRepository)
	suite.taskService = services.NewTaskService(suite.mockRepo)
	suite.testUserID = uuid.New()

	// Set up a test task
	suite.testTask = &models.Task{
		ID:                 uuid.New(),
		UserID:             suite.testUserID,
		Title:              "Test Task",
		Description:        "Test Description",
		Priority:           models.PriorityMedium,
		Status:             models.StatusPending,
		EstimatedPomodoros: 3,
		CompletedPomodoros: 0,
		Tags:               []string{"work", "important"},
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}
}

func (suite *TaskServiceTestSuite) TearDownTest() {
	suite.mockRepo.AssertExpectations(suite.T())
}

// Test Create method
func (suite *TaskServiceTestSuite) TestCreate_Success() {
	req := services.CreateTaskRequest{
		Title:              "New Task",
		Description:        "Task description",
		Priority:           models.PriorityHigh,
		EstimatedPomodoros: 2,
		Tags:               []string{"test"},
	}

	expectedTask := &models.Task{
		ID:                 uuid.New(),
		UserID:             suite.testUserID,
		Title:              req.Title,
		Description:        req.Description,
		Priority:           req.Priority,
		Status:             models.StatusPending,
		EstimatedPomodoros: req.EstimatedPomodoros,
		Tags:               req.Tags,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	// Mock expectations
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.Task")).Return(expectedTask, nil)

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), createdTask)
	assert.Equal(suite.T(), req.Title, createdTask.Title)
	assert.Equal(suite.T(), req.Description, createdTask.Description)
	assert.Equal(suite.T(), req.Priority, createdTask.Priority)
}

func (suite *TaskServiceTestSuite) TestCreate_EmptyTitle() {
	req := services.CreateTaskRequest{
		Title: "", // Empty title should fail
	}

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrTaskTitleRequired, err)
}

func (suite *TaskServiceTestSuite) TestCreate_TitleTooLong() {
	req := services.CreateTaskRequest{
		Title: string(make([]byte, 201)), // Title too long
	}

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrTaskTitleTooLong, err)
}

func (suite *TaskServiceTestSuite) TestCreate_DescriptionTooLong() {
	req := services.CreateTaskRequest{
		Title:       "Valid Title",
		Description: string(make([]byte, 2001)), // Description too long
	}

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrTaskDescriptionTooLong, err)
}

func (suite *TaskServiceTestSuite) TestCreate_InvalidDueDate() {
	pastDate := time.Now().Add(-1 * time.Hour)
	req := services.CreateTaskRequest{
		Title:   "Valid Title",
		DueDate: &pastDate, // Past date should fail
	}

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrInvalidDueDate, err)
}

func (suite *TaskServiceTestSuite) TestCreate_WithParentTask() {
	parentTaskID := uuid.New()
	parentTask := &models.Task{
		ID:     parentTaskID,
		UserID: suite.testUserID,
		Title:  "Parent Task",
	}

	req := services.CreateTaskRequest{
		Title:        "Subtask",
		ParentTaskID: &parentTaskID,
	}

	expectedTask := &models.Task{
		ID:           uuid.New(),
		UserID:       suite.testUserID,
		Title:        req.Title,
		ParentTaskID: &parentTaskID,
		Status:       models.StatusPending,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	// Mock expectations
	suite.mockRepo.On("GetByID", parentTaskID).Return(parentTask, nil)
	suite.mockRepo.On("Create", mock.AnythingOfType("*models.Task")).Return(expectedTask, nil)

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), createdTask)
	assert.Equal(suite.T(), &parentTaskID, createdTask.ParentTaskID)
}

func (suite *TaskServiceTestSuite) TestCreate_ParentTaskNotFound() {
	parentTaskID := uuid.New()
	req := services.CreateTaskRequest{
		Title:        "Subtask",
		ParentTaskID: &parentTaskID,
	}

	// Mock expectations
	suite.mockRepo.On("GetByID", parentTaskID).Return(nil, models.ErrTaskNotFound)

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrTaskNotFound, err)
}

func (suite *TaskServiceTestSuite) TestCreate_ParentTaskNotOwned() {
	parentTaskID := uuid.New()
	differentUserID := uuid.New()
	parentTask := &models.Task{
		ID:     parentTaskID,
		UserID: differentUserID, // Different user owns the parent
		Title:  "Parent Task",
	}

	req := services.CreateTaskRequest{
		Title:        "Subtask",
		ParentTaskID: &parentTaskID,
	}

	// Mock expectations
	suite.mockRepo.On("GetByID", parentTaskID).Return(parentTask, nil)

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

func (suite *TaskServiceTestSuite) TestCreate_SubtaskDepthLimit() {
	grandparentTaskID := uuid.New()
	parentTaskID := uuid.New()
	parentTask := &models.Task{
		ID:           parentTaskID,
		UserID:       suite.testUserID,
		Title:        "Parent Task",
		ParentTaskID: &grandparentTaskID, // Already a subtask
	}

	req := services.CreateTaskRequest{
		Title:        "Sub-subtask",
		ParentTaskID: &parentTaskID,
	}

	// Mock expectations
	suite.mockRepo.On("GetByID", parentTaskID).Return(parentTask, nil)

	// Execute
	createdTask, err := suite.taskService.Create(suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), createdTask)
	assert.Equal(suite.T(), models.ErrSubtaskDepthLimit, err)
}

// Test GetByID method
func (suite *TaskServiceTestSuite) TestGetByID_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)

	// Execute
	task, err := suite.taskService.GetByID(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), task)
	assert.Equal(suite.T(), suite.testTask.ID, task.ID)
	assert.Equal(suite.T(), suite.testTask.Title, task.Title)
}

func (suite *TaskServiceTestSuite) TestGetByID_InvalidUUID() {
	// Execute
	task, err := suite.taskService.GetByID("invalid-uuid", suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), task)
	assert.Contains(suite.T(), err.Error(), "invalid task ID format")
}

func (suite *TaskServiceTestSuite) TestGetByID_TaskNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(nil, models.ErrTaskNotFound)

	// Execute
	task, err := suite.taskService.GetByID(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), task)
	assert.Equal(suite.T(), models.ErrTaskNotFound, err)
}

func (suite *TaskServiceTestSuite) TestGetByID_TaskNotOwned() {
	differentUserID := uuid.New()
	taskOwnedByDifferentUser := *suite.testTask
	taskOwnedByDifferentUser.UserID = differentUserID

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(&taskOwnedByDifferentUser, nil)

	// Execute
	task, err := suite.taskService.GetByID(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), task)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

// Test Update method
func (suite *TaskServiceTestSuite) TestUpdate_Success() {
	newTitle := "Updated Task Title"
	newDescription := "Updated description"
	newPriority := models.PriorityHigh

	req := services.UpdateTaskRequest{
		Title:       &newTitle,
		Description: &newDescription,
		Priority:    &newPriority,
	}

	updatedTask := *suite.testTask
	updatedTask.Title = newTitle
	updatedTask.Description = newDescription
	updatedTask.Priority = newPriority
	updatedTask.UpdatedAt = time.Now()

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.Task")).Return(&updatedTask, nil)

	// Execute
	result, err := suite.taskService.Update(suite.testTask.ID.String(), suite.testUserID, req)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), newTitle, result.Title)
	assert.Equal(suite.T(), newDescription, result.Description)
	assert.Equal(suite.T(), newPriority, result.Priority)
}

func (suite *TaskServiceTestSuite) TestUpdate_TaskNotFound() {
	req := services.UpdateTaskRequest{}

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(nil, models.ErrTaskNotFound)

	// Execute
	result, err := suite.taskService.Update(suite.testTask.ID.String(), suite.testUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrTaskNotFound, err)
}

func (suite *TaskServiceTestSuite) TestUpdate_TaskNotOwned() {
	differentUserID := uuid.New()
	req := services.UpdateTaskRequest{}

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)

	// Execute
	result, err := suite.taskService.Update(suite.testTask.ID.String(), differentUserID, req)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

// Test Complete method
func (suite *TaskServiceTestSuite) TestComplete_Success() {
	completedTask := *suite.testTask
	completedTask.Status = models.StatusCompleted
	completedTask.CompletedAt = time.Now()
	completedTask.UpdatedAt = time.Now()

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)
	suite.mockRepo.On("Update", mock.AnythingOfType("*models.Task")).Return(&completedTask, nil)

	// Execute
	result, err := suite.taskService.Complete(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), models.StatusCompleted, result.Status)
	assert.NotNil(suite.T(), result.CompletedAt)
}

func (suite *TaskServiceTestSuite) TestComplete_AlreadyCompleted() {
	completedTask := *suite.testTask
	completedTask.Status = models.StatusCompleted
	completedAt := time.Now().Add(-1 * time.Hour)
	completedTask.CompletedAt = completedAt

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(&completedTask, nil)

	// Execute
	result, err := suite.taskService.Complete(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), models.ErrTaskAlreadyCompleted, err)
}

// Test Delete method
func (suite *TaskServiceTestSuite) TestDelete_Success() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)
	suite.mockRepo.On("SoftDelete", suite.testTask.ID).Return(nil)

	// Execute
	err := suite.taskService.Delete(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
}

func (suite *TaskServiceTestSuite) TestDelete_TaskNotFound() {
	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(nil, models.ErrTaskNotFound)

	// Execute
	err := suite.taskService.Delete(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Equal(suite.T(), models.ErrTaskNotFound, err)
}

func (suite *TaskServiceTestSuite) TestDelete_TaskNotOwned() {
	differentUserID := uuid.New()

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)

	// Execute
	err := suite.taskService.Delete(suite.testTask.ID.String(), differentUserID)

	// Assert
	assert.Error(suite.T(), err)
	assert.Equal(suite.T(), models.ErrResourceNotOwned, err)
}

// Test List method
func (suite *TaskServiceTestSuite) TestList_Success() {
	tasks := []*models.Task{suite.testTask}
	filter := models.TaskFilter{
		Status:   models.StatusPending,
		Priority: models.PriorityMedium,
		Limit:    10,
		Offset:   0,
	}

	// Mock expectations
	suite.mockRepo.On("GetByUserID", suite.testUserID, mock.AnythingOfType("models.TaskFilter")).Return(tasks, 1, nil)

	// Execute
	response, err := suite.taskService.List(suite.testUserID, filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.Equal(suite.T(), tasks, response.Tasks)
	assert.Equal(suite.T(), 1, response.Total)
	assert.Equal(suite.T(), 1, response.Page)
	assert.Equal(suite.T(), 10, response.PerPage)
	assert.Equal(suite.T(), 1, response.TotalPages)
}

func (suite *TaskServiceTestSuite) TestList_EmptyResult() {
	tasks := []*models.Task{}
	filter := models.TaskFilter{
		Limit:  10,
		Offset: 0,
	}

	// Mock expectations
	suite.mockRepo.On("GetByUserID", suite.testUserID, mock.AnythingOfType("models.TaskFilter")).Return(tasks, 0, nil)

	// Execute
	response, err := suite.taskService.List(suite.testUserID, filter)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.Empty(suite.T(), response.Tasks)
	assert.Equal(suite.T(), 0, response.Total)
}

// Test GetSubtasks method
func (suite *TaskServiceTestSuite) TestGetSubtasks_Success() {
	subtask1 := &models.Task{
		ID:           uuid.New(),
		UserID:       suite.testUserID,
		Title:        "Subtask 1",
		ParentTaskID: &suite.testTask.ID,
	}

	subtask2 := &models.Task{
		ID:           uuid.New(),
		UserID:       suite.testUserID,
		Title:        "Subtask 2",
		ParentTaskID: &suite.testTask.ID,
	}

	subtasks := []*models.Task{subtask1, subtask2}

	// Mock expectations
	suite.mockRepo.On("GetByID", suite.testTask.ID).Return(suite.testTask, nil)
	suite.mockRepo.On("GetSubtasks", suite.testTask.ID).Return(subtasks, nil)

	// Execute
	result, err := suite.taskService.GetSubtasks(suite.testTask.ID.String(), suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Len(suite.T(), result, 2)
	assert.Equal(suite.T(), subtasks, result)
}

// Test SearchTasks method
func (suite *TaskServiceTestSuite) TestSearchTasks_Success() {
	tasks := []*models.Task{suite.testTask}
	query := "test"
	limit := 10

	// Mock expectations
	suite.mockRepo.On("SearchTasks", suite.testUserID, query, limit).Return(tasks, nil)

	// Execute
	result, err := suite.taskService.SearchTasks(suite.testUserID, query, limit)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), tasks, result)
}

func (suite *TaskServiceTestSuite) TestSearchTasks_EmptyQuery() {
	// Execute
	result, err := suite.taskService.SearchTasks(suite.testUserID, "", 10)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Empty(suite.T(), result)
}

// Test GetOverdueTasks method
func (suite *TaskServiceTestSuite) TestGetOverdueTasks_Success() {
	overdueTasks := []*models.Task{suite.testTask}

	// Mock expectations
	suite.mockRepo.On("GetOverdueTasks", suite.testUserID).Return(overdueTasks, nil)

	// Execute
	result, err := suite.taskService.GetOverdueTasks(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), overdueTasks, result)
}

// Test GetTaskStats method
func (suite *TaskServiceTestSuite) TestGetTaskStats_Success() {
	stats := &models.TaskStats{
		TotalTasks:     10,
		CompletedTasks: 7,
		PendingTasks:   3,
		OverdueTasks:   1,
	}

	// Mock expectations
	suite.mockRepo.On("GetTaskStats", suite.testUserID).Return(stats, nil)

	// Execute
	result, err := suite.taskService.GetTaskStats(suite.testUserID)

	// Assert
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), stats, result)
}

// Run the test suite
func TestTaskServiceSuite(t *testing.T) {
	suite.Run(t, new(TaskServiceTestSuite))
}

// Additional individual tests for edge cases
func TestTaskService_EdgeCases(t *testing.T) {
	mockRepo := new(MockTaskRepository)
	taskService := services.NewTaskService(mockRepo)
	userID := uuid.New()

	t.Run("Create_DatabaseError", func(t *testing.T) {
		req := services.CreateTaskRequest{
			Title: "Test Task",
		}

		mockRepo.On("Create", mock.AnythingOfType("*models.Task")).Return(nil, errors.New("database error"))

		result, err := taskService.Create(userID, req)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to create task")

		mockRepo.AssertExpectations(t)
	})

	t.Run("Update_DatabaseError", func(t *testing.T) {
		taskID := uuid.New()
		testTask := &models.Task{
			ID:     taskID,
			UserID: userID,
			Title:  "Test Task",
		}

		req := services.UpdateTaskRequest{
			Title: func(s string) *string { return &s }("Updated Title"),
		}

		mockRepo.On("GetByID", taskID).Return(testTask, nil)
		mockRepo.On("Update", mock.AnythingOfType("*models.Task")).Return(nil, errors.New("database error"))

		result, err := taskService.Update(taskID.String(), userID, req)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "failed to update task")

		mockRepo.AssertExpectations(t)
	})

	t.Run("GetTasksDueToday_Success", func(t *testing.T) {
		tasks := []*models.Task{}

		mockRepo.On("GetTasksDueToday", userID).Return(tasks, nil)

		result, err := taskService.GetTasksDueToday(userID)
		assert.NoError(t, err)
		assert.Equal(t, tasks, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("GetTasksDueThisWeek_Success", func(t *testing.T) {
		tasks := []*models.Task{}

		mockRepo.On("GetTasksDueThisWeek", userID).Return(tasks, nil)

		result, err := taskService.GetTasksDueThisWeek(userID)
		assert.NoError(t, err)
		assert.Equal(t, tasks, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("BulkUpdate_Success", func(t *testing.T) {
		tasks := []*models.Task{}

		mockRepo.On("BulkUpdate", tasks).Return(nil)

		err := taskService.BulkUpdate(tasks)
		assert.NoError(t, err)

		mockRepo.AssertExpectations(t)
	})
}