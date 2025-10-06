# TaskCard Component

**Component Type**: content
**Complexity Level**: moderate
**Dependencies**: TaskActions, PomodoroButton components
**Estimated Implementation Time**: 6 hours

## Component Metadata

- **component_name**: TaskCard
- **component_type**: content
- **complexity_level**: moderate
- **dependencies**: [TaskActions, API client, localStorage]
- **estimated_implementation_time**: 6 hours

## Purpose

The TaskCard component displays individual task information within a project context. It includes task details, status management, and most importantly, provides direct access to Pomodoro sessions through an individual timer button - replacing the global timer approach with task-specific focus sessions.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| task | object | true | null | Valid task object | Complete task data including metadata |
| onToggleComplete | function | true | null | Valid function | Callback when task completion is toggled |
| onStartPomodoro | function | true | null | Valid function | Callback when pomodoro button is clicked |
| onEditTask | function | false | null | Valid function | Callback for task editing |
| onDeleteTask | function | false | null | Valid function | Callback for task deletion |
| isActivePomodoro | boolean | false | false | true\|false | Whether this task has active pomodoro session |
| showActions | boolean | false | true | true\|false | Whether to show edit/delete actions |
| compact | boolean | false | false | true\|false | Compact display mode for mobile |

## Visual States

### Default
- **Appearance**: White background card with subtle shadow and rounded corners
- **Border**: 1px solid #e9ecef with 12px border radius
- **Padding**: 16px all around
- **Spacing**: 8px margin between cards

