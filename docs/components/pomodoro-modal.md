# PomodoroModal Component

**Component Type**: interaction
**Complexity Level**: complex
**Dependencies**: TimerDisplay, TaskActions, Audio API
**Estimated Implementation Time**: 12 hours

## Component Metadata

- **component_name**: PomodoroModal
- **component_type**: interaction
- **complexity_level**: complex
- **dependencies**: [TimerDisplay, Audio API, Notification API, localStorage]
- **estimated_implementation_time**: 12 hours

## Purpose

The PomodoroModal component provides a focused, immersive environment for Pomodoro timer sessions. It replaces the global timer with task-specific sessions, displaying the current task context, timer progress, and session controls while blocking distractions from the main interface.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| isVisible | boolean | true | false | true\|false | Whether modal is currently displayed |
| currentTask | object | true | null | Valid task object | Task associated with this pomodoro session |
| sessionType | string | false | 'work' | work\|short_break\|long_break | Current session type |
| duration | number | false | 1500 | 300-3600 | Session duration in seconds |
| timeRemaining | number | false | 1500 | 0-3600 | Remaining time in current session |
| isRunning | boolean | false | false | true\|false | Whether timer is currently running |
| sessionCount | number | false | 1 | 1-8 | Current session number in cycle |
| totalSessions | number | false | 4 | 1-8 | Total sessions in complete cycle |
| onStart | function | true | null | Valid function | Callback when timer starts |
| onPause | function | true | null | Valid function | Callback when timer pauses |
| onReset | function | true | null | Valid function | Callback when timer resets |
| onComplete | function | true | null | Valid function | Callback when session completes |
| onClose | function | true | null | Valid function | Callback when modal closes |
| onSkip | function | false | null | Valid function | Callback when session is skipped |

## Visual States

