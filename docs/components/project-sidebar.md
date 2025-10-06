# ProjectSidebar Component

**Component Type**: navigation
**Complexity Level**: moderate
**Dependencies**: ProjectList, DailyStats components
**Estimated Implementation Time**: 8 hours

## Component Metadata

- **component_name**: ProjectSidebar
- **component_type**: navigation
- **complexity_level**: moderate
- **dependencies**: [ProjectList, DailyStats, localStorage, API client]
- **estimated_implementation_time**: 8 hours

## Purpose

The ProjectSidebar component provides the primary navigation interface for the project-first architecture. It replaces the previous bottom navigation with a left-aligned sidebar that prioritizes project management and displays contextual information like daily statistics.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| currentProject | string | false | 'inbox' | Valid project UUID | Currently selected project ID |
| projects | array | true | [] | Array of project objects | List of user's projects |
| isCollapsed | boolean | false | false | true\|false | Whether sidebar is collapsed on tablet |
| onProjectSelect | function | true | null | Valid function | Callback when project is selected |
| onAddProject | function | true | null | Valid function | Callback for new project creation |
| dailyStats | object | false | {} | Valid stats object | Today's productivity statistics |
| showStats | boolean | false | true | true\|false | Whether to display daily statistics |

## Visual States

### Default
- **Appearance**: 240px wide sidebar with white/light gray background
- **Border**: 1px solid border on right edge (#e9ecef)
- **Padding**: 20px vertical, 16px horizontal
- **Typography**: System font stack, standard sizes

### Collapsed (Tablet)
- **Appearance**: 60px wide with icons only
- **Hover Expansion**: Expands to full width on hover with 200ms transition
- **Icon Display**: Project icons and quick stats only
- **Labels**: Hidden until hover expansion

### Mobile Hidden
- **Appearance**: Completely hidden, replaced by bottom navigation
- **Transition**: Smooth slide-out animation when switching to mobile layout
- **Alternative**: Project list moves to horizontal scrolling bottom bar

### Loading
- **Appearance**: Skeleton loaders for project list items
- **Animation**: Subtle shimmer effect on placeholder rectangles
- **Duration**: Shows until project data loads from API

### Error
- **Appearance**: Error message in place of project list
- **Action**: Retry button for failed project loading
- **Fallback**: Shows cached projects if available

## Accessibility

### Keyboard Navigation
- **Tab Order**: Sidebar header → project list items → daily stats → add project button
- **Enter Behavior**: Selects project or activates add project function
- **Arrow Keys**: Navigate up/down through project list items
- **Escape Behavior**: Closes any expanded project options

### Screen Reader Support
- **aria-label**: "Project navigation sidebar"
- **aria-role**: "navigation"
- **aria-state**: aria-expanded for collapsed state
- **Live Regions**: Project selection announcements

### Focus Management
- **Focus Indicator**: Clear blue outline (2px solid #007bff) around focused items
- **Focus Trapping**: Not applicable (sidebar is not modal)
- **Focus Restoration**: Maintains focus on selected project after navigation

## Responsive Behavior

### Mobile (<768px)
- **Layout Changes**: Sidebar completely hidden, navigation moves to bottom
- **Touch Interactions**: N/A in mobile layout
- **Space Constraints**: Full screen width available for main content
- **Performance**: Component unmounted to reduce memory usage

### Tablet (768-1024px)
- **Layout Changes**: Sidebar collapses to 60px width with icons only
- **Touch Interactions**: Tap to expand, tap outside to collapse
- **Hover Behavior**: Expand on hover for mouse users
- **Orientation**: Maintains collapsed state in portrait mode

### Desktop (>1024px)
- **Layout Changes**: Full 240px width always visible
- **Interaction Model**: Mouse hover states and click interactions
- **Advanced Features**: Drag and drop project reordering
- **Keyboard Shortcuts**: Quick project switching (Cmd/Ctrl + 1-9)

## Integration Points

### Data Binding
- **API Endpoint**: `/v1/projects` for project list
- **Data Transformation**: Maps API project objects to sidebar display format
- **Error Handling**: Shows cached projects with offline indicator on API failure
- **Loading State**: Skeleton loading during initial data fetch
- **Cache Strategy**: 5-minute cache for project list, immediate invalidation on changes

### Performance Requirements
- **Render Time**: <50ms for sidebar visibility toggle
- **Memory Usage**: <2MB for component and project data
- **Re-render Triggers**: currentProject, projects array, isCollapsed state changes
- **Optimization**: Virtual scrolling for 100+ projects

## Wireframe

```
┌──────────────────────┐
│   📋 我的项目    ➕   │ ← Header with add button
├──────────────────────┤
│                      │
│ 📥 Inbox        5    │ ← Project with task count
│ 💼 Work Project 12   │
│ 📚 Study Plan   8    │ ← Active project highlighted
│ 🏠 Personal     3    │
│                      │
├──────────────────────┤
│     📊 今日统计       │ ← Statistics section
├──────────────────────┤
│ 🍅 完成番茄钟   6    │
│ ⏱️ 专注时间    2h30m │
│ ✅ 完成任务    4     │
│                      │
└──────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.project-sidebar {
  width: 240px;
  background: #f8f9fa;
  border-right: 1px solid #e9ecef;
  transition: width 0.2s ease;
}

.project-sidebar--collapsed {
  width: 60px;
}

.project-sidebar--mobile-hidden {
  display: none;
}

.project-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.project-item:hover {
  background: #e9ecef;
}

.project-item--active {
  background: #007bff;
  color: white;
}

.daily-stats {
  border-top: 1px solid #e9ecef;
  padding-top: 16px;
  margin-top: 16px;
}
```

### JavaScript Structure
```javascript
class ProjectSidebar {
  constructor(props) {
    this.props = props;
    this.state = {
      isLoading: false,
      error: null,
      expandedProject: null
    };
  }

  handleProjectSelect(projectId) {
    this.props.onProjectSelect(projectId);
    // Analytics tracking
    // State management updates
  }

  handleAddProject() {
    this.props.onAddProject();
    // Open project creation modal
  }

  renderProjectList() {
    // Render project items with icons and counts
  }

  renderDailyStats() {
    // Render statistics section
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Props validation and default values
- [ ] Project selection callback execution
- [ ] Collapsed state visual changes
- [ ] Loading and error state rendering

### Integration Tests
- [ ] Project data loading from API
- [ ] Project selection updates main content
- [ ] Add project modal trigger
- [ ] Daily statistics data binding

### Accessibility Tests
- [ ] Keyboard navigation through all interactive elements
- [ ] Screen reader announcements for project selection
- [ ] Focus management and visual indicators
- [ ] ARIA attributes validation

### Responsive Tests
- [ ] Mobile layout hiding behavior
- [ ] Tablet collapse/expand functionality
- [ ] Desktop full-width display
- [ ] Touch interaction support on tablet

## Usage Examples

### Basic Usage
```html
<project-sidebar
  projects="[{id: 'inbox', name: 'Inbox', taskCount: 5}]"
  currentProject="inbox"
  onProjectSelect="handleProjectSelect"
  onAddProject="handleAddProject">
</project-sidebar>
```

### Advanced Usage
```html
<project-sidebar
  projects="[projectArray]"
  currentProject="work-project-1"
  isCollapsed="false"
  dailyStats="{pomodoros: 6, focusTime: '2h30m', completedTasks: 4}"
  showStats="true"
  onProjectSelect="handleProjectSelect"
  onAddProject="handleAddProject">
</project-sidebar>
```