### Completed
- **Appearance**: Light green background (#f8f9fa with green tint)
- **Text**: Strikethrough on task title
- **Checkbox**: Filled checkmark icon
- **Opacity**: Slightly reduced (0.8) for secondary visual weight

### Active Pomodoro
- **Appearance**: Orange/red accent border (3px solid #ff6b6b)
- **Background**: Subtle orange tint (#fff5f5)
- **Button**: Pomodoro button shows "Active" state with pulsing animation
- **Priority**: Visual emphasis as most important task

### Hover
- **Appearance**: Slight shadow increase and 1px upward transform
- **Border**: Subtle blue tint on border color
- **Transition**: 200ms ease for all property changes
- **Cursor**: Pointer for interactive elements

### Loading
- **Appearance**: Skeleton loading for task content
- **Animation**: Shimmer effect on text areas
- **Actions**: Disabled state for all buttons
- **Duration**: Until task update API call completes

### Error
- **Appearance**: Red border with error icon
- **Message**: Inline error message below task content
- **Actions**: Retry button for failed operations
- **Recovery**: Maintains previous task state

## Accessibility

### Keyboard Navigation
- **Tab Order**: Checkbox → task content → pomodoro button → edit button → delete button
- **Enter Behavior**: Toggles completion state when focused on checkbox
- **Space Behavior**: Activates buttons and toggles checkbox
- **Escape Behavior**: Cancels edit mode if in inline editing

### Screen Reader Support
- **aria-label**: "Task: [task title], [completion status], [priority]"
- **aria-role**: "article" for task container
- **aria-state**: aria-checked for completion checkbox
- **Live Regions**: Task status changes announced immediately

### Focus Management
- **Focus Indicator**: Clear blue outline (2px solid #007bff) around focused elements
- **Focus Trapping**: Not applicable (card is not modal)
- **Focus Restoration**: Maintains focus after completion toggle

## Responsive Behavior

### Mobile (<768px)
- **Layout Changes**: Stacked layout with larger touch targets
- **Touch Interactions**: 44px minimum tap targets for all interactive elements
- **Compact Mode**: Reduced padding and smaller text sizes
- **Actions**: Swipe gestures for edit/delete (optional enhancement)

### Tablet (768-1024px)
- **Layout Changes**: Compressed layout with hybrid interaction model
- **Touch Support**: Works with both touch and mouse interactions
- **Button Size**: Medium-sized buttons suitable for touch
- **Spacing**: Adequate spacing for finger taps

### Desktop (>1024px)
- **Layout Changes**: Full layout with all details and actions visible
- **Interaction Model**: Mouse hover states and precise click targets
- **Advanced Features**: Drag and drop for task reordering
- **Keyboard Shortcuts**: Quick task completion (Ctrl+Enter)

## Integration Points

### Data Binding
- **API Endpoint**: `/v1/tasks/{id}` for task updates
- **Data Transformation**: Maps task object to display properties
- **Error Handling**: Shows task in error state with retry option
- **Loading State**: Skeleton loading during API operations
- **Cache Strategy**: Optimistic updates with rollback on failure

### Pomodoro Integration
- **Session Creation**: `/v1/pomodoro/sessions` API call
- **State Management**: Tracks active pomodoro session per task
- **Timer Display**: Shows remaining time for active sessions
- **Completion**: Updates task pomodoro count on session completion

### Performance Requirements
- **Render Time**: <30ms for card updates
- **Memory Usage**: <500KB per card instance
- **Re-render Triggers**: task object changes, isActivePomodoro state
- **Optimization**: Memoization for expensive prop calculations

## Wireframe

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ☐ Complete project architecture design                                     │
│                                                                             │
│   设计前端项目优先架构，包括左侧边栏和任务管理                                │
│                                                                             │
│   🔴 高优先级    📅 10月8日    🍅 2/5    [🍅 开始番茄钟]  ✏️  🗑️           │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.task-card {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  padding: 16px;
  margin: 8px 0;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.task-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform: translateY(-1px);
}

.task-card--completed {
  background: #f8f9fa;
  opacity: 0.8;
}

.task-card--active-pomodoro {
  border: 3px solid #ff6b6b;
  background: #fff5f5;
}

.task-main {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.task-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.btn-pomodoro {
  background: #ff6b6b;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-pomodoro:hover {
  background: #ff5252;
  transform: scale(1.05);
}

.btn-pomodoro--active {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}
```

### JavaScript Structure
```javascript
class TaskCard {
  constructor(props) {
    this.props = props;
    this.state = {
      isUpdating: false,
      error: null
    };
  }

  handleToggleComplete() {
    this.setState({ isUpdating: true });
    this.props.onToggleComplete(this.props.task.id)
      .then(() => this.setState({ isUpdating: false }))
      .catch(error => this.setState({ error, isUpdating: false }));
  }

  handleStartPomodoro() {
    this.props.onStartPomodoro(this.props.task);
    // Analytics tracking
  }

  renderTaskContent() {
    const { task } = this.props;
    return (
      <div className="task-content">
        <h4 className="task-title">{task.title}</h4>
        <p className="task-description">{task.description}</p>
        <div className="task-meta">
          {this.renderPriority()}
          {this.renderDueDate()}
          {this.renderPomodoroCount()}
        </div>
      </div>
    );
  }

  renderActions() {
    return (
      <div className="task-actions">
        <button className="btn-pomodoro" onClick={this.handleStartPomodoro}>
          🍅 开始番茄钟
        </button>
        {this.props.showActions && (
          <>
            <button className="btn-edit" onClick={this.props.onEditTask}>✏️</button>
            <button className="btn-delete" onClick={this.props.onDeleteTask}>🗑️</button>
          </>
        )}
      </div>
    );
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Task data display and formatting
- [ ] Completion toggle functionality
- [ ] Pomodoro button click handling
- [ ] Visual state transitions
- [ ] Error state handling

### Integration Tests
- [ ] Task update API integration
- [ ] Pomodoro session creation
- [ ] Real-time pomodoro status updates
- [ ] Task action callbacks

### Accessibility Tests
- [ ] Keyboard navigation through all elements
- [ ] Screen reader task information announcement
- [ ] Focus management and visual indicators
- [ ] Completion toggle accessibility

### Responsive Tests
- [ ] Mobile compact layout
- [ ] Touch interaction support
- [ ] Tablet hybrid interaction
- [ ] Desktop hover states

## Usage Examples

### Basic Usage
```html
<task-card
  task="{id: '123', title: 'Complete design', description: 'Finalize UI specs'}"
  onToggleComplete="handleTaskComplete"
  onStartPomodoro="handlePomodoroStart">
</task-card>
```

### Advanced Usage
```html
<task-card
  task="{taskObject}"
  onToggleComplete="handleTaskComplete"
  onStartPomodoro="handlePomodoroStart"
  onEditTask="handleTaskEdit"
  onDeleteTask="handleTaskDelete"
  isActivePomodoro="true"
  showActions="true"
  compact="false">
</task-card>
```