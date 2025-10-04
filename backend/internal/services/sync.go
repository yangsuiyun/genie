package services

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"

	"backend/internal/models"
)

// SyncRepository defines the interface for sync data access
type SyncRepository interface {
	GetLastSyncTime(userID uuid.UUID, deviceID string) (*time.Time, error)
	UpdateLastSyncTime(userID uuid.UUID, deviceID string, syncTime time.Time) error
	GetChangedTasksSince(userID uuid.UUID, since time.Time) ([]*models.Task, error)
	GetChangedSessionsSince(userID uuid.UUID, since time.Time) ([]*models.PomodoroSession, error)
	GetDeletedItemsSince(userID uuid.UUID, since time.Time) ([]SyncDeletedItem, error)
	RecordSyncConflict(conflict *SyncConflict) error
	GetUserDevices(userID uuid.UUID) ([]*SyncDevice, error)
	RegisterDevice(device *SyncDevice) error
	UpdateDeviceLastSeen(deviceID string) error
}

// SyncService handles data synchronization between devices
type SyncService struct {
	repo            SyncRepository
	taskRepo        TaskRepository
	pomodoroRepo    PomodoroRepository
	conflictHandler ConflictHandler
}

// SyncRequest represents a synchronization request from a client
type SyncRequest struct {
	DeviceID       string                      `json:"device_id" validate:"required"`
	LastSyncTime   *time.Time                  `json:"last_sync_time,omitempty"`
	ChangedTasks   []*models.Task              `json:"changed_tasks,omitempty"`
	ChangedSessions []*models.PomodoroSession  `json:"changed_sessions,omitempty"`
	DeletedItems   []SyncDeletedItem           `json:"deleted_items,omitempty"`
	DeviceInfo     SyncDeviceInfo              `json:"device_info"`
}

// SyncResponse represents the response to a synchronization request
type SyncResponse struct {
	Success        bool                        `json:"success"`
	LastSyncTime   time.Time                   `json:"last_sync_time"`
	ChangedTasks   []*models.Task              `json:"changed_tasks,omitempty"`
	ChangedSessions []*models.PomodoroSession  `json:"changed_sessions,omitempty"`
	DeletedItems   []SyncDeletedItem           `json:"deleted_items,omitempty"`
	Conflicts      []SyncConflict              `json:"conflicts,omitempty"`
	ConflictCount  int                         `json:"conflict_count"`
	Message        string                      `json:"message,omitempty"`
}

// SyncDeletedItem represents a deleted item for sync purposes
type SyncDeletedItem struct {
	ID         uuid.UUID `json:"id"`
	Type       string    `json:"type"` // "task", "session", "note", etc.
	DeletedAt  time.Time `json:"deleted_at"`
	DeviceID   string    `json:"device_id"`
}

// SyncConflict represents a synchronization conflict
type SyncConflict struct {
	ID            uuid.UUID   `json:"id"`
	UserID        uuid.UUID   `json:"user_id"`
	ItemID        uuid.UUID   `json:"item_id"`
	ItemType      string      `json:"item_type"`
	ConflictType  string      `json:"conflict_type"` // "version", "concurrent_edit", "deleted_vs_modified"
	LocalVersion  interface{} `json:"local_version"`
	RemoteVersion interface{} `json:"remote_version"`
	Resolution    string      `json:"resolution"` // "last_write_wins", "manual", "merge"
	ResolvedAt    *time.Time  `json:"resolved_at,omitempty"`
	CreatedAt     time.Time   `json:"created_at"`
}

// SyncDevice represents a device registered for synchronization
type SyncDevice struct {
	ID           string         `json:"id"`
	UserID       uuid.UUID      `json:"user_id"`
	DeviceName   string         `json:"device_name"`
	DeviceType   string         `json:"device_type"` // "mobile", "desktop", "web"
	Platform     string         `json:"platform"`    // "ios", "android", "windows", "macos", "web"
	AppVersion   string         `json:"app_version"`
	LastSeen     time.Time      `json:"last_seen"`
	IsActive     bool           `json:"is_active"`
	RegisteredAt time.Time      `json:"registered_at"`
}

