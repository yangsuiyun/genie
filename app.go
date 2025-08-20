package main

import (
	"context"
	"sync"
	"time"
)

// App struct
type App struct {
	ctx   context.Context
	timer *PomodoroTimer
}

// TimerState represents the current state of the timer
type TimerState string

const (
	StateIdle    TimerState = "idle"
	StateWorking TimerState = "working"
	StateBreak   TimerState = "break"
	StateLongBreak TimerState = "longBreak"
	StatePaused  TimerState = "paused"
)

// PomodoroTimer manages the pomodoro timer logic
type PomodoroTimer struct {
	mu            sync.RWMutex
	state         TimerState
	remainingTime int // seconds
	currentCycle  int
	completedPomodoros int
	ticker        *time.Ticker
	stopChan      chan bool
	
	// Settings
	workDuration     int // minutes
	shortBreakDuration int // minutes
	longBreakDuration  int // minutes
	longBreakInterval  int // pomodoros before long break
}

// TimerStatus represents the current timer status for frontend
type TimerStatus struct {
	State         TimerState `json:"state"`
	RemainingTime int        `json:"remainingTime"`
	CurrentCycle  int        `json:"currentCycle"`
	CompletedPomodoros int   `json:"completedPomodoros"`
}

// NewApp creates a new App application struct
func NewApp() *App {
	return &App{
		timer: NewPomodoroTimer(),
	}
}

// NewPomodoroTimer creates a new pomodoro timer with default settings
func NewPomodoroTimer() *PomodoroTimer {
	return &PomodoroTimer{
		state:              StateIdle,
		remainingTime:      0,
		currentCycle:       1,
		completedPomodoros: 0,
		stopChan:           make(chan bool),
		
		// Default settings
		workDuration:       25,
		shortBreakDuration: 5,
		longBreakDuration:  15,
		longBreakInterval:  4,
	}
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

// StartTimer starts a new pomodoro session
func (a *App) StartTimer() TimerStatus {
	a.timer.mu.Lock()
	defer a.timer.mu.Unlock()
	
	if a.timer.state == StateIdle {
		a.timer.state = StateWorking
		a.timer.remainingTime = a.timer.workDuration * 60 // convert to seconds
		a.timer.startTicking()
	} else if a.timer.state == StatePaused {
		a.timer.state = StateWorking
		a.timer.startTicking()
	}
	
	return a.getStatus()
}

// PauseTimer pauses the current session
func (a *App) PauseTimer() TimerStatus {
	a.timer.mu.Lock()
	defer a.timer.mu.Unlock()
	
	if a.timer.state == StateWorking || a.timer.state == StateBreak || a.timer.state == StateLongBreak {
		a.timer.state = StatePaused
		a.timer.stopTicking()
	}
	
	return a.getStatus()
}

// StopTimer stops and resets the timer
func (a *App) StopTimer() TimerStatus {
	a.timer.mu.Lock()
	defer a.timer.mu.Unlock()
	
	a.timer.state = StateIdle
	a.timer.remainingTime = 0
	a.timer.currentCycle = 1
	a.timer.stopTicking()
	
	return a.getStatus()
}

// GetTimerStatus returns the current timer status
func (a *App) GetTimerStatus() TimerStatus {
	a.timer.mu.RLock()
	defer a.timer.mu.RUnlock()
	return a.getStatus()
}

// getStatus returns the current status (must be called with lock held)
func (a *App) getStatus() TimerStatus {
	return TimerStatus{
		State:              a.timer.state,
		RemainingTime:      a.timer.remainingTime,
		CurrentCycle:       a.timer.currentCycle,
		CompletedPomodoros: a.timer.completedPomodoros,
	}
}

// startTicking starts the timer countdown
func (t *PomodoroTimer) startTicking() {
	if t.ticker != nil {
		t.ticker.Stop()
	}
	
	t.ticker = time.NewTicker(1 * time.Second)
	
	go func() {
		for {
			select {
			case <-t.ticker.C:
				t.mu.Lock()
				t.remainingTime--
				
				if t.remainingTime <= 0 {
					t.handleTimerComplete()
				}
				t.mu.Unlock()
				
			case <-t.stopChan:
				return
			}
		}
	}()
}

// stopTicking stops the timer countdown
func (t *PomodoroTimer) stopTicking() {
	if t.ticker != nil {
		t.ticker.Stop()
		t.ticker = nil
	}
	
	select {
	case t.stopChan <- true:
	default:
	}
}

// handleTimerComplete handles timer completion and state transitions
func (t *PomodoroTimer) handleTimerComplete() {
	switch t.state {
	case StateWorking:
		t.completedPomodoros++
		
		// Determine break type
		if t.completedPomodoros%t.longBreakInterval == 0 {
			t.state = StateLongBreak
			t.remainingTime = t.longBreakDuration * 60
		} else {
			t.state = StateBreak
			t.remainingTime = t.shortBreakDuration * 60
		}
		
	case StateBreak, StateLongBreak:
		t.state = StateWorking
		t.currentCycle++
		t.remainingTime = t.workDuration * 60
	}
	
	// Continue ticking for the next phase
	t.startTicking()
}

// UpdateSettings updates timer settings
func (a *App) UpdateSettings(workDuration, shortBreak, longBreak, longBreakInterval int) {
	a.timer.mu.Lock()
	defer a.timer.mu.Unlock()
	
	a.timer.workDuration = workDuration
	a.timer.shortBreakDuration = shortBreak
	a.timer.longBreakDuration = longBreak
	a.timer.longBreakInterval = longBreakInterval
}

// GetSettings returns current timer settings
func (a *App) GetSettings() map[string]int {
	a.timer.mu.RLock()
	defer a.timer.mu.RUnlock()
	
	return map[string]int{
		"workDuration":       a.timer.workDuration,
		"shortBreakDuration": a.timer.shortBreakDuration,
		"longBreakDuration":  a.timer.longBreakDuration,
		"longBreakInterval":  a.timer.longBreakInterval,
	}
}
