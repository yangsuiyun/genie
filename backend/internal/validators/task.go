package validators

import (
	"regexp"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
)

// TaskValidators contains validation rules for task management
type TaskValidators struct {
	validate *validator.Validate
}

// NewTaskValidators creates a new instance of task validators
func NewTaskValidators() *TaskValidators {
	validate := validator.New()

	// Register custom validators
	validate.RegisterValidation("valid_priority", validatePriority)
	validate.RegisterValidation("valid_status", validateTaskStatus)
	validate.RegisterValidation("future_date", validateFutureDate)
	validate.RegisterValidation("valid_tag", validateTag)
	validate.RegisterValidation("valid_sort", validateSortField)

	return &TaskValidators{
		validate: validate,
	}
}

// TaskRequest validation struct
type TaskRequest struct {
	Title               string    `json:"title" validate:"required,min=1,max=255"`
	Description         string    `json:"description" validate:"max=2000"`
	Priority            string    `json:"priority" validate:"omitempty,valid_priority"`
	Status              string    `json:"status" validate:"omitempty,valid_status"`
	DueDate             *time.Time `json:"due_date" validate:"omitempty,future_date"`
	Tags                []string  `json:"tags" validate:"omitempty,dive,valid_tag"`
	ParentTaskID        string    `json:"parent_task_id" validate:"omitempty,uuid4"`
	EstimatedPomodoros  int       `json:"estimated_pomodoros" validate:"omitempty,min=1,max=100"`
	CompletedPomodoros  int       `json:"completed_pomodoros" validate:"omitempty,min=0"`
}

// SubtaskRequest validation struct
type SubtaskRequest struct {
	Title       string `json:"title" validate:"required,min=1,max=255"`
	IsCompleted bool   `json:"is_completed"`
	Order       int    `json:"order" validate:"omitempty,min=0"`
}

// NoteRequest validation struct
type NoteRequest struct {
	Content string `json:"content" validate:"required,min=1,max=5000"`
}

// ReminderRequest validation struct
type ReminderRequest struct {
	ScheduledAt time.Time `json:"scheduled_at" validate:"required,future_date"`
	Message     string    `json:"message" validate:"omitempty,max=500"`
}

// TaskListRequest validation struct
type TaskListRequest struct {
	Page       int      `json:"page" validate:"omitempty,min=1"`
	Limit      int      `json:"limit" validate:"omitempty,min=1,max=100"`
	Status     string   `json:"status" validate:"omitempty,valid_status"`
	Priority   string   `json:"priority" validate:"omitempty,valid_priority"`
	Tags       []string `json:"tags" validate:"omitempty,dive,valid_tag"`
	Search     string   `json:"search" validate:"omitempty,max=255"`
	SortBy     string   `json:"sort_by" validate:"omitempty,valid_sort"`
	SortOrder  string   `json:"sort_order" validate:"omitempty,oneof=asc desc"`
	DueBefore  *time.Time `json:"due_before"`
	DueAfter   *time.Time `json:"due_after"`
}

// RecurrenceRuleRequest validation struct
type RecurrenceRuleRequest struct {
	Type           string     `json:"type" validate:"required,oneof=daily weekly monthly yearly"`
	Interval       int        `json:"interval" validate:"required,min=1,max=999"`
	DaysOfWeek     []int      `json:"days_of_week" validate:"omitempty,dive,min=0,max=6"`
	DaysOfMonth    []int      `json:"days_of_month" validate:"omitempty,dive,min=1,max=31"`
	Months         []int      `json:"months" validate:"omitempty,dive,min=1,max=12"`
	EndDate        *time.Time `json:"end_date" validate:"omitempty,future_date"`
	MaxOccurrences int        `json:"max_occurrences" validate:"omitempty,min=1,max=1000"`
}

// ValidateTask validates task creation/update request
func (tv *TaskValidators) ValidateTask(req *TaskRequest) error {
	return tv.validate.Struct(req)
}

// ValidateSubtask validates subtask creation/update request
func (tv *TaskValidators) ValidateSubtask(req *SubtaskRequest) error {
	return tv.validate.Struct(req)
}

// ValidateNote validates note creation/update request
func (tv *TaskValidators) ValidateNote(req *NoteRequest) error {
	return tv.validate.Struct(req)
}