### Work Session
- **Background**: Clean white with subtle orange accent (#fff5f5)
- **Timer Color**: Primary red (#ff6b6b) for work focus
- **Progress**: Circular progress ring with work color
- **Task Display**: Prominent task information with progress

### Short Break
- **Background**: Light blue tint (#f0f8ff)
- **Timer Color**: Calming blue (#45b7d1) for rest period
- **Progress**: Circular progress with break color
- **Content**: Relaxation suggestions and break activities

### Long Break
- **Background**: Light green tint (#f0fff0)
- **Timer Color**: Refreshing green (#66bb6a) for extended rest
- **Progress**: Circular progress with extended break color
- **Content**: Achievement summary and preparation for next cycle

### Paused
- **Overlay**: Semi-transparent pause indicator
- **Button**: Resume button prominently displayed
- **Timer**: Paused time display with different styling
- **Background**: Slightly dimmed to indicate inactive state

### Completed
- **Animation**: Celebration animation (optional confetti effect)
- **Message**: Session completion notification
- **Actions**: Continue to break or start next session
- **Sound**: Completion notification sound (if enabled)

## Accessibility

### Keyboard Navigation
- **Tab Order**: Close button → start/pause → reset → skip → close
- **Enter Behavior**: Activates focused button (start/pause primary action)
- **Space Behavior**: Same as Enter for consistency
- **Escape Behavior**: Closes modal and pauses timer

### Screen Reader Support
- **aria-label**: "Pomodoro timer session for [task name]"
- **aria-role**: "dialog"
- **aria-modal**: "true" to indicate modal nature
- **Live Regions**: Timer updates announced every minute

### Focus Management
- **Focus Trapping**: Focus contained within modal while open
- **Initial Focus**: Start/pause button receives focus on open
- **Focus Restoration**: Returns focus to triggering task card button on close

## Responsive Behavior

### Mobile (<768px)
- **Layout**: Full-screen modal covering entire viewport
- **Touch Targets**: Large touch-friendly buttons (minimum 44px)
- **Gestures**: Swipe down to close, tap anywhere to pause/resume
- **Vibration**: Haptic feedback for timer start/stop/complete

### Tablet (768-1024px)
- **Layout**: Large centered modal (600px width) with backdrop
- **Touch Support**: Hybrid touch and mouse interaction support
- **Size**: Larger timer display suitable for medium screens
- **Controls**: Medium-sized buttons optimized for touch

### Desktop (>1024px)
- **Layout**: Centered modal (500px width) with semi-transparent backdrop
- **Interaction**: Mouse hover states and keyboard shortcuts
- **Features**: Additional keyboard shortcuts (Space = pause, R = reset)
- **Window**: Always-on-top option for multitasking

## Integration Points

### Timer Management
- **Session Creation**: Creates new session record via `/v1/pomodoro/sessions`
- **Progress Tracking**: Updates session progress in real-time
- **Completion Handling**: Marks session as complete and updates task statistics
- **State Persistence**: Saves timer state to localStorage for recovery

### Task Integration
- **Task Context**: Displays current task information prominently
- **Progress Updates**: Updates task pomodoro count on completion
- **Task Actions**: Quick access to mark task complete during session
- **History**: Links completed sessions to task history

### Notification System
- **Sound Alerts**: Configurable notification sounds for start/complete
- **Desktop Notifications**: Browser notifications for session transitions
- **Visual Indicators**: Progress animations and color changes
- **Focus Assistance**: Optional website blocking suggestions

### Performance Requirements
- **Timer Accuracy**: ±1 second precision using high-resolution timers
- **Background Operation**: Continues running when browser tab inactive
- **Memory Usage**: <5MB including timer state and audio resources
- **Battery Optimization**: Efficient timer implementation for mobile devices

## Wireframe

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           🍅 专注模式                    ✕                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                           当前任务                                          │
│                    完成项目架构设计                                        │
│                                                                             │
│                  番茄钟进度: 2/5                                           │
│    ████████████████░░░░░░░░░░  40%                                         │
│                                                                             │
│                        ┌─────────┐                                        │
│                        │         │                                        │
│                        │  25:00  │  ← Circular timer display              │
│                        │         │                                        │
│                        │ 工作时间 │                                        │
│                        └─────────┘                                        │
│                                                                             │
│                                                                             │
│      [▶️ 开始]     [🔄 重置]     [⏭️ 跳过]                               │
│                                                                             │
│                                                                             │
│                   第 3 轮，共 4 轮                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.pomodoro-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 20px;
  padding: 32px;
  width: 480px;
  max-width: 90vw;
  text-align: center;
  box-shadow: 0 20px 40px rgba(0,0,0,0.2);
}

.timer-circle {
  position: relative;
  width: 240px;
  height: 240px;
  margin: 20px auto;
}

.timer-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.timer-progress {
  fill: none;
  stroke: #ff6b6b;
  stroke-width: 8;
  stroke-linecap: round;
  transition: stroke-dashoffset 1s ease;
}

.timer-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.time-remaining {
  font-size: 48px;
  font-weight: bold;
  color: #333;
}

.timer-controls {
  display: flex;
  justify-content: center;
  gap: 16px;
  margin: 24px 0;
}

.btn-large {
  padding: 12px 24px;
  font-size: 16px;
  border-radius: 24px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}
```

### JavaScript Structure
```javascript
class PomodoroModal {
  constructor(props) {
    this.props = props;
    this.state = {
      timeRemaining: props.duration,
      isRunning: false,
      sessionType: 'work',
      intervalId: null
    };
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }

  componentDidMount() {
    if (this.props.isVisible) {
      document.body.classList.add('modal-open');
      this.focusFirstElement();
    }
  }

  startTimer() {
    if (!this.state.isRunning) {
      this.setState({ isRunning: true });
      this.intervalId = setInterval(() => {
        this.tick();
      }, 1000);
      this.props.onStart();
    }
  }

  pauseTimer() {
    if (this.state.isRunning) {
      this.setState({ isRunning: false });
      clearInterval(this.intervalId);
      this.props.onPause();
    }
  }

  tick() {
    const newTime = this.state.timeRemaining - 1;
    if (newTime <= 0) {
      this.completeSession();
    } else {
      this.setState({ timeRemaining: newTime });
    }
  }

  completeSession() {
    this.setState({ isRunning: false, timeRemaining: 0 });
    clearInterval(this.intervalId);
    this.playCompletionSound();
    this.showNotification();
    this.props.onComplete();
  }

  playCompletionSound() {
    // Web Audio API implementation for completion sound
  }

  showNotification() {
    if (Notification.permission === 'granted') {
      new Notification('Pomodoro Session Complete!', {
        body: `Great work on "${this.props.currentTask.title}"`,
        icon: '/icons/pomodoro-icon.png'
      });
    }
  }

  render() {
    return (
      <div className="pomodoro-modal" onKeyDown={this.handleKeyDown}>
        <div className="modal-content">
          {this.renderHeader()}
          {this.renderTaskInfo()}
          {this.renderTimer()}
          {this.renderControls()}
          {this.renderSessionInfo()}
        </div>
      </div>
    );
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Timer accuracy and countdown functionality
- [ ] Session state transitions (work → break → work)
- [ ] Button interactions and callback execution
- [ ] Time formatting and display

### Integration Tests
- [ ] Task integration and context display
- [ ] Session creation and completion API calls
- [ ] Notification system integration
- [ ] Audio playback functionality

### Accessibility Tests
- [ ] Focus trapping within modal
- [ ] Keyboard navigation and shortcuts
- [ ] Screen reader announcements
- [ ] ARIA attributes validation

### Performance Tests
- [ ] Timer accuracy under CPU load
- [ ] Memory usage during long sessions
- [ ] Background tab performance
- [ ] Mobile device battery impact

## Usage Examples

### Basic Usage
```html
<pomodoro-modal
  isVisible="true"
  currentTask="{id: '123', title: 'Complete design'}"
  onStart="handleTimerStart"
  onComplete="handleSessionComplete"
  onClose="handleModalClose">
</pomodoro-modal>
```

### Advanced Usage
```html
<pomodoro-modal
  isVisible="true"
  currentTask="{taskObject}"
  sessionType="work"
  duration="1500"
  sessionCount="2"
  totalSessions="4"
  onStart="handleStart"
  onPause="handlePause"
  onReset="handleReset"
  onComplete="handleComplete"
  onSkip="handleSkip"
  onClose="handleClose">
</pomodoro-modal>
```