// SyncDeviceInfo represents device information sent during sync
type SyncDeviceInfo struct {
	DeviceName string `json:"device_name"`
	DeviceType string `json:"device_type"`
	Platform   string `json:"platform"`
	AppVersion string `json:"app_version"`
}

// ConflictHandler defines how to handle sync conflicts
type ConflictHandler interface {
	ResolveTaskConflict(local, remote *models.Task) (*models.Task, error)
	ResolveSessionConflict(local, remote *models.PomodoroSession) (*models.PomodoroSession, error)
}

// LastWriteWinsHandler implements last-write-wins conflict resolution
type LastWriteWinsHandler struct{}

// SyncStats represents synchronization statistics
type SyncStats struct {
	LastSyncTime    *time.Time `json:"last_sync_time"`
	TotalSyncs      int        `json:"total_syncs"`
	SuccessfulSyncs int        `json:"successful_syncs"`
	ConflictsTotal  int        `json:"conflicts_total"`
	ConflictsResolved int      `json:"conflicts_resolved"`
	DeviceCount     int        `json:"device_count"`
	LastConflictAt  *time.Time `json:"last_conflict_at"`
}

// NewSyncService creates a new sync service
func NewSyncService(repo SyncRepository, taskRepo TaskRepository, pomodoroRepo PomodoroRepository) *SyncService {
	return &SyncService{
		repo:            repo,
		taskRepo:        taskRepo,
		pomodoroRepo:    pomodoroRepo,
		conflictHandler: &LastWriteWinsHandler{},
	}
}

// Sync performs bidirectional synchronization for a user
func (s *SyncService) Sync(userID uuid.UUID, req SyncRequest) (*SyncResponse, error) {
	response := &SyncResponse{
		Success:      false,
		LastSyncTime: time.Now(),
		Conflicts:    []SyncConflict{},
	}

	// Register or update device
	err := s.registerOrUpdateDevice(userID, req)
	if err != nil {
		return response, fmt.Errorf("failed to register device: %w", err)
	}

	// Get last sync time for this device
	lastSyncTime, err := s.repo.GetLastSyncTime(userID, req.DeviceID)
	if err != nil {
		return response, fmt.Errorf("failed to get last sync time: %w", err)
	}

	// If no last sync time provided, use stored one
	if req.LastSyncTime == nil {
		req.LastSyncTime = lastSyncTime
	}

	// Process incoming changes from client
	conflicts, err := s.processIncomingChanges(userID, req)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to process incoming changes: %v", err)
		return response, err
	}
	response.Conflicts = conflicts
	response.ConflictCount = len(conflicts)

	// Get outgoing changes to send to client
	err = s.getOutgoingChanges(userID, req.LastSyncTime, response)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to get outgoing changes: %v", err)
		return response, err
	}

	// Update last sync time
	err = s.repo.UpdateLastSyncTime(userID, req.DeviceID, response.LastSyncTime)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to update sync time: %v", err)
		return response, err
	}

	response.Success = true
	if response.ConflictCount > 0 {
		response.Message = fmt.Sprintf("Sync completed with %d conflicts resolved", response.ConflictCount)
	} else {
		response.Message = "Sync completed successfully"
	}

	return response, nil
}

// processIncomingChanges handles changes from the client
func (s *SyncService) processIncomingChanges(userID uuid.UUID, req SyncRequest) ([]SyncConflict, error) {
	var conflicts []SyncConflict

	// Process changed tasks
	for _, task := range req.ChangedTasks {
		conflict, err := s.processIncomingTask(userID, task, req.DeviceID)
		if err != nil {
			return conflicts, fmt.Errorf("failed to process task %s: %w", task.ID, err)
		}
		if conflict != nil {
			conflicts = append(conflicts, *conflict)
		}
	}

	// Process changed sessions
	for _, session := range req.ChangedSessions {
		conflict, err := s.processIncomingSession(userID, session, req.DeviceID)
		if err != nil {
			return conflicts, fmt.Errorf("failed to process session %s: %w", session.ID, err)
		}
		if conflict != nil {
			conflicts = append(conflicts, *conflict)
		}
	}

	// Process deleted items
	for _, deletedItem := range req.DeletedItems {
		err := s.processDeletedItem(userID, deletedItem)
		if err != nil {
			return conflicts, fmt.Errorf("failed to process deleted item %s: %w", deletedItem.ID, err)
		}
	}

	return conflicts, nil
}