// ValidateReminder validates reminder creation/update request
func (tv *TaskValidators) ValidateReminder(req *ReminderRequest) error {
	return tv.validate.Struct(req)
}

// ValidateTaskList validates task list request
func (tv *TaskValidators) ValidateTaskList(req *TaskListRequest) error {
	return tv.validate.Struct(req)
}

// ValidateRecurrenceRule validates recurrence rule
func (tv *TaskValidators) ValidateRecurrenceRule(req *RecurrenceRuleRequest) error {
	return tv.validate.Struct(req)
}

// Custom validation functions

// validatePriority validates task priority
func validatePriority(fl validator.FieldLevel) bool {
	priority := fl.Field().String()
	validPriorities := []string{"low", "medium", "high", "urgent"}

	for _, valid := range validPriorities {
		if priority == valid {
			return true
		}
	}
	return false
}

// validateTaskStatus validates task status
func validateTaskStatus(fl validator.FieldLevel) bool {
	status := fl.Field().String()
	validStatuses := []string{"pending", "in_progress", "completed", "cancelled"}

	for _, valid := range validStatuses {
		if status == valid {
			return true
		}
	}
	return false
}

// validateFutureDate validates that date is in the future
func validateFutureDate(fl validator.FieldLevel) bool {
	if fl.Field().IsNil() {
		return true // Allow nil dates
	}

	date := fl.Field().Interface().(time.Time)
	return date.After(time.Now())
}

// validateTag validates task tag format
func validateTag(fl validator.FieldLevel) bool {
	tag := fl.Field().String()

	// Tag length validation
	if len(tag) < 1 || len(tag) > 50 {
		return false
	}

	// Tag format validation (alphanumeric, hyphens, underscores)
	tagRegex := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
	return tagRegex.MatchString(tag)
}

// validateSortField validates sort field
func validateSortField(fl validator.FieldLevel) bool {
	sortBy := fl.Field().String()
	validSortFields := []string{"title", "priority", "due_date", "created_at", "updated_at", "status"}

	for _, valid := range validSortFields {
		if sortBy == valid {
			return true
		}
	}
	return false
}

// GetValidationErrors returns formatted validation errors for tasks
func (tv *TaskValidators) GetValidationErrors(err error) map[string]string {
	errors := make(map[string]string)

	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, fieldError := range validationErrors {
			fieldName := strings.ToLower(fieldError.Field())

			switch fieldError.Tag() {
			case "required":
				errors[fieldName] = fieldName + " is required"
			case "min":
				errors[fieldName] = fieldName + " must be at least " + fieldError.Param() + " characters"
			case "max":
				errors[fieldName] = fieldName + " must be at most " + fieldError.Param() + " characters"
			case "valid_priority":
				errors[fieldName] = "Priority must be one of: low, medium, high, urgent"
			case "valid_status":
				errors[fieldName] = "Status must be one of: pending, in_progress, completed, cancelled"
			case "future_date":
				errors[fieldName] = "Date must be in the future"
			case "valid_tag":
				errors[fieldName] = "Tag must contain only letters, numbers, hyphens, and underscores"
			case "valid_sort":
				errors[fieldName] = "Sort field must be one of: title, priority, due_date, created_at, updated_at, status"
			case "oneof":
				errors[fieldName] = fieldName + " must be one of the allowed values"
			case "uuid4":
				errors[fieldName] = fieldName + " must be a valid UUID"
			default:
				errors[fieldName] = fieldName + " is invalid"
			}
		}
	}

	return errors
}

// ValidateTaskTitle validates and sanitizes task title
func (tv *TaskValidators) ValidateTaskTitle(title string) (string, error) {
	// Trim whitespace
	title = strings.TrimSpace(title)

	// Check length
	if len(title) == 0 {
		return "", validator.ValidationErrors{}
	}
	if len(title) > 255 {
		return "", validator.ValidationErrors{}
	}

	// Remove control characters except newlines and tabs
	var sanitized strings.Builder
	for _, r := range title {
		if r >= 32 || r == '\t' || r == '\n' || r == '\r' {
			sanitized.WriteRune(r)
		}
	}

	return sanitized.String(), nil
}

