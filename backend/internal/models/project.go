package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Project represents a project in the system
type Project struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID      uuid.UUID `json:"user_id" gorm:"type:uuid;not null;index"`
	Name        string    `json:"name" gorm:"type:varchar(255);not null"`
	Description string    `json:"description" gorm:"type:text"`
	IsDefault   bool      `json:"is_default" gorm:"not null;default:false"`
	IsCompleted bool      `json:"is_completed" gorm:"not null;default:false"`
	CreatedAt   time.Time `json:"created_at" gorm:"not null;default:CURRENT_TIMESTAMP"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"not null;default:CURRENT_TIMESTAMP"`

	// Relationships
	User     User             `json:"-" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
	Tasks    []Task           `json:"tasks,omitempty" gorm:"foreignKey:ProjectID;constraint:OnDelete:CASCADE"`
	Sessions []PomodoroSession `json:"sessions,omitempty" gorm:"foreignKey:ProjectID;constraint:OnDelete:CASCADE"`
}

// ProjectStatistics represents calculated statistics for a project
type ProjectStatistics struct {
	TotalTasks         int     `json:"total_tasks"`
	CompletedTasks     int     `json:"completed_tasks"`
	PendingTasks       int     `json:"pending_tasks"`
	CompletionPercent  float64 `json:"completion_percent"`
	TotalPomodoros     int     `json:"total_pomodoros"`
	TotalTimeSeconds   int     `json:"total_time_seconds"`
	TotalTimeFormatted string  `json:"total_time_formatted"`
	AvgPomodoroSec     int     `json:"avg_pomodoro_duration_sec"`
	LastActivityAt     *time.Time `json:"last_activity_at"`
}

// ProjectWithStats combines a project with its statistics
type ProjectWithStats struct {
	Project
	Statistics ProjectStatistics `json:"statistics"`
}

// ProjectCreateRequest represents the request to create a new project
type ProjectCreateRequest struct {
	Name        string `json:"name" binding:"required,min=1,max=255"`
	Description string `json:"description" binding:"max=1000"`
}

// ProjectUpdateRequest represents the request to update a project
type ProjectUpdateRequest struct {
	Name        *string `json:"name" binding:"omitempty,min=1,max=255"`
	Description *string `json:"description" binding:"omitempty,max=1000"`
	IsCompleted *bool   `json:"is_completed"`
}

// ProjectCompletionRequest represents the request to toggle project completion
type ProjectCompletionRequest struct {
	IsCompleted bool `json:"is_completed"`
}

// BeforeCreate sets the ID if not provided
func (p *Project) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

// TableName returns the table name for Project
func (Project) TableName() string {
	return "projects"
}

// IsEditable returns true if the project can be edited (non-default projects can always be edited)
func (p *Project) IsEditable() bool {
	return true // All projects are editable, including default ones
}

// IsDeletable returns true if the project can be deleted (default projects cannot be deleted)
func (p *Project) IsDeletable() bool {
	return !p.IsDefault
}

// CanToggleCompletion returns true if the project completion status can be toggled
func (p *Project) CanToggleCompletion() bool {
	return true // All projects can be manually marked complete/incomplete
}