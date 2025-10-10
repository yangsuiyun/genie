package unit

import (
	"fmt"
	"regexp"
	"time"

	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
)

// TestHelpers provides utility functions for tests

// CreateTestUser creates a test user with default values
func CreateTestUser() *models.User {
	return &models.User{
		ID:           uuid.New(),
		Email:        "test@example.com",
		PasswordHash: "hashed-password",
		IsVerified:   true,
		Preferences:  models.DefaultUserPreferences(),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
}

// CreateTestTask creates a test task with default values
func CreateTestTask(userID uuid.UUID) *models.Task {
	return &models.Task{
		ID:                 uuid.New(),
		UserID:             userID,
		Title:              "Test Task",
		Description:        "Test Description",
		Priority:           models.PriorityMedium,
		Status:             models.TaskStatusPending,
		EstimatedPomodoros: 3,
		CompletedPomodoros: 0,
		Tags:               []string{"test", "important"},
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}
}

// CreateTestPomodoroSession creates a test pomodoro session
func CreateTestPomodoroSession(userID, taskID uuid.UUID) *models.PomodoroSession {
	return &models.PomodoroSession{
		ID:              uuid.New(),
		UserID:          userID,
		TaskID:          taskID,
		SessionType:     models.SessionTypeWork,
		Status:          models.PomodoroStatusActive,
		PlannedDuration: 25 * 60, // 25 minutes
		ActualDuration:  0,
		StartedAt:       time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}
}

// CreateTestReport creates a test report
func CreateTestReport(userID uuid.UUID) *models.Report {
	return &models.Report{
		ID:         uuid.New(),
		UserID:     userID,
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

// CreateTestNotification creates a test notification
func CreateTestNotification(userID uuid.UUID) *models.Notification {
	return &models.Notification{
		ID:      uuid.New(),
		UserID:  userID,
		Type:    models.NotificationTypeTaskReminder,
		Title:   "Test Notification",
		Message: "This is a test notification",
		IsRead:  false,
		CreatedAt: time.Now(),
	}
}

// AssertTimeAlmostEqual checks if two times are within a reasonable delta
func AssertTimeAlmostEqual(t1, t2 time.Time, delta time.Duration) bool {
	diff := t1.Sub(t2)
	if diff < 0 {
		diff = -diff
	}
	return diff <= delta
}

// StringPtr returns a pointer to a string (helper for optional fields)
func StringPtr(s string) *string {
	return &s
}

// IntPtr returns a pointer to an int (helper for optional fields)
func IntPtr(i int) *int {
	return &i
}

// BoolPtr returns a pointer to a bool (helper for optional fields)
func BoolPtr(b bool) *bool {
	return &b
}

// TimePtr returns a pointer to a time (helper for optional fields)
func TimePtr(t time.Time) *time.Time {
	return &t
}

// UUIDPtr returns a pointer to a UUID (helper for optional fields)
func UUIDPtr(id uuid.UUID) *uuid.UUID {
	return &id
}

// MockDataHelpers provides consistent test data

// GetValidPasswords returns a list of valid passwords for testing
func GetValidPasswords() []string {
	return []string{
		"StrongPassword123!",
		"AnotherValid1@",
		"Test123Password#",
		"Secure2023$",
	}
}

// GetInvalidPasswords returns a list of invalid passwords for testing
func GetInvalidPasswords() []string {
	return []string{
		"weak",           // too short
		"password123",    // no uppercase
		"PASSWORD123",    // no lowercase
		"StrongPassword", // no number
		"StrongPass123",  // no special char
		"",               // empty
	}
}

// GetValidEmails returns a list of valid emails for testing
func GetValidEmails() []string {
	return []string{
		"test@example.com",
		"user.name@domain.co.uk",
		"test+tag@gmail.com",
		"valid_email@subdomain.example.org",
	}
}

// GetInvalidEmails returns a list of invalid emails for testing
func GetInvalidEmails() []string {
	return []string{
		"invalid",
		"@example.com",
		"test@",
		"test.example.com",
		"test@.com",
		"",
	}
}

// TestConstants provides constants used across tests
const (
	TestTimeout     = 5 * time.Second
	DefaultPageSize = 20
	MaxPageSize     = 100
	TestDeviceID    = "test-device-123"
)

// Test data generators

// GenerateTestTasks creates multiple test tasks
func GenerateTestTasks(userID uuid.UUID, count int) []*models.Task {
	tasks := make([]*models.Task, count)
	for i := 0; i < count; i++ {
		task := CreateTestTask(userID)
		task.Title = fmt.Sprintf("Test Task %d", i+1)
		tasks[i] = task
	}
	return tasks
}

// GenerateTestSessions creates multiple test pomodoro sessions
func GenerateTestSessions(userID, taskID uuid.UUID, count int) []*models.PomodoroSession {
	sessions := make([]*models.PomodoroSession, count)
	for i := 0; i < count; i++ {
		session := CreateTestPomodoroSession(userID, taskID)
		// Vary the session types
		switch i % 3 {
		case 0:
			session.SessionType = models.SessionTypeWork
		case 1:
			session.SessionType = models.SessionTypeShortBreak
		case 2:
			session.SessionType = models.SessionTypeLongBreak
		}
		sessions[i] = session
	}
	return sessions
}

// Error helpers

// IsExpectedError checks if an error matches the expected error
func IsExpectedError(err, expected error) bool {
	if err == nil && expected == nil {
		return true
	}
	if err == nil || expected == nil {
		return false
	}
	return err.Error() == expected.Error()
}

// ValidationHelpers

// ValidateUUID checks if a string is a valid UUID
func ValidateUUID(s string) bool {
	_, err := uuid.Parse(s)
	return err == nil
}

// ValidateEmail performs basic email validation
func ValidateEmail(email string) bool {
	// Simple regex for basic email validation
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// ValidatePassword checks if a password meets basic requirements
func ValidatePassword(password string) bool {
	if len(password) < 8 || len(password) > 128 {
		return false
	}

	hasUpper := false
	hasLower := false
	hasDigit := false
	hasSpecial := false

	for _, char := range password {
		switch {
		case char >= 'A' && char <= 'Z':
			hasUpper = true
		case char >= 'a' && char <= 'z':
			hasLower = true
		case char >= '0' && char <= '9':
			hasDigit = true
		default:
			// Consider any non-alphanumeric as special
			if !((char >= 'A' && char <= 'Z') || (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9')) {
				hasSpecial = true
			}
		}
	}

	return hasUpper && hasLower && hasDigit && hasSpecial
}