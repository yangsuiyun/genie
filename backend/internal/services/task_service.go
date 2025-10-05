package services

import (
	"fmt"
	"sync"
	"time"

	"pomodoro-backend/internal/models"
)

// TaskService handles task management operations
type TaskService struct {
	tasks    map[string]*models.Task // taskID -> task
	userTasks map[string][]string    // userID -> []taskID
	mutex    sync.RWMutex
}

// NewTaskService creates a new task service
func NewTaskService() *TaskService {
	return &TaskService{
		tasks:     make(map[string]*models.Task),
		userTasks: make(map[string][]string),
	}
}

// CreateTask creates a new task for a user
func (s *TaskService) CreateTask(userID string, req models.TaskCreateRequest) (*models.Task, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	// Generate task ID
	taskID, err := generateID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate task ID: %w", err)
	}

	// Set default priority if not specified
	priority := req.Priority
	if priority == "" {
		priority = "medium"
	}

	// Create task
	task := &models.Task{
		ID:          taskID,
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
		Priority:    priority,
		Status:      "pending",
		DueDate:     req.DueDate,
		Tags:        req.Tags,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
		Subtasks:    []models.Subtask{},
	}

	// Store task
	s.tasks[taskID] = task
	s.userTasks[userID] = append(s.userTasks[userID], taskID)

	return task, nil
}

// GetTask retrieves a task by ID
func (s *TaskService) GetTask(taskID, userID string) (*models.Task, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	task, exists := s.tasks[taskID]
	if !exists {
		return nil, fmt.Errorf("task not found")
	}

	// Verify ownership
	if task.UserID != userID {
		return nil, fmt.Errorf("access denied")
	}

	return task, nil
}

// GetUserTasks retrieves all tasks for a user
func (s *TaskService) GetUserTasks(userID string, status string) ([]*models.Task, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	taskIDs, exists := s.userTasks[userID]
	if !exists {
		return []*models.Task{}, nil
	}

	var tasks []*models.Task
	for _, taskID := range taskIDs {
		task, exists := s.tasks[taskID]
		if !exists {
			continue
		}

		// Filter by status if specified
		if status != "" && task.Status != status {
			continue
		}

		tasks = append(tasks, task)
	}

	return tasks, nil
}

// UpdateTask updates an existing task
func (s *TaskService) UpdateTask(taskID, userID string, req models.TaskUpdateRequest) (*models.Task, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	task, exists := s.tasks[taskID]
	if !exists {
		return nil, fmt.Errorf("task not found")
	}

	// Verify ownership
	if task.UserID != userID {
		return nil, fmt.Errorf("access denied")
	}

	// Update fields
	if req.Title != nil {
		task.Title = *req.Title
	}
	if req.Description != nil {
		task.Description = *req.Description
	}
	if req.Priority != nil {
		task.Priority = *req.Priority
	}
	if req.Status != nil {
		task.Status = *req.Status
	}
	if req.DueDate != nil {
		task.DueDate = req.DueDate
	}
	if req.Tags != nil {
		task.Tags = req.Tags
	}

	task.UpdatedAt = time.Now()

	return task, nil
}

// DeleteTask deletes a task
func (s *TaskService) DeleteTask(taskID, userID string) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	task, exists := s.tasks[taskID]
	if !exists {
		return fmt.Errorf("task not found")
	}

	// Verify ownership
	if task.UserID != userID {
		return fmt.Errorf("access denied")
	}

	// Remove from tasks map
	delete(s.tasks, taskID)

	// Remove from user's task list
	taskIDs := s.userTasks[userID]
	for i, id := range taskIDs {
		if id == taskID {
			s.userTasks[userID] = append(taskIDs[:i], taskIDs[i+1:]...)
			break
		}
	}

	return nil
}

// AddSubtask adds a subtask to an existing task
func (s *TaskService) AddSubtask(taskID, userID, title string) (*models.Subtask, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	task, exists := s.tasks[taskID]
	if !exists {
		return nil, fmt.Errorf("task not found")
	}

	// Verify ownership
	if task.UserID != userID {
		return nil, fmt.Errorf("access denied")
	}

	// Generate subtask ID
	subtaskID, err := generateID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate subtask ID: %w", err)
	}

	// Create subtask
	subtask := models.Subtask{
		ID:        subtaskID,
		TaskID:    taskID,
		Title:     title,
		Completed: false,
		CreatedAt: time.Now(),
	}

	// Add to task
	task.Subtasks = append(task.Subtasks, subtask)
	task.UpdatedAt = time.Now()

	return &subtask, nil
}

// UpdateSubtask updates a subtask
func (s *TaskService) UpdateSubtask(taskID, subtaskID, userID string, completed bool) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	task, exists := s.tasks[taskID]
	if !exists {
		return fmt.Errorf("task not found")
	}

	// Verify ownership
	if task.UserID != userID {
		return fmt.Errorf("access denied")
	}

	// Find and update subtask
	for i, subtask := range task.Subtasks {
		if subtask.ID == subtaskID {
			task.Subtasks[i].Completed = completed
			task.UpdatedAt = time.Now()
			return nil
		}
	}

	return fmt.Errorf("subtask not found")
}

// GetTaskStatistics returns task statistics for a user
func (s *TaskService) GetTaskStatistics(userID string) (map[string]interface{}, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	taskIDs, exists := s.userTasks[userID]
	if !exists {
		return map[string]interface{}{
			"total":      0,
			"pending":    0,
			"completed":  0,
			"in_progress": 0,
		}, nil
	}

	stats := map[string]int{
		"total":      0,
		"pending":    0,
		"completed":  0,
		"in_progress": 0,
		"overdue":    0,
	}

	now := time.Now()
	for _, taskID := range taskIDs {
		task, exists := s.tasks[taskID]
		if !exists {
			continue
		}

		stats["total"]++
		stats[task.Status]++

		// Check if overdue
		if task.DueDate != nil && task.DueDate.Before(now) && task.Status != "completed" {
			stats["overdue"]++
		}
	}

	// Convert to interface{}
	result := make(map[string]interface{})
	for k, v := range stats {
		result[k] = v
	}

	return result, nil
}