// ValidateTaskDescription validates and sanitizes task description
func (tv *TaskValidators) ValidateTaskDescription(description string) (string, error) {
	// Trim whitespace
	description = strings.TrimSpace(description)

	// Check length
	if len(description) > 2000 {
		return "", validator.ValidationErrors{}
	}

	// Remove control characters except newlines and tabs
	var sanitized strings.Builder
	for _, r := range description {
		if r >= 32 || r == '\t' || r == '\n' || r == '\r' {
			sanitized.WriteRune(r)
		}
	}

	return sanitized.String(), nil
}

// ValidateTags validates and sanitizes tags
func (tv *TaskValidators) ValidateTags(tags []string) ([]string, error) {
	if len(tags) > 20 {
		return nil, validator.ValidationErrors{}
	}

	var validTags []string
	seen := make(map[string]bool)

	for _, tag := range tags {
		// Trim and lowercase
		tag = strings.ToLower(strings.TrimSpace(tag))

		// Skip empty tags
		if len(tag) == 0 {
			continue
		}

		// Skip duplicates
		if seen[tag] {
			continue
		}

		// Validate tag format
		if len(tag) > 50 {
			continue
		}

		tagRegex := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
		if !tagRegex.MatchString(tag) {
			continue
		}

		validTags = append(validTags, tag)
		seen[tag] = true
	}

	return validTags, nil
}

// ValidateDueDate validates due date
func (tv *TaskValidators) ValidateDueDate(dueDate *time.Time) error {
	if dueDate == nil {
		return nil
	}

	// Check if date is too far in the future (10 years)
	maxFutureDate := time.Now().AddDate(10, 0, 0)
	if dueDate.After(maxFutureDate) {
		return validator.ValidationErrors{}
	}

	return nil
}

// ValidateEstimatedPomodoros validates estimated pomodoros count
func (tv *TaskValidators) ValidateEstimatedPomodoros(count int) error {
	if count < 1 || count > 100 {
		return validator.ValidationErrors{}
	}
	return nil
}

// ValidateTaskHierarchy validates task parent-child relationships
func (tv *TaskValidators) ValidateTaskHierarchy(taskID, parentTaskID string) bool {
	// Prevent self-reference
	if taskID == parentTaskID {
		return false
	}

	// Prevent circular references (this would need database access in real implementation)
	// For now, we just prevent direct self-reference
	return true
}

// ValidateRecurrencePattern validates recurrence rule pattern
func (tv *TaskValidators) ValidateRecurrencePattern(rule *RecurrenceRuleRequest) []string {
	var issues []string

	switch rule.Type {
	case "weekly":
		if len(rule.DaysOfWeek) == 0 {
			issues = append(issues, "Weekly recurrence requires at least one day of week")
		}
		for _, day := range rule.DaysOfWeek {
			if day < 0 || day > 6 {
				issues = append(issues, "Days of week must be between 0 (Sunday) and 6 (Saturday)")
				break
			}
		}

	case "monthly":
		if len(rule.DaysOfMonth) == 0 {
			issues = append(issues, "Monthly recurrence requires at least one day of month")
		}
		for _, day := range rule.DaysOfMonth {
			if day < 1 || day > 31 {
				issues = append(issues, "Days of month must be between 1 and 31")
				break
			}
		}

	case "yearly":
		if len(rule.Months) == 0 {
			issues = append(issues, "Yearly recurrence requires at least one month")
		}
		for _, month := range rule.Months {
			if month < 1 || month > 12 {
				issues = append(issues, "Months must be between 1 and 12")
				break
			}
		}
	}

	// Validate end conditions
	if rule.EndDate != nil && rule.MaxOccurrences > 0 {
		issues = append(issues, "Cannot specify both end date and max occurrences")
	}

	if rule.EndDate == nil && rule.MaxOccurrences == 0 {
		issues = append(issues, "Must specify either end date or max occurrences")
	}

	return issues
}

// SanitizeSearchQuery sanitizes search query to prevent injection
func (tv *TaskValidators) SanitizeSearchQuery(query string) string {
	// Trim whitespace
	query = strings.TrimSpace(query)

	// Remove special SQL characters
	query = strings.ReplaceAll(query, "'", "")
	query = strings.ReplaceAll(query, "\"", "")
	query = strings.ReplaceAll(query, ";", "")
	query = strings.ReplaceAll(query, "--", "")
	query = strings.ReplaceAll(query, "/*", "")
	query = strings.ReplaceAll(query, "*/", "")

	// Limit length
	if len(query) > 255 {
		query = query[:255]
	}

	return query
}