// processIncomingTask handles an incoming task change
func (s *SyncService) processIncomingTask(userID uuid.UUID, incomingTask *models.Task, deviceID string) (*SyncConflict, error) {
	// Validate task belongs to user
	if incomingTask.UserID != userID {
		return nil, fmt.Errorf("task does not belong to user")
	}

	// Get existing task from database
	existingTask, err := s.taskRepo.GetByID(incomingTask.ID)
	if err != nil {
		if models.IsNotFoundError(err) {
			// New task, create it
			incomingTask.LastModifiedDevice = deviceID
			_, err = s.taskRepo.Create(incomingTask)
			return nil, err
		}
		return nil, err
	}

	// Check for conflicts
	if existingTask.SyncVersion > incomingTask.SyncVersion {
		// Server has newer version, create conflict
		conflict := &SyncConflict{
			ID:            uuid.New(),
			UserID:        userID,
			ItemID:        incomingTask.ID,
			ItemType:      "task",
			ConflictType:  "version",
			LocalVersion:  existingTask,
			RemoteVersion: incomingTask,
			Resolution:    "last_write_wins",
			CreatedAt:     time.Now(),
		}

		// Resolve using last-write-wins (most recent UpdatedAt)
		var resolvedTask *models.Task
		if incomingTask.UpdatedAt.After(existingTask.UpdatedAt) {
			resolvedTask = incomingTask
		} else {
			resolvedTask = existingTask
		}

		resolvedTask.SyncVersion = max(existingTask.SyncVersion, incomingTask.SyncVersion) + 1
		resolvedTask.LastModifiedDevice = deviceID
		resolvedTask.UpdatedAt = time.Now()

		_, err = s.taskRepo.Update(resolvedTask)
		if err != nil {
			return conflict, err
		}

		conflict.ResolvedAt = &resolvedTask.UpdatedAt
		err = s.repo.RecordSyncConflict(conflict)
		return conflict, err
	}

	// No conflict, update task
	incomingTask.SyncVersion++
	incomingTask.LastModifiedDevice = deviceID
	_, err = s.taskRepo.Update(incomingTask)
	return nil, err
}

// processIncomingSession handles an incoming session change
func (s *SyncService) processIncomingSession(userID uuid.UUID, incomingSession *models.PomodoroSession, deviceID string) (*SyncConflict, error) {
	// Validate session belongs to user
	if incomingSession.UserID != userID {
		return nil, fmt.Errorf("session does not belong to user")
	}

	// Get existing session from database
	existingSession, err := s.pomodoroRepo.GetByID(incomingSession.ID)
	if err != nil {
		if models.IsNotFoundError(err) {
			// New session, create it
			_, err = s.pomodoroRepo.Create(incomingSession)
			return nil, err
		}
		return nil, err
	}

	// Sessions are generally less conflicted than tasks
	// Use simple last-write-wins based on UpdatedAt
	if incomingSession.UpdatedAt.After(existingSession.UpdatedAt) {
		_, err = s.pomodoroRepo.Update(incomingSession)
		return nil, err
	}

	// Server version is newer, no update needed
	return nil, nil
}

// processDeletedItem handles a deleted item
func (s *SyncService) processDeletedItem(userID uuid.UUID, deletedItem SyncDeletedItem) error {
	switch deletedItem.Type {
	case "task":
		// Verify ownership before deletion
		task, err := s.taskRepo.GetByID(deletedItem.ID)
		if err != nil {
			if models.IsNotFoundError(err) {
				return nil // Already deleted
			}
			return err
		}
		if task.UserID != userID {
			return fmt.Errorf("cannot delete task belonging to another user")
		}
		return s.taskRepo.SoftDelete(deletedItem.ID)

	case "session":
		// Similar for sessions
		session, err := s.pomodoroRepo.GetByID(deletedItem.ID)
		if err != nil {
			if models.IsNotFoundError(err) {
				return nil // Already deleted
			}
			return err
		}
		if session.UserID != userID {
			return fmt.Errorf("cannot delete session belonging to another user")
		}
		return s.pomodoroRepo.Delete(deletedItem.ID)

	default:
		return fmt.Errorf("unknown item type for deletion: %s", deletedItem.Type)
	}
}

