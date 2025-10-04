package models

import (
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Note represents a note that can be attached to tasks or sessions
type Note struct {
	ID         string    `json:"id" db:"id"`
	UserID     string    `json:"user_id" db:"user_id"`
	TaskID     *string   `json:"task_id,omitempty" db:"task_id"`
	SessionID  *string   `json:"session_id,omitempty" db:"session_id"`
	Content    string    `json:"content" db:"content"`
	NoteType   NoteType  `json:"note_type" db:"note_type"`
	IsPinned   bool      `json:"is_pinned" db:"is_pinned"`
	Tags       []string  `json:"tags" db:"tags"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
	SyncVersion int64    `json:"sync_version" db:"sync_version"`
	IsDeleted  bool      `json:"is_deleted" db:"is_deleted"`
	DeletedAt  *time.Time `json:"deleted_at,omitempty" db:"deleted_at"`

	// Computed fields (not stored in DB)
	WordCount      int    `json:"word_count" db:"-"`
	CharacterCount int    `json:"character_count" db:"-"`
	ReadingTime    int    `json:"reading_time" db:"-"` // estimated reading time in seconds
}

// NoteType represents different types of notes
type NoteType string

const (
	NoteTypeGeneral     NoteType = "general"
	NoteTypeProgress    NoteType = "progress"
	NoteTypeIdea        NoteType = "idea"
	NoteTypeIssue       NoteType = "issue"
	NoteTypeReflection  NoteType = "reflection"
	NoteTypeReminder    NoteType = "reminder"
	NoteTypeResource    NoteType = "resource"
	NoteTypeMeeting     NoteType = "meeting"
	NoteTypeDecision    NoteType = "decision"
	NoteTypeAction      NoteType = "action"
)

// NewNote creates a new note
func NewNote(userID, content string, noteType NoteType) *Note {
	now := time.Now()
	return &Note{
		ID:          uuid.New().String(),
		UserID:      userID,
		Content:     content,
		NoteType:    noteType,
		IsPinned:    false,
		Tags:        []string{},
		CreatedAt:   now,
		UpdatedAt:   now,
		SyncVersion: 1,
		IsDeleted:   false,
	}
}

// NewTaskNote creates a new note attached to a task
func NewTaskNote(userID, taskID, content string, noteType NoteType) *Note {
	note := NewNote(userID, content, noteType)
	note.TaskID = &taskID
	return note
}

// NewSessionNote creates a new note attached to a Pomodoro session
func NewSessionNote(userID, sessionID, content string, noteType NoteType) *Note {
	note := NewNote(userID, content, noteType)
	note.SessionID = &sessionID
	return note
}

// Update updates the note content and type
func (n *Note) Update(content *string, noteType *NoteType) {
	if content != nil {
		n.Content = *content
	}
	if noteType != nil {
		n.NoteType = *noteType
	}

	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// Pin pins the note
func (n *Note) Pin() {
	n.IsPinned = true
	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// Unpin unpins the note
func (n *Note) Unpin() {
	n.IsPinned = false
	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// AddTag adds a tag to the note
func (n *Note) AddTag(tag string) {
	// Check if tag already exists
	for _, existingTag := range n.Tags {
		if existingTag == tag {
			return
		}
	}

	n.Tags = append(n.Tags, tag)
	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// RemoveTag removes a tag from the note
func (n *Note) RemoveTag(tag string) {
	for i, existingTag := range n.Tags {
		if existingTag == tag {
			n.Tags = append(n.Tags[:i], n.Tags[i+1:]...)
			n.UpdatedAt = time.Now()
			n.SyncVersion++
			return
		}
	}
}

// SetTags replaces all tags with new ones
func (n *Note) SetTags(tags []string) {
	n.Tags = tags
	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// SoftDelete marks the note as deleted
func (n *Note) SoftDelete() {
	now := time.Now()
	n.IsDeleted = true
	n.DeletedAt = &now
	n.UpdatedAt = now
	n.SyncVersion++
}

// Restore restores a soft-deleted note
func (n *Note) Restore() {
	n.IsDeleted = false
	n.DeletedAt = nil
	n.UpdatedAt = time.Now()
	n.SyncVersion++
}

// CalculateWordCount calculates the word count of the note content
func (n *Note) CalculateWordCount() int {
	if n.Content == "" {
		return 0
	}

	// Simple word count - split by whitespace
	words := strings.Fields(n.Content)
	return len(words)
}

// CalculateCharacterCount calculates the character count of the note content
func (n *Note) CalculateCharacterCount() int {
	return len(n.Content)
}

// CalculateReadingTime estimates reading time in seconds (assuming 200 WPM)
func (n *Note) CalculateReadingTime() int {
	wordCount := n.CalculateWordCount()
	if wordCount == 0 {
		return 0
	}

	// Assuming average reading speed of 200 words per minute
	minutes := float64(wordCount) / 200.0
	seconds := int(minutes * 60)
	if seconds < 5 {
		return 5 // Minimum 5 seconds reading time
	}
	return seconds
}

// UpdateComputedFields updates computed fields
func (n *Note) UpdateComputedFields() {
	n.WordCount = n.CalculateWordCount()
	n.CharacterCount = n.CalculateCharacterCount()
	n.ReadingTime = n.CalculateReadingTime()
}

// IsTaskNote returns true if this note is attached to a task
func (n *Note) IsTaskNote() bool {
	return n.TaskID != nil
}

// IsSessionNote returns true if this note is attached to a session
func (n *Note) IsSessionNote() bool {
	return n.SessionID != nil
}

// IsStandaloneNote returns true if this note is not attached to anything
func (n *Note) IsStandaloneNote() bool {
	return n.TaskID == nil && n.SessionID == nil
}

// GetAttachmentType returns the type of attachment
func (n *Note) GetAttachmentType() string {
	if n.IsTaskNote() {
		return "task"
	}
	if n.IsSessionNote() {
		return "session"
	}
	return "standalone"
}

// Validate validates the note fields
func (n *Note) Validate() error {
	if n.Content == "" {
		return NewValidationError("content", "content is required")
	}
	if len(n.Content) > 10000 {
		return NewValidationError("content", "content must be 10000 characters or less")
	}
	if len(n.Tags) > 20 {
		return NewValidationError("tags", "maximum 20 tags allowed")
	}

	// Validate note type
	validTypes := map[NoteType]bool{
		NoteTypeGeneral:    true,
		NoteTypeProgress:   true,
		NoteTypeIdea:       true,
		NoteTypeIssue:      true,
		NoteTypeReflection: true,
		NoteTypeReminder:   true,
		NoteTypeResource:   true,
		NoteTypeMeeting:    true,
		NoteTypeDecision:   true,
		NoteTypeAction:     true,
	}
	if !validTypes[n.NoteType] {
		return NewValidationError("note_type", "invalid note type")
	}

	// Cannot be attached to both task and session
	if n.TaskID != nil && n.SessionID != nil {
		return NewValidationError("attachment", "note cannot be attached to both task and session")
	}

	return nil
}

// ExtractMentions extracts @mentions from note content
func (n *Note) ExtractMentions() []string {
	if n.Content == "" {
		return []string{}
	}

	// Simple regex to find @mentions
	re := regexp.MustCompile(`@(\w+)`)
	matches := re.FindAllStringSubmatch(n.Content, -1)

	mentions := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			mentions = append(mentions, match[1])
		}
	}

	return mentions
}

// ExtractHashtags extracts #hashtags from note content
func (n *Note) ExtractHashtags() []string {
	if n.Content == "" {
		return []string{}
	}

	// Simple regex to find #hashtags
	re := regexp.MustCompile(`#(\w+)`)
	matches := re.FindAllStringSubmatch(n.Content, -1)

	hashtags := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			hashtags = append(hashtags, match[1])
		}
	}

	return hashtags
}

