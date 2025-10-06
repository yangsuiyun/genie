# TimerDisplay Component

**Component Type**: display
**Complexity Level**: moderate
**Dependencies**: Audio API, Notification API, Web Workers
**Estimated Implementation Time**: 8 hours

## Component Metadata

- **component_name**: TimerDisplay
- **component_type**: display
- **complexity_level**: moderate
- **dependencies**: [Audio API, Notification API, Web Workers, localStorage]
- **estimated_implementation_time**: 8 hours

## Purpose

The TimerDisplay component provides the core countdown timer interface within the PomodoroModal, featuring a circular progress indicator, time display, and session status. It handles precise timing, visual feedback, and user interactions for work and break sessions while maintaining accuracy even when the browser tab is inactive.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| duration | number | true | 1500 | 300-7200 | Session duration in seconds |
| sessionType | string | true | 'work' | work\|short_break\|long_break | Type of timer session |
| isRunning | boolean | false | false | true\|false | Whether timer is currently active |
| timeRemaining | number | false | null | 0-7200 | Override remaining time |
| onTimeUpdate | function | false | null | Valid function | Callback for time updates (every second) |
| onComplete | function | true | null | Valid function | Callback when timer reaches zero |
| onToggle | function | true | null | Valid function | Callback for start/pause toggle |
| showProgress | boolean | false | true | true\|false | Whether to show circular progress |
| showMilliseconds | boolean | false | false | true\|false | Display precision to milliseconds |
| soundEnabled | boolean | false | true | true\|false | Enable completion sound |
| notificationsEnabled | boolean | false | true | true\|false | Enable browser notifications |
| theme | string | false | 'default' | Valid theme name | Visual theme for timer |
| size | string | false | 'large' | small\|medium\|large | Display size variant |

## Visual States