// getOutgoingChanges retrieves changes to send to the client
func (s *SyncService) getOutgoingChanges(userID uuid.UUID, since *time.Time, response *SyncResponse) error {
	if since == nil {
		// First sync, send all data
		defaultTime := time.Unix(0, 0)
		since = &defaultTime
	}

	// Get changed tasks
	changedTasks, err := s.repo.GetChangedTasksSince(userID, *since)
	if err != nil {
		return fmt.Errorf("failed to get changed tasks: %w", err)
	}
	response.ChangedTasks = changedTasks

	// Get changed sessions
	changedSessions, err := s.repo.GetChangedSessionsSince(userID, *since)
	if err != nil {
		return fmt.Errorf("failed to get changed sessions: %w", err)
	}
	response.ChangedSessions = changedSessions

	// Get deleted items
	deletedItems, err := s.repo.GetDeletedItemsSince(userID, *since)
	if err != nil {
		return fmt.Errorf("failed to get deleted items: %w", err)
	}
	response.DeletedItems = deletedItems

	return nil
}

// registerOrUpdateDevice registers a new device or updates existing one
func (s *SyncService) registerOrUpdateDevice(userID uuid.UUID, req SyncRequest) error {
	device := &SyncDevice{
		ID:           req.DeviceID,
		UserID:       userID,
		DeviceName:   req.DeviceInfo.DeviceName,
		DeviceType:   req.DeviceInfo.DeviceType,
		Platform:     req.DeviceInfo.Platform,
		AppVersion:   req.DeviceInfo.AppVersion,
		LastSeen:     time.Now(),
		IsActive:     true,
		RegisteredAt: time.Now(),
	}

	return s.repo.RegisterDevice(device)
}

// NotifyTaskChange notifies the sync service of a task change
func (s *SyncService) NotifyTaskChange(taskID uuid.UUID, changeType string) {
	// This could trigger real-time sync notifications to other devices
	// For now, it's just a placeholder for future real-time sync implementation
	fmt.Printf("Task %s changed: %s\n", taskID, changeType)
}

// GetUserDevices retrieves all devices for a user
func (s *SyncService) GetUserDevices(userID uuid.UUID) ([]*SyncDevice, error) {
	devices, err := s.repo.GetUserDevices(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user devices: %w", err)
	}
	return devices, nil
}

// GetSyncStats retrieves synchronization statistics for a user
func (s *SyncService) GetSyncStats(userID uuid.UUID) (*SyncStats, error) {
	// TODO: Implement actual stats calculation
	// This would involve querying sync history, conflicts, etc.

	devices, err := s.repo.GetUserDevices(userID)
	if err != nil {
		return nil, err
	}

	stats := &SyncStats{
		DeviceCount: len(devices),
		// Other stats would be calculated from database
	}

	return stats, nil
}

// ForceSync forces a full synchronization for a user (useful for troubleshooting)
func (s *SyncService) ForceSync(userID uuid.UUID, deviceID string) error {
	// Reset last sync time to force full sync
	return s.repo.UpdateLastSyncTime(userID, deviceID, time.Unix(0, 0))
}

// Implementation of LastWriteWinsHandler

// ResolveTaskConflict resolves task conflicts using last-write-wins strategy
func (h *LastWriteWinsHandler) ResolveTaskConflict(local, remote *models.Task) (*models.Task, error) {
	if remote.UpdatedAt.After(local.UpdatedAt) {
		return remote, nil
	}
	return local, nil
}

// ResolveSessionConflict resolves session conflicts using last-write-wins strategy
func (h *LastWriteWinsHandler) ResolveSessionConflict(local, remote *models.PomodoroSession) (*models.PomodoroSession, error) {
	if remote.UpdatedAt.After(local.UpdatedAt) {
		return remote, nil
	}
	return local, nil
}

// Helper function to get max of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}