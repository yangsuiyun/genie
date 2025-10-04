package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"

	"backend/internal/models"
)

// UserRepository defines the interface for user data access
type UserRepository interface {
	Create(user *models.User) (*models.User, error)
	GetByID(id uuid.UUID) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	Update(user *models.User) (*models.User, error)
	Delete(id uuid.UUID) error
	List(filter UserFilter) ([]*models.User, int, error)
	UpdateLastLogin(id uuid.UUID) error
	UpdatePreferences(id uuid.UUID, preferences models.UserPreferences) error
}

// UserService handles user-related business logic
type UserService struct {
	repo UserRepository
}

// UserFilter represents filters for user queries
type UserFilter struct {
	Email      string    `json:"email,omitempty"`
	IsVerified *bool     `json:"is_verified,omitempty"`
	CreatedAfter *time.Time `json:"created_after,omitempty"`
	CreatedBefore *time.Time `json:"created_before,omitempty"`
	Limit      int       `json:"limit"`
	Offset     int       `json:"offset"`
	SortBy     string    `json:"sort_by"`
	SortOrder  string    `json:"sort_order"`
}

// UserStats represents user statistics
type UserStats struct {
	TotalUsers       int     `json:"total_users"`
	VerifiedUsers    int     `json:"verified_users"`
	ActiveUsers      int     `json:"active_users"`
	NewUsersToday    int     `json:"new_users_today"`
	NewUsersThisWeek int     `json:"new_users_this_week"`
	VerificationRate float64 `json:"verification_rate"`
}

// NewUserService creates a new user service
func NewUserService(repo UserRepository) *UserService {
	return &UserService{
		repo: repo,
	}
}

// Create creates a new user
func (s *UserService) Create(user *models.User) (*models.User, error) {
	// Validate user data
	if err := user.Validate(); err != nil {
		return nil, fmt.Errorf("user validation failed: %w", err)
	}

	// Check if email already exists
	existingUser, err := s.repo.GetByEmail(user.Email)
	if err != nil && !models.IsNotFoundError(err) {
		return nil, fmt.Errorf("failed to check existing email: %w", err)
	}
	if existingUser != nil {
		return nil, models.ErrEmailAlreadyExists
	}

	// Set default values
	if user.ID == uuid.Nil {
		user.ID = uuid.New()
	}

	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	// Set default preferences if not provided
	if user.Preferences == (models.UserPreferences{}) {
		user.Preferences = models.DefaultUserPreferences()
	}

	// Create user
	createdUser, err := s.repo.Create(user)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return createdUser, nil
}

// GetByID retrieves a user by ID
func (s *UserService) GetByID(id string) (*models.User, error) {
	userUUID, err := uuid.Parse(id)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID format: %w", err)
	}

	user, err := s.repo.GetByID(userUUID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by ID: %w", err)
	}

	return user, nil
}

// GetByEmail retrieves a user by email
func (s *UserService) GetByEmail(email string) (*models.User, error) {
	if email == "" {
		return nil, models.ErrEmailRequired
	}

	user, err := s.repo.GetByEmail(email)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	return user, nil
}

// Update updates a user
func (s *UserService) Update(user *models.User) (*models.User, error) {
	// Validate user data
	if err := user.Validate(); err != nil {
		return nil, fmt.Errorf("user validation failed: %w", err)
	}

	// Check if user exists
	existingUser, err := s.repo.GetByID(user.ID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get existing user: %w", err)
	}

	// Check if email is being changed and if it's already taken
	if existingUser.Email != user.Email {
		emailTaken, err := s.repo.GetByEmail(user.Email)
		if err != nil && !models.IsNotFoundError(err) {
			return nil, fmt.Errorf("failed to check email availability: %w", err)
		}
		if emailTaken != nil {
			return nil, models.ErrEmailAlreadyExists
		}
	}

	// Update timestamp
	user.UpdatedAt = time.Now()

	// Update user
	updatedUser, err := s.repo.Update(user)
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return updatedUser, nil
}

// Delete deletes a user
func (s *UserService) Delete(id string) error {
	userUUID, err := uuid.Parse(id)
	if err != nil {
		return fmt.Errorf("invalid user ID format: %w", err)
	}

	// Check if user exists
	_, err = s.repo.GetByID(userUUID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return models.ErrUserNotFound
		}
		return fmt.Errorf("failed to get user for deletion: %w", err)
	}

	// Delete user
	err = s.repo.Delete(userUUID)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	return nil
}

