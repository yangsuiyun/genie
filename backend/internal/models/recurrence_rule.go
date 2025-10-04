package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// RecurrenceRule represents a rule for recurring tasks or reminders
type RecurrenceRule struct {
	ID              string             `json:"id" db:"id"`
	Frequency       RecurrenceFrequency `json:"frequency" db:"frequency"`
	Interval        int                `json:"interval" db:"interval"`                 // Every N frequencies (e.g., every 2 weeks)
	DaysOfWeek      []Weekday          `json:"days_of_week,omitempty" db:"days_of_week"`
	DaysOfMonth     []int              `json:"days_of_month,omitempty" db:"days_of_month"`
	MonthsOfYear    []int              `json:"months_of_year,omitempty" db:"months_of_year"`
	WeekOfMonth     *WeekOfMonth       `json:"week_of_month,omitempty" db:"week_of_month"`
	DayOfMonth      *DayOfMonth        `json:"day_of_month,omitempty" db:"day_of_month"`
	StartDate       time.Time          `json:"start_date" db:"start_date"`
	EndDate         *time.Time         `json:"end_date,omitempty" db:"end_date"`
	Count           *int               `json:"count,omitempty" db:"count"`             // Maximum number of occurrences
	BySetPos        []int              `json:"by_set_pos,omitempty" db:"by_set_pos"`   // Which occurrence within the set
	TimeOfDay       string             `json:"time_of_day" db:"time_of_day"`           // HH:MM format
	Timezone        string             `json:"timezone" db:"timezone"`
	SkipWeekends    bool               `json:"skip_weekends" db:"skip_weekends"`
	SkipHolidays    bool               `json:"skip_holidays" db:"skip_holidays"`
	Exceptions      []time.Time        `json:"exceptions,omitempty" db:"exceptions"`   // Specific dates to skip
	Includes        []time.Time        `json:"includes,omitempty" db:"includes"`       // Additional specific dates
	CreatedAt       time.Time          `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time          `json:"updated_at" db:"updated_at"`
}

// RecurrenceFrequency represents how often the recurrence happens
type RecurrenceFrequency string

const (
	FrequencyDaily   RecurrenceFrequency = "daily"
	FrequencyWeekly  RecurrenceFrequency = "weekly"
	FrequencyMonthly RecurrenceFrequency = "monthly"
	FrequencyYearly  RecurrenceFrequency = "yearly"
	FrequencyHourly  RecurrenceFrequency = "hourly"
)

// Weekday represents days of the week
type Weekday string

const (
	Sunday    Weekday = "sunday"
	Monday    Weekday = "monday"
	Tuesday   Weekday = "tuesday"
	Wednesday Weekday = "wednesday"
	Thursday  Weekday = "thursday"
	Friday    Weekday = "friday"
	Saturday  Weekday = "saturday"
)

// WeekOfMonth represents which week of the month
type WeekOfMonth string

const (
	WeekFirst  WeekOfMonth = "first"
	WeekSecond WeekOfMonth = "second"
	WeekThird  WeekOfMonth = "third"
	WeekFourth WeekOfMonth = "fourth"
	WeekLast   WeekOfMonth = "last"
)

// DayOfMonth represents special day calculations for monthly recurrence
type DayOfMonth string

const (
	DayLastDay       DayOfMonth = "last_day"
	DayLastWeekday   DayOfMonth = "last_weekday"
	DayLastMonday    DayOfMonth = "last_monday"
	DayLastTuesday   DayOfMonth = "last_tuesday"
	DayLastWednesday DayOfMonth = "last_wednesday"
	DayLastThursday  DayOfMonth = "last_thursday"
	DayLastFriday    DayOfMonth = "last_friday"
	DayLastSaturday  DayOfMonth = "last_saturday"
	DayLastSunday    DayOfMonth = "last_sunday"
)

// NewRecurrenceRule creates a new recurrence rule
func NewRecurrenceRule(frequency RecurrenceFrequency, interval int, startDate time.Time, timeOfDay, timezone string) *RecurrenceRule {
	now := time.Now()
	return &RecurrenceRule{
		ID:          uuid.New().String(),
		Frequency:   frequency,
		Interval:    interval,
		StartDate:   startDate,
		TimeOfDay:   timeOfDay,
		Timezone:    timezone,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

// NewDailyRule creates a daily recurrence rule
func NewDailyRule(startDate time.Time, timeOfDay, timezone string, interval int) *RecurrenceRule {
	rule := NewRecurrenceRule(FrequencyDaily, interval, startDate, timeOfDay, timezone)
	return rule
}

// NewWeeklyRule creates a weekly recurrence rule
func NewWeeklyRule(startDate time.Time, timeOfDay, timezone string, interval int, daysOfWeek []Weekday) *RecurrenceRule {
	rule := NewRecurrenceRule(FrequencyWeekly, interval, startDate, timeOfDay, timezone)
	rule.DaysOfWeek = daysOfWeek
	return rule
}

// NewMonthlyRule creates a monthly recurrence rule
func NewMonthlyRule(startDate time.Time, timeOfDay, timezone string, interval int, daysOfMonth []int) *RecurrenceRule {
	rule := NewRecurrenceRule(FrequencyMonthly, interval, startDate, timeOfDay, timezone)
	rule.DaysOfMonth = daysOfMonth
	return rule
}

// NewMonthlyByWeekRule creates a monthly recurrence rule by week (e.g., "first Monday")
func NewMonthlyByWeekRule(startDate time.Time, timeOfDay, timezone string, interval int, weekOfMonth WeekOfMonth, dayOfWeek Weekday) *RecurrenceRule {
	rule := NewRecurrenceRule(FrequencyMonthly, interval, startDate, timeOfDay, timezone)
	rule.WeekOfMonth = &weekOfMonth
	rule.DaysOfWeek = []Weekday{dayOfWeek}
	return rule
}

// NewYearlyRule creates a yearly recurrence rule
func NewYearlyRule(startDate time.Time, timeOfDay, timezone string, interval int, monthsOfYear []int, daysOfMonth []int) *RecurrenceRule {
	rule := NewRecurrenceRule(FrequencyYearly, interval, startDate, timeOfDay, timezone)
	rule.MonthsOfYear = monthsOfYear
	rule.DaysOfMonth = daysOfMonth
	return rule
}

// SetEndDate sets an end date for the recurrence
func (r *RecurrenceRule) SetEndDate(endDate time.Time) {
	r.EndDate = &endDate
	r.UpdatedAt = time.Now()
}

// SetCount sets a maximum count for occurrences
func (r *RecurrenceRule) SetCount(count int) {
	r.Count = &count
	r.UpdatedAt = time.Now()
}

// AddException adds a date to skip
func (r *RecurrenceRule) AddException(date time.Time) {
	r.Exceptions = append(r.Exceptions, date)
	r.UpdatedAt = time.Now()
}

// RemoveException removes a date from exceptions
func (r *RecurrenceRule) RemoveException(date time.Time) {
	for i, exception := range r.Exceptions {
		if exception.Equal(date) {
			r.Exceptions = append(r.Exceptions[:i], r.Exceptions[i+1:]...)
			r.UpdatedAt = time.Now()
			return
		}
	}
}

// AddInclude adds a specific date to include
func (r *RecurrenceRule) AddInclude(date time.Time) {
	r.Includes = append(r.Includes, date)
	r.UpdatedAt = time.Now()
}

// RemoveInclude removes a date from includes
func (r *RecurrenceRule) RemoveInclude(date time.Time) {
	for i, include := range r.Includes {
		if include.Equal(date) {
			r.Includes = append(r.Includes[:i], r.Includes[i+1:]...)
			r.UpdatedAt = time.Now()
			return
		}
	}
}

// GetNextOccurrence calculates the next occurrence after the given date
func (r *RecurrenceRule) GetNextOccurrence(after time.Time) (*time.Time, error) {
	location, err := time.LoadLocation(r.Timezone)
	if err != nil {
		location = time.UTC
	}

	// Parse time of day
	timeOfDay, err := time.Parse("15:04", r.TimeOfDay)
	if err != nil {
		return nil, fmt.Errorf("invalid time format: %v", err)
	}

	var next time.Time
	switch r.Frequency {
	case FrequencyDaily:
		next = r.calculateNextDaily(after, location, timeOfDay)
	case FrequencyWeekly:
		next = r.calculateNextWeekly(after, location, timeOfDay)
	case FrequencyMonthly:
		next = r.calculateNextMonthly(after, location, timeOfDay)
	case FrequencyYearly:
		next = r.calculateNextYearly(after, location, timeOfDay)
	case FrequencyHourly:
		next = r.calculateNextHourly(after, location)
	default:
		return nil, fmt.Errorf("unsupported frequency: %s", r.Frequency)
	}

	// Check if next occurrence is within bounds
	if r.EndDate != nil && next.After(*r.EndDate) {
		return nil, nil // No more occurrences
	}

	// Check exceptions
	for _, exception := range r.Exceptions {
		if next.Equal(exception) {
			// Skip this occurrence and find the next one
			return r.GetNextOccurrence(next)
		}
	}

	// Skip weekends if configured
	if r.SkipWeekends && (next.Weekday() == time.Saturday || next.Weekday() == time.Sunday) {
		return r.GetNextOccurrence(next)
	}

	// TODO: Implement holiday checking if SkipHolidays is true

	return &next, nil
}

// calculateNextDaily calculates the next daily occurrence
func (r *RecurrenceRule) calculateNextDaily(after time.Time, location *time.Location, timeOfDay time.Time) time.Time {
	next := after.In(location)

	// Set to the specified time of day
	next = time.Date(next.Year(), next.Month(), next.Day(), timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)

	// If the time has already passed today, move to tomorrow
	if next.Before(after) || next.Equal(after) {
		next = next.AddDate(0, 0, 1)
	}

	// Apply interval
	if r.Interval > 1 {
		daysSinceStart := int(next.Sub(r.StartDate).Hours() / 24)
		if daysSinceStart%r.Interval != 0 {
			daysToAdd := r.Interval - (daysSinceStart % r.Interval)
			next = next.AddDate(0, 0, daysToAdd)
		}
	}

	return next
}

// calculateNextWeekly calculates the next weekly occurrence
func (r *RecurrenceRule) calculateNextWeekly(after time.Time, location *time.Location, timeOfDay time.Time) time.Time {
	next := after.In(location)

	// If no specific days are set, use the start date's weekday
	daysOfWeek := r.DaysOfWeek
	if len(daysOfWeek) == 0 {
		daysOfWeek = []Weekday{weekdayToWeekday(r.StartDate.Weekday())}
	}

	// Find the next occurrence within the current week
	for i := 0; i < 7; i++ {
		candidate := next.AddDate(0, 0, i)
		candidateWeekday := weekdayToWeekday(candidate.Weekday())

		for _, day := range daysOfWeek {
			if candidateWeekday == day {
				candidate = time.Date(candidate.Year(), candidate.Month(), candidate.Day(), timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)
				if candidate.After(after) {
					return candidate
				}
			}
		}
	}

	// If no occurrence found in current week, move to next interval
	next = next.AddDate(0, 0, 7*r.Interval)
	return r.calculateNextWeekly(next.Add(-24*time.Hour), location, timeOfDay)
}

// calculateNextMonthly calculates the next monthly occurrence
func (r *RecurrenceRule) calculateNextMonthly(after time.Time, location *time.Location, timeOfDay time.Time) time.Time {
	next := after.In(location)

	// Handle specific days of month
	if len(r.DaysOfMonth) > 0 {
		for i := 0; i < 12*r.Interval; i++ {
			candidate := next.AddDate(0, i, 0)
			for _, day := range r.DaysOfMonth {
				if day <= daysInMonth(candidate.Year(), candidate.Month()) {
					candidateTime := time.Date(candidate.Year(), candidate.Month(), day, timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)
					if candidateTime.After(after) {
						return candidateTime
					}
				}
			}
		}
	}

	// Handle week-based monthly recurrence (e.g., "first Monday")
	if r.WeekOfMonth != nil && len(r.DaysOfWeek) > 0 {
		for i := 0; i < 12*r.Interval; i++ {
			candidate := next.AddDate(0, i, 0)
			candidateTime := r.calculateWeekdayInMonth(candidate.Year(), candidate.Month(), *r.WeekOfMonth, r.DaysOfWeek[0], timeOfDay, location)
			if candidateTime != nil && candidateTime.After(after) {
				return *candidateTime
			}
		}
	}

	// Default to same day of month as start date
	day := r.StartDate.Day()
	for i := 0; i < 12*r.Interval; i++ {
		candidate := next.AddDate(0, i, 0)
		if day <= daysInMonth(candidate.Year(), candidate.Month()) {
			candidateTime := time.Date(candidate.Year(), candidate.Month(), day, timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)
			if candidateTime.After(after) {
				return candidateTime
			}
		}
	}

	return next.AddDate(0, r.Interval, 0)
}

// calculateNextYearly calculates the next yearly occurrence
func (r *RecurrenceRule) calculateNextYearly(after time.Time, location *time.Location, timeOfDay time.Time) time.Time {
	next := after.In(location)

	monthsOfYear := r.MonthsOfYear
	if len(monthsOfYear) == 0 {
		monthsOfYear = []int{int(r.StartDate.Month())}
	}

	daysOfMonth := r.DaysOfMonth
	if len(daysOfMonth) == 0 {
		daysOfMonth = []int{r.StartDate.Day()}
	}

	for i := 0; i < 10*r.Interval; i++ {
		year := next.Year() + i
		for _, month := range monthsOfYear {
			for _, day := range daysOfMonth {
				if day <= daysInMonth(year, time.Month(month)) {
					candidateTime := time.Date(year, time.Month(month), day, timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)
					if candidateTime.After(after) {
						return candidateTime
					}
				}
			}
		}
	}

	return next.AddDate(r.Interval, 0, 0)
}

// calculateNextHourly calculates the next hourly occurrence
func (r *RecurrenceRule) calculateNextHourly(after time.Time, location *time.Location) time.Time {
	next := after.In(location)

	// Round up to the next hour
	next = time.Date(next.Year(), next.Month(), next.Day(), next.Hour()+1, 0, 0, 0, location)

	// Apply interval
	if r.Interval > 1 {
		hoursSinceStart := int(next.Sub(r.StartDate).Hours())
		if hoursSinceStart%r.Interval != 0 {
			hoursToAdd := r.Interval - (hoursSinceStart % r.Interval)
			next = next.Add(time.Duration(hoursToAdd) * time.Hour)
		}
	}

	return next
}

// calculateWeekdayInMonth calculates a specific weekday in a month (e.g., "first Monday")
func (r *RecurrenceRule) calculateWeekdayInMonth(year int, month time.Month, week WeekOfMonth, weekday Weekday, timeOfDay time.Time, location *time.Location) *time.Time {
	firstDay := time.Date(year, month, 1, timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location)
	targetWeekday := weekdayToTimeWeekday(weekday)

	// Find the first occurrence of the target weekday in the month
	daysToAdd := int(targetWeekday - firstDay.Weekday())
	if daysToAdd < 0 {
		daysToAdd += 7
	}

	firstOccurrence := firstDay.AddDate(0, 0, daysToAdd)

	switch week {
	case WeekFirst:
		if firstOccurrence.Month() == month {
			return &firstOccurrence
		}
	case WeekSecond:
		secondOccurrence := firstOccurrence.AddDate(0, 0, 7)
		if secondOccurrence.Month() == month {
			return &secondOccurrence
		}
	case WeekThird:
		thirdOccurrence := firstOccurrence.AddDate(0, 0, 14)
		if thirdOccurrence.Month() == month {
			return &thirdOccurrence
		}
	case WeekFourth:
		fourthOccurrence := firstOccurrence.AddDate(0, 0, 21)
		if fourthOccurrence.Month() == month {
			return &fourthOccurrence
		}
	case WeekLast:
		// Find the last occurrence by going backwards from the end of the month
		lastDay := time.Date(year, month+1, 0, timeOfDay.Hour(), timeOfDay.Minute(), 0, 0, location) // Last day of month
		daysBack := int(lastDay.Weekday() - targetWeekday)
		if daysBack < 0 {
			daysBack += 7
		}
		lastOccurrence := lastDay.AddDate(0, 0, -daysBack)
		if lastOccurrence.Month() == month {
			return &lastOccurrence
		}
	}

	return nil
}

// GetAllOccurrences returns all occurrences within a date range
func (r *RecurrenceRule) GetAllOccurrences(start, end time.Time, maxCount int) ([]time.Time, error) {
	var occurrences []time.Time
	current := start
	count := 0

	for count < maxCount {
		next, err := r.GetNextOccurrence(current)
		if err != nil {
			return nil, err
		}
		if next == nil || next.After(end) {
			break
		}

		occurrences = append(occurrences, *next)
		current = *next
		count++

		// Check count limit
		if r.Count != nil && count >= *r.Count {
			break
		}
	}

	// Add any specific includes within the range
	for _, include := range r.Includes {
		if include.After(start) && include.Before(end) {
			// Insert in chronological order
			inserted := false
			for i, occurrence := range occurrences {
				if include.Before(occurrence) {
					occurrences = append(occurrences[:i], append([]time.Time{include}, occurrences[i:]...)...)
					inserted = true
					break
				}
			}
			if !inserted {
				occurrences = append(occurrences, include)
			}
		}
	}

	return occurrences, nil
}

// Validate validates the recurrence rule
func (r *RecurrenceRule) Validate() error {
	// Validate frequency
	validFrequencies := map[RecurrenceFrequency]bool{
		FrequencyDaily:   true,
		FrequencyWeekly:  true,
		FrequencyMonthly: true,
		FrequencyYearly:  true,
		FrequencyHourly:  true,
	}
	if !validFrequencies[r.Frequency] {
		return NewValidationError("frequency", "invalid frequency")
	}

	// Validate interval
	if r.Interval < 1 || r.Interval > 999 {
		return NewValidationError("interval", "interval must be between 1 and 999")
	}

	// Validate days of month
	for _, day := range r.DaysOfMonth {
		if day < 1 || day > 31 {
			return NewValidationError("days_of_month", "day of month must be between 1 and 31")
		}
	}

	// Validate months of year
	for _, month := range r.MonthsOfYear {
		if month < 1 || month > 12 {
			return NewValidationError("months_of_year", "month must be between 1 and 12")
		}
	}

	// Validate time format
	if _, err := time.Parse("15:04", r.TimeOfDay); err != nil {
		return NewValidationError("time_of_day", "time must be in HH:MM format")
	}

	// Validate timezone
	if _, err := time.LoadLocation(r.Timezone); err != nil {
		return NewValidationError("timezone", "invalid timezone")
	}

	// Validate end date is after start date
	if r.EndDate != nil && r.EndDate.Before(r.StartDate) {
		return NewValidationError("end_date", "end date must be after start date")
	}

	// Validate count
	if r.Count != nil && (*r.Count < 1 || *r.Count > 1000) {
		return NewValidationError("count", "count must be between 1 and 1000")
	}

	return nil
}

// Helper functions

// weekdayToWeekday converts time.Weekday to our Weekday type
func weekdayToWeekday(wd time.Weekday) Weekday {
	switch wd {
	case time.Sunday:
		return Sunday
	case time.Monday:
		return Monday
	case time.Tuesday:
		return Tuesday
	case time.Wednesday:
		return Wednesday
	case time.Thursday:
		return Thursday
	case time.Friday:
		return Friday
	case time.Saturday:
		return Saturday
	default:
		return Sunday
	}
}

// weekdayToTimeWeekday converts our Weekday type to time.Weekday
func weekdayToTimeWeekday(wd Weekday) time.Weekday {
	switch wd {
	case Sunday:
		return time.Sunday
	case Monday:
		return time.Monday
	case Tuesday:
		return time.Tuesday
	case Wednesday:
		return time.Wednesday
	case Thursday:
		return time.Thursday
	case Friday:
		return time.Friday
	case Saturday:
		return time.Saturday
	default:
		return time.Sunday
	}
}

// daysInMonth returns the number of days in a given month/year
func daysInMonth(year int, month time.Month) int {
	return time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
}

// IsValid checks if the recurrence rule is valid and can generate occurrences
func (r *RecurrenceRule) IsValid() bool {
	return r.Validate() == nil
}

// GetDescription returns a human-readable description of the recurrence rule
func (r *RecurrenceRule) GetDescription() string {
	switch r.Frequency {
	case FrequencyDaily:
		if r.Interval == 1 {
			return "Daily"
		}
		return fmt.Sprintf("Every %d days", r.Interval)
	case FrequencyWeekly:
		if r.Interval == 1 && len(r.DaysOfWeek) == 1 {
			return fmt.Sprintf("Weekly on %s", r.DaysOfWeek[0])
		}
		if r.Interval == 1 {
			return fmt.Sprintf("Weekly on %s", formatDaysOfWeek(r.DaysOfWeek))
		}
		return fmt.Sprintf("Every %d weeks", r.Interval)
	case FrequencyMonthly:
		if r.Interval == 1 {
			return "Monthly"
		}
		return fmt.Sprintf("Every %d months", r.Interval)
	case FrequencyYearly:
		if r.Interval == 1 {
			return "Yearly"
		}
		return fmt.Sprintf("Every %d years", r.Interval)
	case FrequencyHourly:
		if r.Interval == 1 {
			return "Hourly"
		}
		return fmt.Sprintf("Every %d hours", r.Interval)
	}
	return "Custom recurrence"
}

// formatDaysOfWeek formats a list of weekdays for display
func formatDaysOfWeek(days []Weekday) string {
	if len(days) == 0 {
		return ""
	}
	if len(days) == 1 {
		return string(days[0])
	}

	result := ""
	for i, day := range days {
		if i > 0 {
			if i == len(days)-1 {
				result += " and "
			} else {
				result += ", "
			}
		}
		result += string(day)
	}
	return result
}