// ExtractLinks extracts URLs from note content
func (n *Note) ExtractLinks() []string {
	if n.Content == "" {
		return []string{}
	}

	// Simple regex to find URLs
	re := regexp.MustCompile(`https?://[^\s]+`)
	return re.FindAllString(n.Content, -1)
}

// GetPreview returns a preview of the note content (first N characters)
func (n *Note) GetPreview(length int) string {
	if len(n.Content) <= length {
		return n.Content
	}

	// Try to break at word boundary
	preview := n.Content[:length]
	if lastSpace := strings.LastIndex(preview, " "); lastSpace > length/2 {
		preview = preview[:lastSpace]
	}

	return preview + "..."
}

// NoteFilter represents filters for note queries
type NoteFilter struct {
	UserID      string    `json:"user_id"`
	TaskID      *string   `json:"task_id,omitempty"`
	SessionID   *string   `json:"session_id,omitempty"`
	NoteType    *NoteType `json:"note_type,omitempty"`
	IsPinned    *bool     `json:"is_pinned,omitempty"`
	Tags        []string  `json:"tags,omitempty"`
	SearchQuery string    `json:"search_query,omitempty"`
	CreatedAfter *time.Time `json:"created_after,omitempty"`
	CreatedBefore *time.Time `json:"created_before,omitempty"`
	IsDeleted   bool      `json:"is_deleted"`
	Limit       int       `json:"limit"`
	Offset      int       `json:"offset"`
	SortBy      string    `json:"sort_by"`
	SortOrder   string    `json:"sort_order"`
}

