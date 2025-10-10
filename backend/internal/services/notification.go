package services

import (
	"context"
	"fmt"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"

	"pomodoro-backend/internal/models"
)

// NotificationRepository defines the interface for notification data access
type NotificationRepository interface {
	StoreNotification(notification *StoredNotification) error
	GetUserNotifications(userID uuid.UUID, limit, offset int) ([]*StoredNotification, error)
	MarkAsRead(notificationID uuid.UUID) error
	MarkAllAsRead(userID uuid.UUID) error
	GetUnreadCount(userID uuid.UUID) (int, error)
	DeleteNotification(notificationID uuid.UUID) error
	GetScheduledNotifications(before time.Time) ([]*ScheduledNotification, error)
	StoreScheduledNotification(notification *ScheduledNotification) error
	DeleteScheduledNotification(id uuid.UUID) error
}

// NotificationService handles push notifications and reminders
type NotificationService struct {
	repo         NotificationRepository
	fcmClient    *messaging.Client
	scheduler    NotificationScheduler
	userService  *UserService
}

// StoredNotification represents a notification stored in the database
type StoredNotification struct {
	ID          uuid.UUID            `json:"id"`
	UserID      uuid.UUID            `json:"user_id"`
	Type        NotificationType     `json:"type"`
	Title       string               `json:"title"`
	Body        string               `json:"body"`
	Data        map[string]string    `json:"data"`
	IsRead      bool                 `json:"is_read"`
	CreatedAt   time.Time            `json:"created_at"`
	ReadAt      *time.Time           `json:"read_at,omitempty"`
	Platform    string               `json:"platform"` // "fcm", "apns", "web"
	Status      NotificationStatus   `json:"status"`
}

// ScheduledNotification represents a notification scheduled for future delivery
type ScheduledNotification struct {
	ID           uuid.UUID         `json:"id"`
	UserID       uuid.UUID         `json:"user_id"`
	Type         NotificationType  `json:"type"`
	Title        string            `json:"title"`
	Body         string            `json:"body"`
	Data         map[string]string `json:"data"`
	ScheduledFor time.Time         `json:"scheduled_for"`
	Status       string            `json:"status"` // "pending", "sent", "failed"
	CreatedAt    time.Time         `json:"created_at"`
	SentAt       *time.Time        `json:"sent_at,omitempty"`
}

// NotificationType represents different types of notifications
type NotificationType string

const (
	NotificationTypeTaskReminder      NotificationType = "task_reminder"
	NotificationTypeTaskDue           NotificationType = "task_due"
	NotificationTypeTaskCompleted     NotificationType = "task_completed"
	NotificationTypeSessionComplete   NotificationType = "session_complete"
	NotificationTypeBreakReminder     NotificationType = "break_reminder"
	NotificationTypeSessionStart      NotificationType = "session_start"
	NotificationTypeDailyGoal         NotificationType = "daily_goal"
	NotificationTypeWeeklyReport      NotificationType = "weekly_report"
	NotificationTypeStreakReminder    NotificationType = "streak_reminder"
)

// NotificationStatus represents the delivery status
type NotificationStatus string

const (
	NotificationTaskStatusPending   NotificationStatus = "pending"
	NotificationStatusSent      NotificationStatus = "sent"
	NotificationStatusDelivered NotificationStatus = "delivered"
	NotificationStatusFailed    NotificationStatus = "failed"
	NotificationStatusRead      NotificationStatus = "read"
)

// NotificationRequest represents a notification to be sent
type NotificationRequest struct {
	UserID   uuid.UUID         `json:"user_id"`
	Type     NotificationType  `json:"type"`
	Title    string            `json:"title"`
	Body     string            `json:"body"`
	Data     map[string]string `json:"data"`
	Sound    string            `json:"sound,omitempty"`
	Priority string            `json:"priority,omitempty"` // "normal", "high"
}

// NotificationScheduler handles scheduled notifications
type NotificationScheduler interface {
	ScheduleNotification(notification *ScheduledNotification) error
	CancelScheduledNotification(id uuid.UUID) error
	ProcessPendingNotifications() error
}

