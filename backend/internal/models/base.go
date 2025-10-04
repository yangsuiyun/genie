package models

import (
	"time"

	"github.com/google/uuid"
)

// BaseModel provides common fields for all entities
type BaseModel struct {
	ID        string    `json:"id" db:"id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// SyncableModel extends BaseModel with sync-related fields
type SyncableModel struct {
	BaseModel
	SyncVersion int64      `json:"sync_version" db:"sync_version"`
	IsDeleted   bool       `json:"is_deleted" db:"is_deleted"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty" db:"deleted_at"`
}

// UserOwnedModel extends SyncableModel with user ownership
type UserOwnedModel struct {
	SyncableModel
	UserID string `json:"user_id" db:"user_id"`
}

// NewBaseModel creates a new BaseModel with generated ID and timestamps
func NewBaseModel() BaseModel {
	now := time.Now()
	return BaseModel{
		ID:        uuid.New().String(),
		CreatedAt: now,
		UpdatedAt: now,
	}
}

// NewSyncableModel creates a new SyncableModel with generated ID and timestamps
func NewSyncableModel() SyncableModel {
	return SyncableModel{
		BaseModel:   NewBaseModel(),
		SyncVersion: 1,
		IsDeleted:   false,
		DeletedAt:   nil,
	}
}

// NewUserOwnedModel creates a new UserOwnedModel with user ID
func NewUserOwnedModel(userID string) UserOwnedModel {
	return UserOwnedModel{
		SyncableModel: NewSyncableModel(),
		UserID:        userID,
	}
}

// Touch updates the UpdatedAt timestamp
func (m *BaseModel) Touch() {
	m.UpdatedAt = time.Now()
}

// IncrementSyncVersion increments the sync version and updates timestamp
func (m *SyncableModel) IncrementSyncVersion() {
	m.SyncVersion++
	m.Touch()
}

// MarkDeleted marks the entity as deleted (soft delete)
func (m *SyncableModel) MarkDeleted() {
	now := time.Now()
	m.IsDeleted = true
	m.DeletedAt = &now
	m.IncrementSyncVersion()
}

// IsActive returns true if the entity is not deleted
func (m *SyncableModel) IsActive() bool {
	return !m.IsDeleted
}

// TimestampUpdateHook provides a common interface for updating timestamps
type TimestampUpdateHook interface {
	BeforeUpdate()
}

// BeforeUpdate implements TimestampUpdateHook for BaseModel
func (m *BaseModel) BeforeUpdate() {
	m.Touch()
}

// BeforeUpdate implements TimestampUpdateHook for SyncableModel
func (m *SyncableModel) BeforeUpdate() {
	m.IncrementSyncVersion()
}

// Validation interface for common validation patterns
type Validator interface {
	Validate() error
}

// SoftDeletable interface for entities that support soft deletion
type SoftDeletable interface {
	MarkDeleted()
	IsActive() bool
}

// Syncable interface for entities that support synchronization
type Syncable interface {
	GetSyncVersion() int64
	IncrementSyncVersion()
	GetUserID() string
}

// GetSyncVersion returns the sync version
func (m *SyncableModel) GetSyncVersion() int64 {
	return m.SyncVersion
}

// GetUserID returns the user ID for UserOwnedModel
func (m *UserOwnedModel) GetUserID() string {
	return m.UserID
}