// List retrieves users with filtering and pagination
func (s *UserService) List(filter UserFilter) ([]*models.User, int, error) {
	// Set default values
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100 // Max limit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	if filter.SortBy == "" {
		filter.SortBy = "created_at"
	}
	if filter.SortOrder == "" {
		filter.SortOrder = "desc"
	}

	users, total, err := s.repo.List(filter)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list users: %w", err)
	}

	return users, total, nil
}

// UpdateLastLogin updates the user's last login timestamp
func (s *UserService) UpdateLastLogin(id uuid.UUID) error {
	err := s.repo.UpdateLastLogin(id)
	if err != nil {
		return fmt.Errorf("failed to update last login: %w", err)
	}
	return nil
}

// UpdatePreferences updates a user's preferences
func (s *UserService) UpdatePreferences(id string, preferences models.UserPreferences) (*models.User, error) {
	userUUID, err := uuid.Parse(id)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID format: %w", err)
	}

	// Get user to validate it exists
	user, err := s.repo.GetByID(userUUID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return nil, models.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Validate preferences
	user.Preferences = preferences
	if err := user.Validate(); err != nil {
		return nil, fmt.Errorf("preferences validation failed: %w", err)
	}

	// Update preferences
	err = s.repo.UpdatePreferences(userUUID, preferences)
	if err != nil {
		return nil, fmt.Errorf("failed to update preferences: %w", err)
	}

	// Return updated user
	updatedUser, err := s.repo.GetByID(userUUID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated user: %w", err)
	}

	return updatedUser, nil
}

// VerifyEmail marks a user's email as verified
func (s *UserService) VerifyEmail(id string) error {
	userUUID, err := uuid.Parse(id)
	if err != nil {
		return fmt.Errorf("invalid user ID format: %w", err)
	}

	user, err := s.repo.GetByID(userUUID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return models.ErrUserNotFound
		}
		return fmt.Errorf("failed to get user: %w", err)
	}

	if user.IsVerified {
		return nil // Already verified
	}

	user.IsVerified = true
	user.UpdatedAt = time.Now()

	_, err = s.repo.Update(user)
	if err != nil {
		return fmt.Errorf("failed to verify email: %w", err)
	}

	return nil
}

// DeactivateUser deactivates a user account
func (s *UserService) DeactivateUser(id string) error {
	userUUID, err := uuid.Parse(id)
	if err != nil {
		return fmt.Errorf("invalid user ID format: %w", err)
	}

	user, err := s.repo.GetByID(userUUID)
	if err != nil {
		if models.IsNotFoundError(err) {
			return models.ErrUserNotFound
		}
		return fmt.Errorf("failed to get user: %w", err)
	}

	// Add deactivation logic here if needed
	// For now, we could add an IsActive field to the User model
	user.UpdatedAt = time.Now()

	_, err = s.repo.Update(user)
	if err != nil {
		return fmt.Errorf("failed to deactivate user: %w", err)
	}

	return nil
}

// GetUserStats retrieves user statistics
func (s *UserService) GetUserStats() (*UserStats, error) {
	// TODO: Implement actual statistics calculation
	// This would typically involve aggregation queries on the database

	// For now, return empty stats
	stats := &UserStats{
		TotalUsers:       0,
		VerifiedUsers:    0,
		ActiveUsers:      0,
		NewUsersToday:    0,
		NewUsersThisWeek: 0,
		VerificationRate: 0.0,
	}

	return stats, nil
}

// SearchUsers searches for users by email or name
func (s *UserService) SearchUsers(query string, limit int) ([]*models.User, error) {
	if query == "" {
		return []*models.User{}, nil
	}

	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50 // Max limit for search
	}

	filter := UserFilter{
		Email:     query,
		Limit:     limit,
		Offset:    0,
		SortBy:    "created_at",
		SortOrder: "desc",
	}

	users, _, err := s.repo.List(filter)
	if err != nil {
		return nil, fmt.Errorf("failed to search users: %w", err)
	}

	return users, nil
}

// GetRecentUsers retrieves recently created users
func (s *UserService) GetRecentUsers(limit int) ([]*models.User, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}

	filter := UserFilter{
		Limit:     limit,
		Offset:    0,
		SortBy:    "created_at",
		SortOrder: "desc",
	}

	users, _, err := s.repo.List(filter)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent users: %w", err)
	}

	return users, nil
}

// ValidateUserData validates user input data
func (s *UserService) ValidateUserData(user *models.User) error {
	return user.Validate()
}

// GetUserPreferences retrieves a user's preferences
func (s *UserService) GetUserPreferences(id string) (*models.UserPreferences, error) {
	user, err := s.GetByID(id)
	if err != nil {
		return nil, err
	}

	return &user.Preferences, nil
}