// DeviceToken represents a user's device token for push notifications
type DeviceToken struct {
	UserID    uuid.UUID `json:"user_id"`
	Token     string    `json:"token"`
	Platform  string    `json:"platform"` // "ios", "android", "web"
	DeviceID  string    `json:"device_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	IsActive  bool      `json:"is_active"`
}

// NewNotificationService creates a new notification service
func NewNotificationService(repo NotificationRepository, fcmClient *messaging.Client) *NotificationService {
	return &NotificationService{
		repo:      repo,
		fcmClient: fcmClient,
		// scheduler will be set via dependency injection
	}
}

// SetDependencies sets dependent services
func (s *NotificationService) SetDependencies(userService *UserService, scheduler NotificationScheduler) {
	s.userService = userService
	s.scheduler = scheduler
}

// SendNotification sends an immediate notification
func (s *NotificationService) SendNotification(req NotificationRequest) error {
	// Check user notification preferences
	if s.userService != nil {
		user, err := s.userService.GetByID(req.UserID.String())
		if err != nil {
			return fmt.Errorf("failed to get user: %w", err)
		}

		// Check if notifications are enabled for this type
		if !s.isNotificationEnabled(user, req.Type) {
			return nil // Skip sending if disabled
		}
	}

	// Get user device tokens
	deviceTokens, err := s.getUserDeviceTokens(req.UserID)
	if err != nil {
		return fmt.Errorf("failed to get device tokens: %w", err)
	}

	if len(deviceTokens) == 0 {
		return fmt.Errorf("no device tokens found for user")
	}

	// Store notification in database
	storedNotification := &StoredNotification{
		ID:        uuid.New(),
		UserID:    req.UserID,
		Type:      req.Type,
		Title:     req.Title,
		Body:      req.Body,
		Data:      req.Data,
		IsRead:    false,
		CreatedAt: time.Now(),
		Status:    NotificationTaskStatusPending,
	}

	err = s.repo.StoreNotification(storedNotification)
	if err != nil {
		return fmt.Errorf("failed to store notification: %w", err)
	}

	// Send FCM notification
	err = s.sendFCMNotification(req, deviceTokens)
	if err != nil {
		// Update status to failed
		storedNotification.Status = NotificationStatusFailed
		s.repo.StoreNotification(storedNotification)
		return fmt.Errorf("failed to send FCM notification: %w", err)
	}

	// Update status to sent
	storedNotification.Status = NotificationStatusSent
	err = s.repo.StoreNotification(storedNotification)
	if err != nil {
		fmt.Printf("Warning: failed to update notification status: %v\n", err)
	}

	return nil
}

// ScheduleNotification schedules a notification for future delivery
func (s *NotificationService) ScheduleNotification(userID uuid.UUID, scheduledFor time.Time, req NotificationRequest) error {
	if scheduledFor.Before(time.Now()) {
		return fmt.Errorf("cannot schedule notification in the past")
	}

	scheduledNotification := &ScheduledNotification{
		ID:           uuid.New(),
		UserID:       userID,
		Type:         req.Type,
		Title:        req.Title,
		Body:         req.Body,
		Data:         req.Data,
		ScheduledFor: scheduledFor,
		Status:       "pending",
		CreatedAt:    time.Now(),
	}

	err := s.repo.StoreScheduledNotification(scheduledNotification)
	if err != nil {
		return fmt.Errorf("failed to store scheduled notification: %w", err)
	}

	if s.scheduler != nil {
		err = s.scheduler.ScheduleNotification(scheduledNotification)
		if err != nil {
			return fmt.Errorf("failed to schedule notification: %w", err)
		}
	}

	return nil
}

// SendTaskReminderNotification sends a task reminder notification
func (s *NotificationService) SendTaskReminderNotification(userID uuid.UUID, task *models.Task, reminderTime time.Time) error {
	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeTaskReminder,
		Title:    "Task Reminder",
		Body:     fmt.Sprintf("Don't forget: %s", task.Title),
		Data: map[string]string{
			"task_id":      task.ID.String(),
			"reminder_time": reminderTime.Format(time.RFC3339),
		},
		Priority: "normal",
	}

	return s.SendNotification(req)
}

// SendTaskDueNotification sends a task due notification
func (s *NotificationService) SendTaskDueNotification(userID uuid.UUID, task *models.Task) error {
	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeTaskDue,
		Title:    "Task Due",
		Body:     fmt.Sprintf("Task is due: %s", task.Title),
		Data: map[string]string{
			"task_id": task.ID.String(),
			"due_date": task.DueDate.Format(time.RFC3339),
		},
		Priority: "high",
	}

	return s.SendNotification(req)
}

// SendTaskCompletionNotification sends a task completion notification
func (s *NotificationService) SendTaskCompletionNotification(userID uuid.UUID, task *models.Task) error {
	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeTaskCompleted,
		Title:    "Task Completed! 🎉",
		Body:     fmt.Sprintf("Great job completing: %s", task.Title),
		Data: map[string]string{
			"task_id":      task.ID.String(),
			"completed_at": task.CompletedAt.Format(time.RFC3339),
		},
		Priority: "normal",
	}

	return s.SendNotification(req)
}

// SendSessionCompletionNotification sends a Pomodoro session completion notification
func (s *NotificationService) SendSessionCompletionNotification(userID uuid.UUID, session *models.PomodoroSession) error {
	var title, body string

	switch session.SessionType {
	case models.SessionTypeWork:
		title = "Pomodoro Complete! 🍅"
		body = "Great focus session! Time for a break."
	case models.SessionTypeShortBreak:
		title = "Break Complete"
		body = "Ready to get back to work?"
	case models.SessionTypeLongBreak:
		title = "Long Break Complete"
		body = "Refreshed and ready for the next session!"
	}

	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeSessionComplete,
		Title:    title,
		Body:     body,
		Data: map[string]string{
			"session_id":   session.ID.String(),
			"task_id":      session.TaskID.String(),
			"session_type": string(session.SessionType),
			"completed_at": session.EndedAt.Format(time.RFC3339),
		},
		Sound:    "pomodoro_complete",
		Priority: "high",
	}

	return s.SendNotification(req)
}

// ScheduleSessionCompletion schedules a notification for when a session completes
func (s *NotificationService) ScheduleSessionCompletion(userID, sessionID uuid.UUID, completionTime time.Time) error {
	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeSessionComplete,
		Title:    "Session Complete! 🍅",
		Body:     "Your Pomodoro session has finished.",
		Data: map[string]string{
			"session_id": sessionID.String(),
		},
		Sound:    "pomodoro_complete",
		Priority: "high",
	}

	return s.ScheduleNotification(userID, completionTime, req)
}

// SendDailyGoalNotification sends a daily goal achievement notification
func (s *NotificationService) SendDailyGoalNotification(userID uuid.UUID, sessionsCompleted, dailyGoal int) error {
	var title, body string

	if sessionsCompleted >= dailyGoal {
		title = "Daily Goal Achieved! 🎯"
		body = fmt.Sprintf("Congratulations! You've completed %d Pomodoros today.", sessionsCompleted)
	} else {
		remaining := dailyGoal - sessionsCompleted
		title = "Daily Goal Progress"
		body = fmt.Sprintf("You've completed %d/%d Pomodoros today. %d more to go!", sessionsCompleted, dailyGoal, remaining)
	}

	req := NotificationRequest{
		UserID:   userID,
		Type:     NotificationTypeDailyGoal,
		Title:    title,
		Body:     body,
		Data: map[string]string{
			"sessions_completed": fmt.Sprintf("%d", sessionsCompleted),
			"daily_goal":        fmt.Sprintf("%d", dailyGoal),
		},
		Priority: "normal",
	}

	return s.SendNotification(req)
}

// GetUserNotifications retrieves notifications for a user
func (s *NotificationService) GetUserNotifications(userID uuid.UUID, limit, offset int) ([]*StoredNotification, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	notifications, err := s.repo.GetUserNotifications(userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get notifications: %w", err)
	}

	return notifications, nil
}

// MarkAsRead marks a notification as read
func (s *NotificationService) MarkAsRead(notificationID uuid.UUID) error {
	return s.repo.MarkAsRead(notificationID)
}

// MarkAllAsRead marks all notifications as read for a user
func (s *NotificationService) MarkAllAsRead(userID uuid.UUID) error {
	return s.repo.MarkAllAsRead(userID)
}

// GetUnreadCount gets the count of unread notifications for a user
func (s *NotificationService) GetUnreadCount(userID uuid.UUID) (int, error) {
	return s.repo.GetUnreadCount(userID)
}

// RegisterDeviceToken registers a device token for push notifications
func (s *NotificationService) RegisterDeviceToken(userID uuid.UUID, token, platform, deviceID string) error {
	// TODO: Implement device token storage
	// This would typically involve a separate repository for device tokens
	fmt.Printf("Registered device token for user %s: %s (%s)\n", userID, token, platform)
	return nil
}

// UnregisterDeviceToken removes a device token
func (s *NotificationService) UnregisterDeviceToken(userID uuid.UUID, token string) error {
	// TODO: Implement device token removal
	fmt.Printf("Unregistered device token for user %s: %s\n", userID, token)
	return nil
}

// ProcessScheduledNotifications processes pending scheduled notifications
func (s *NotificationService) ProcessScheduledNotifications() error {
	now := time.Now()
	notifications, err := s.repo.GetScheduledNotifications(now)
	if err != nil {
		return fmt.Errorf("failed to get scheduled notifications: %w", err)
	}

	for _, notification := range notifications {
		req := NotificationRequest{
			UserID: notification.UserID,
			Type:   notification.Type,
			Title:  notification.Title,
			Body:   notification.Body,
			Data:   notification.Data,
		}

		err = s.SendNotification(req)
		if err != nil {
			fmt.Printf("Failed to send scheduled notification %s: %v\n", notification.ID, err)
			continue
		}

		// Mark as sent
		notification.Status = "sent"
		sentTime := time.Now()
		notification.SentAt = &sentTime
		s.repo.StoreScheduledNotification(notification)
	}

	return nil
}

// Helper methods

// sendFCMNotification sends notification via Firebase Cloud Messaging
func (s *NotificationService) sendFCMNotification(req NotificationRequest, deviceTokens []string) error {
	if s.fcmClient == nil {
		return fmt.Errorf("FCM client not configured")
	}

	// Create FCM message
	message := &messaging.MulticastMessage{
		Data: req.Data,
		Notification: &messaging.Notification{
			Title: req.Title,
			Body:  req.Body,
		},
		Tokens: deviceTokens,
	}

	// Set Android-specific options
	message.Android = &messaging.AndroidConfig{
		Priority: "high",
		Notification: &messaging.AndroidNotification{
			Sound:           req.Sound,
			ChannelID:       string(req.Type),
			Priority:        messaging.PriorityHigh,
			DefaultSound:    req.Sound == "",
			NotificationCount: getNotificationCount(req.UserID),
		},
	}

	// Set iOS-specific options
	message.APNS = &messaging.APNSConfig{
		Payload: &messaging.APNSPayload{
			Aps: &messaging.Aps{
				Alert: &messaging.ApsAlert{
					Title: req.Title,
					Body:  req.Body,
				},
				Sound: req.Sound,
				Badge: getNotificationCount(req.UserID),
			},
		},
	}

	// Send message
	response, err := s.fcmClient.SendMulticast(context.Background(), message)
	if err != nil {
		return err
	}

	// Check for failures
	if response.FailureCount > 0 {
		fmt.Printf("FCM send had %d failures out of %d messages\n", response.FailureCount, len(deviceTokens))
	}

	return nil
}

// getUserDeviceTokens retrieves device tokens for a user
func (s *NotificationService) getUserDeviceTokens(userID uuid.UUID) ([]string, error) {
	// TODO: Implement actual device token retrieval from database
	// For now, return empty slice
	return []string{}, nil
}

// isNotificationEnabled checks if a notification type is enabled for the user
func (s *NotificationService) isNotificationEnabled(user *models.User, notificationType NotificationType) bool {
	prefs := user.Preferences.Notifications

	switch notificationType {
	case NotificationTypeTaskReminder, NotificationTypeTaskDue:
		return prefs.TaskReminders
	case NotificationTypeSessionComplete:
		return prefs.SessionCompleted
	case NotificationTypeBreakReminder:
		return prefs.BreakReminders
	default:
		return prefs.PushEnabled
	}
}

// getNotificationCount gets the notification badge count for a user
func getNotificationCount(userID uuid.UUID) *int {
	// TODO: Implement actual unread count retrieval
	count := 0
	return &count
}