// NoteSummary represents a summary of notes for a user
type NoteSummary struct {
	UserID         string             `json:"user_id"`
	TotalNotes     int                `json:"total_notes"`
	PinnedNotes    int                `json:"pinned_notes"`
	TaskNotes      int                `json:"task_notes"`
	SessionNotes   int                `json:"session_notes"`
	StandaloneNotes int               `json:"standalone_notes"`
	NotesByType    map[NoteType]int   `json:"notes_by_type"`
	TotalWordCount int                `json:"total_word_count"`
	AverageLength  float64            `json:"average_length"`
	MostUsedTags   []TagCount         `json:"most_used_tags"`
	LastUpdated    time.Time          `json:"last_updated"`
}

// TagCount represents a tag and its usage count
type TagCount struct {
	Tag   string `json:"tag"`
	Count int    `json:"count"`
}

// NoteTemplate represents a template for creating notes
type NoteTemplate struct {
	ID          string    `json:"id" db:"id"`
	UserID      string    `json:"user_id" db:"user_id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	Template    string    `json:"template" db:"template"`
	NoteType    NoteType  `json:"note_type" db:"note_type"`
	DefaultTags []string  `json:"default_tags" db:"default_tags"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
	UsageCount  int       `json:"usage_count" db:"usage_count"`
}

// NewNoteTemplate creates a new note template
func NewNoteTemplate(userID, name, description, template string, noteType NoteType) *NoteTemplate {
	now := time.Now()
	return &NoteTemplate{
		ID:          uuid.New().String(),
		UserID:      userID,
		Name:        name,
		Description: description,
		Template:    template,
		NoteType:    noteType,
		DefaultTags: []string{},
		CreatedAt:   now,
		UpdatedAt:   now,
		UsageCount:  0,
	}
}

// ApplyTemplate applies a template to create a note
func (nt *NoteTemplate) ApplyTemplate(userID string, variables map[string]string) *Note {
	content := nt.Template

	// Replace template variables
	for key, value := range variables {
		placeholder := "{{" + key + "}}"
		content = strings.ReplaceAll(content, placeholder, value)
	}

	note := NewNote(userID, content, nt.NoteType)
	note.SetTags(nt.DefaultTags)

	// Increment template usage count
	nt.UsageCount++
	nt.UpdatedAt = time.Now()

	return note
}

// NoteAnalytics represents analytics for notes
type NoteAnalytics struct {
	UserID              string             `json:"user_id"`
	Period              string             `json:"period"` // "day", "week", "month"
	NotesCreated        int                `json:"notes_created"`
	NotesUpdated        int                `json:"notes_updated"`
	NotesDeleted        int                `json:"notes_deleted"`
	AverageNoteLength   float64            `json:"average_note_length"`
	MostActiveDay       string             `json:"most_active_day"`
	MostActiveHour      int                `json:"most_active_hour"`
	PopularNoteTypes    map[NoteType]int   `json:"popular_note_types"`
	WritingProductivity struct {
		WordsPerDay       float64 `json:"words_per_day"`
		NotesPerSession   float64 `json:"notes_per_session"`
		PeakWritingHours  []int   `json:"peak_writing_hours"`
		WritingStreak     int     `json:"writing_streak"` // consecutive days with notes
	} `json:"writing_productivity"`
	LastAnalyzed time.Time `json:"last_analyzed"`
}