### Work Session
- **Colors**: Primary red theme (#ff6b6b) for work focus
- **Progress**: Red circular progress ring
- **Background**: Clean white with subtle red accents
- **Animation**: Smooth progress animation with subtle pulse

### Short Break
- **Colors**: Calming blue theme (#45b7d1) for rest
- **Progress**: Blue circular progress ring
- **Background**: Light blue tinted background
- **Animation**: Relaxed animation timing

### Long Break
- **Colors**: Refreshing green theme (#66bb6a) for extended rest
- **Progress**: Green circular progress ring
- **Background**: Light green tinted background
- **Animation**: Gentle, slow animations

### Running State
- **Indicator**: Active progress animation
- **Pulse**: Subtle breathing animation on timer circle
- **Focus**: Enhanced visual prominence
- **Live**: Real-time countdown updates

### Paused State
- **Overlay**: Semi-transparent pause indicator
- **Animation**: Frozen progress animation
- **Visual**: Muted colors to indicate inactive state
- **Feedback**: Clear pause symbol overlay

### Completed State
- **Animation**: Completion celebration (brief flash or pulse)
- **Sound**: Completion notification sound
- **Visual**: 00:00 display with completion styling
- **Feedback**: Success state with appropriate colors

## Accessibility

### Keyboard Navigation
- **Focus**: Timer can receive focus for screen reader access
- **Shortcuts**: Space bar for pause/resume, R for reset
- **Navigation**: No internal navigation (single component)

### Screen Reader Support
- **aria-label**: "Pomodoro timer: X minutes Y seconds remaining"
- **aria-live**: "assertive" for time updates every minute
- **Role**: "timer" with live updates
- **Status**: Session type and remaining time announced

### Visual Indicators
- **Progress**: Multiple ways to indicate progress (visual + text)
- **Status**: Clear visual indication of running/paused states
- **Completion**: Multiple completion indicators (visual + audio + notification)

## Responsive Behavior

### Large Size (Default)
- **Diameter**: 280px circle
- **Font**: 52px for time display
- **Progress**: 8px stroke width
- **Spacing**: Generous padding around elements

### Medium Size
- **Diameter**: 200px circle
- **Font**: 36px for time display
- **Progress**: 6px stroke width
- **Spacing**: Moderate padding for tablet use

### Small Size
- **Diameter**: 120px circle
- **Font**: 24px for time display
- **Progress**: 4px stroke width
- **Spacing**: Compact layout for mobile or sidebar

### Mobile Optimization
- **Touch**: Enhanced touch area for pause/resume
- **Size**: Automatically adjusts based on viewport
- **Performance**: Optimized animations for mobile devices

## Integration Points

### Timer Management
- **Precision**: High-resolution timing using requestAnimationFrame
- **Background**: Web Worker for accurate background timing
- **Recovery**: Sync time on tab focus recovery
- **Persistence**: Save timer state to localStorage

### Audio Integration
- **Completion Sound**: Web Audio API for completion notifications
- **Volume Control**: Configurable volume levels
- **Format**: Optimized audio files for quick loading
- **Fallback**: Silent operation if audio fails

### Notification Integration
- **Browser Notifications**: Native notification API
- **Permission**: Request and handle notification permissions
- **Content**: Informative notification messages
- **Fallback**: Visual-only feedback if notifications disabled

### State Synchronization
- **Session State**: Sync with parent PomodoroModal state
- **Global State**: Update app-wide timer status
- **Storage**: Persist timer state across browser sessions
- **Recovery**: Resume timer after page refresh

## Data Structure

### Timer State Schema
```javascript
{
  duration: 1500,
  timeRemaining: 1500,
  sessionType: 'work',
  isRunning: false,
  isPaused: false,
  isCompleted: false,
  startTime: null,
  pausedTime: 0,
  lastUpdate: null,
  cycles: {
    completed: 2,
    total: 4
  }
}
```

### Session Configuration
```javascript
{
  work: {
    duration: 1500,
    color: '#ff6b6b',
    sound: 'work-complete.mp3',
    message: 'Work session complete!'
  },
  short_break: {
    duration: 300,
    color: '#45b7d1',
    sound: 'break-complete.mp3',
    message: 'Break time over!'
  },
  long_break: {
    duration: 900,
    color: '#66bb6a',
    sound: 'long-break-complete.mp3',
    message: 'Long break complete!'
  }
}
```

## Wireframe

```
                    ┌─────────────────┐
                    │                 │
                ┌───│                 │───┐
             ┌──│   │                 │   │──┐
           ┌─│  │   │      25:00      │   │  │─┐
         ┌─│ │  │   │                 │   │  │ │─┐
       ┌─│  │ │  │   │   工作时间      │   │  │ │  │─┐
     ┌─│   │ │ │  │   │               │   │  │ │ │   │─┐
    │ │    │ │││  │   │               │   │  │││ │    │ │
   ┌│ │    │ │││  │   └─────────────────┘   │  │││ │    │ │┐
  ┌││ │    │ │││  │                         │  │││ │    │ ││┐
 ┌│││ │    │ │││  │      [▶️ 开始]          │  │││ │    │ │││┐
 ││││ │    │ │││  │      [⏸️ 暂停]          │  │││ │    │ ││││
 ││││ │    │ │││  │      [🔄 重置]          │  │││ │    │ ││││
 │││└─│    │ │││  │                         │  │││ │    │─┘│││
 ││└──│    │ │││  │                         │  │││ │    │──┘││
 │└───│    │ │││  │                         │  │││ │    │───┘│
  └───│    │ │││  │                         │  │││ │    │───┘
      └─   │ │││  │                         │  │││ │   ─┘
        └──│ │││  │                         │  │││ │──┘
          └│ │││  │                         │  │││ │┘
           └││││  │                         │  ││││┘
            │││└──│                         │──┘│││
             ││└──│                         │──┘││
              │└──│                         │──┘│
               └──│                         │──┘
                  └─────────────────────────┘

           ████████████████████░░░░░░░░  67%
```

## Implementation Notes

### CSS Classes
```css
.timer-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  user-select: none;
}

.timer-circle {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.timer-circle:hover {
  transform: scale(1.02);
}

.timer-circle.running {
  animation: timerPulse 2s ease-in-out infinite;
}

@keyframes timerPulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(255, 107, 107, 0.4);
  }
  50% {
    box-shadow: 0 0 0 20px rgba(255, 107, 107, 0);
  }
}

.timer-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
  position: absolute;
  top: 0;
  left: 0;
}

.timer-progress-bg {
  fill: none;
  stroke: var(--border-color);
  stroke-width: 8;
}

.timer-progress {
  fill: none;
  stroke: var(--timer-color);
  stroke-width: 8;
  stroke-linecap: round;
  transition: stroke-dashoffset 1s ease;
  filter: drop-shadow(0 0 6px rgba(255, 107, 107, 0.3));
}

.timer-content {
  position: relative;
  z-index: 1;
  text-align: center;
  pointer-events: none;
}

.timer-time {
  font-size: var(--timer-font-size);
  font-weight: 800;
  color: var(--text-primary);
  font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
  line-height: 1;
  margin-bottom: 8px;
  text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.timer-label {
  font-size: 16px;
  color: var(--text-secondary);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.timer-controls {
  margin-top: 24px;
  display: flex;
  gap: 16px;
  justify-content: center;
}

.timer-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 24px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: var(--shadow-light);
}

.timer-btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-medium);
}

.timer-btn.primary {
  background: var(--timer-color);
  color: white;
}

.timer-btn.secondary {
  background: var(--surface-color);
  color: var(--text-primary);
  border: 2px solid var(--border-color);
}

.pause-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(255, 255, 255, 0.95);
  border-radius: 50%;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}

.timer-circle.paused .pause-overlay {
  opacity: 1;
}

/* Size variants */
.timer-display.small {
  --timer-size: 120px;
  --timer-font-size: 24px;
}

.timer-display.medium {
  --timer-size: 200px;
  --timer-font-size: 36px;
}

.timer-display.large {
  --timer-size: 280px;
  --timer-font-size: 52px;
}

.timer-circle {
  width: var(--timer-size);
  height: var(--timer-size);
}

/* Theme variants */
.timer-display.work {
  --timer-color: #ff6b6b;
}

.timer-display.short-break {
  --timer-color: #45b7d1;
}

.timer-display.long-break {
  --timer-color: #66bb6a;
}

/* Completion animation */
.timer-display.completed .timer-circle {
  animation: completionFlash 0.6s ease-out;
}

@keyframes completionFlash {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.8; transform: scale(1.05); }
}

/* Mobile responsive */
@media (max-width: 768px) {
  .timer-display.large {
    --timer-size: 240px;
    --timer-font-size: 42px;
  }

  .timer-controls {
    margin-top: 20px;
    gap: 12px;
  }

  .timer-btn {
    padding: 10px 20px;
    font-size: 14px;
  }
}
```

### JavaScript Structure
```javascript
class TimerDisplay {
  constructor(props) {
    this.props = props;
    this.state = {
      timeRemaining: props.timeRemaining || props.duration,
      isRunning: props.isRunning || false,
      isCompleted: false,
      isPaused: false
    };

    this.intervalId = null;
    this.startTime = null;
    this.pausedTime = 0;
    this.worker = null;

    this.init();
  }

  init() {
    this.setupWorker();
    this.bindEvents();
    this.loadSavedState();
  }

  setupWorker() {
    // Create Web Worker for background timing
    const workerCode = `
      let intervalId = null;
      let startTime = null;
      let duration = 0;

      self.addEventListener('message', function(e) {
        const { type, data } = e.data;

        switch (type) {
          case 'start':
            startTime = Date.now() - (data.elapsed || 0);
            duration = data.duration;
            intervalId = setInterval(() => {
              const elapsed = Date.now() - startTime;
              const remaining = Math.max(0, duration - Math.floor(elapsed / 1000));
              self.postMessage({ type: 'tick', remaining, elapsed });

              if (remaining <= 0) {
                clearInterval(intervalId);
                self.postMessage({ type: 'complete' });
              }
            }, 100);
            break;

          case 'pause':
            clearInterval(intervalId);
            break;

          case 'reset':
            clearInterval(intervalId);
            break;
        }
      });
    `;

    const blob = new Blob([workerCode], { type: 'application/javascript' });
    this.worker = new Worker(URL.createObjectURL(blob));

    this.worker.addEventListener('message', (e) => {
      const { type, remaining } = e.data;

      switch (type) {
        case 'tick':
          this.updateTime(remaining);
          break;
        case 'complete':
          this.handleCompletion();
          break;
      }
    });
  }

  start() {
    if (this.state.isCompleted) return;

    const elapsed = this.props.duration - this.state.timeRemaining;

    this.setState({ isRunning: true, isPaused: false });
    this.startTime = Date.now() - (elapsed * 1000);

    this.worker.postMessage({
      type: 'start',
      data: {
        duration: this.props.duration * 1000,
        elapsed: elapsed * 1000
      }
    });

    this.saveState();
  }

  pause() {
    this.setState({ isRunning: false, isPaused: true });
    this.worker.postMessage({ type: 'pause' });
    this.saveState();
  }

  reset() {
    this.setState({
      timeRemaining: this.props.duration,
      isRunning: false,
      isPaused: false,
      isCompleted: false
    });

    this.worker.postMessage({ type: 'reset' });
    this.clearSavedState();
  }

  toggle() {
    if (this.state.isRunning) {
      this.pause();
    } else {
      this.start();
    }

    if (this.props.onToggle) {
      this.props.onToggle(this.state.isRunning);
    }
  }

  updateTime(timeRemaining) {
    this.setState({ timeRemaining });

    if (this.props.onTimeUpdate) {
      this.props.onTimeUpdate(timeRemaining);
    }

    // Update page title with remaining time
    if (this.state.isRunning) {
      document.title = `${this.formatTime(timeRemaining)} - Pomodoro Timer`;
    }
  }

  handleCompletion() {
    this.setState({
      isRunning: false,
      isCompleted: true,
      timeRemaining: 0
    });

    this.playCompletionSound();
    this.showNotification();
    this.clearSavedState();

    if (this.props.onComplete) {
      this.props.onComplete();
    }

    // Trigger completion animation
    document.querySelector('.timer-display').classList.add('completed');
    setTimeout(() => {
      document.querySelector('.timer-display')?.classList.remove('completed');
    }, 600);
  }

  playCompletionSound() {
    if (!this.props.soundEnabled) return;

    const audioContext = new (window.AudioContext || window.webkitAudioContext)();

    // Create completion sound using Web Audio API
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
    oscillator.frequency.setValueAtTime(600, audioContext.currentTime + 0.1);
    oscillator.frequency.setValueAtTime(800, audioContext.currentTime + 0.2);

    gainNode.gain.setValueAtTime(0, audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(0.3, audioContext.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);

    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.3);
  }

  showNotification() {
    if (!this.props.notificationsEnabled || Notification.permission !== 'granted') {
      return;
    }

    const messages = {
      work: 'Work session complete! Time for a break.',
      short_break: 'Break time over! Ready to focus?',
      long_break: 'Long break complete! Let\'s get back to work.'
    };

    new Notification('Pomodoro Timer', {
      body: messages[this.props.sessionType] || 'Timer complete!',
      icon: '/icons/pomodoro-icon.png',
      tag: 'pomodoro-complete'
    });
  }

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;

    if (this.props.showMilliseconds && seconds < 10) {
      return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  getProgressPercentage() {
    const elapsed = this.props.duration - this.state.timeRemaining;
    return (elapsed / this.props.duration) * 100;
  }

  getCircumference() {
    const radius = 136; // Adjust based on SVG size
    return 2 * Math.PI * radius;
  }

  getStrokeDashoffset() {
    const circumference = this.getCircumference();
    const progress = this.getProgressPercentage();
    return circumference - (progress / 100) * circumference;
  }

  saveState() {
    const state = {
      timeRemaining: this.state.timeRemaining,
      isRunning: this.state.isRunning,
      startTime: this.startTime,
      sessionType: this.props.sessionType,
      duration: this.props.duration
    };

    localStorage.setItem('timerState', JSON.stringify(state));
  }

  loadSavedState() {
    const saved = localStorage.getItem('timerState');
    if (!saved) return;

    try {
      const state = JSON.parse(saved);

      // Only restore if it's the same session type
      if (state.sessionType === this.props.sessionType) {
        const elapsed = Date.now() - state.startTime;
        const remaining = Math.max(0, state.duration - Math.floor(elapsed / 1000));

        if (remaining > 0 && state.isRunning) {
          this.setState({
            timeRemaining: remaining,
            isRunning: true
          });
          this.start();
        }
      }
    } catch (error) {
      console.error('Failed to load timer state:', error);
    }
  }

  clearSavedState() {
    localStorage.removeItem('timerState');
  }

  render() {
    const { timeRemaining, isRunning, isPaused, isCompleted } = this.state;
    const { sessionType, size, showProgress } = this.props;

    const circumference = this.getCircumference();
    const strokeDashoffset = this.getStrokeDashoffset();

    return `
      <div class="timer-display ${sessionType} ${size}"
           role="timer"
           aria-label="Pomodoro timer: ${this.formatTime(timeRemaining)} remaining"
           aria-live="polite">

        <div class="timer-circle ${isRunning ? 'running' : ''} ${isPaused ? 'paused' : ''}"
             onclick="this.toggle()">

          ${showProgress ? `
            <svg class="timer-svg" viewBox="0 0 280 280">
              <circle class="timer-progress-bg"
                      cx="140" cy="140" r="136">
              </circle>
              <circle class="timer-progress"
                      cx="140" cy="140" r="136"
                      stroke-dasharray="${circumference}"
                      stroke-dashoffset="${strokeDashoffset}">
              </circle>
            </svg>
          ` : ''}

          <div class="timer-content">
            <div class="timer-time">${this.formatTime(timeRemaining)}</div>
            <div class="timer-label">${this.getSessionLabel()}</div>
          </div>

          ${isPaused ? '<div class="pause-overlay">⏸️</div>' : ''}
        </div>

        <div class="timer-controls">
          <button class="timer-btn primary" onclick="this.toggle()">
            ${isRunning ? '⏸️ 暂停' : '▶️ 开始'}
          </button>
          <button class="timer-btn secondary" onclick="this.reset()">
            🔄 重置
          </button>
        </div>
      </div>
    `;
  }

  getSessionLabel() {
    const labels = {
      work: '工作时间',
      short_break: '短休息',
      long_break: '长休息'
    };
    return labels[this.props.sessionType] || '计时器';
  }

  bindEvents() {
    // Handle page visibility changes to maintain accuracy
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden && this.state.isRunning) {
        // Resume accurate timing when tab becomes visible
        this.syncTimeWithWorker();
      }
    });

    // Handle beforeunload to save state
    window.addEventListener('beforeunload', () => {
      if (this.state.isRunning) {
        this.saveState();
      }
    });
  }

  syncTimeWithWorker() {
    if (this.startTime) {
      const elapsed = Date.now() - this.startTime;
      const remaining = Math.max(0, this.props.duration - Math.floor(elapsed / 1000));
      this.updateTime(remaining);
    }
  }

  destroy() {
    if (this.worker) {
      this.worker.terminate();
    }
    this.clearSavedState();
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Timer accuracy and countdown functionality
- [ ] Start, pause, reset, and completion behavior
- [ ] Time formatting and display
- [ ] Progress calculation and visual updates

### Integration Tests
- [ ] Web Worker background timing
- [ ] Audio API sound playback
- [ ] Notification API integration
- [ ] localStorage state persistence

### Accessibility Tests
- [ ] Screen reader announcements for time updates
- [ ] ARIA attributes and timer role
- [ ] Keyboard interaction support
- [ ] Focus management and visual indicators

### Performance Tests
- [ ] Timer accuracy under CPU load
- [ ] Background tab performance
- [ ] Memory usage during extended sessions
- [ ] Mobile device battery optimization

## Usage Examples

### Basic Usage
```html
<timer-display
  duration="1500"
  sessionType="work"
  onComplete="handleTimerComplete"
  onToggle="handleTimerToggle">
</timer-display>
```

### Advanced Usage
```html
<timer-display
  duration="1500"
  sessionType="work"
  isRunning="false"
  timeRemaining="1200"
  showProgress="true"
  soundEnabled="true"
  notificationsEnabled="true"
  size="large"
  onTimeUpdate="handleTimeUpdate"
  onComplete="handleTimerComplete"
  onToggle="handleTimerToggle">
</timer-display>
```

### Compact Usage
```html
<timer-display
  duration="300"
  sessionType="short_break"
  size="small"
  showProgress="false"
  onComplete="handleTimerComplete"
  onToggle="handleTimerToggle">
</timer-display>
```

This TimerDisplay component provides the core timing functionality for the Pomodoro technique while ensuring accuracy, accessibility, and excellent user experience across all platforms and usage scenarios.