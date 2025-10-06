# ProjectList Component

**Component Type**: navigation
**Complexity Level**: moderate
**Dependencies**: ProjectCard, DailyStats, API integration
**Estimated Implementation Time**: 8 hours

## Component Metadata

- **component_name**: ProjectList
- **component_type**: navigation
- **complexity_level**: moderate
- **dependencies**: [ProjectCard, DailyStats, API integration, localStorage]
- **estimated_implementation_time**: 8 hours

## Purpose

The ProjectList component serves as the primary navigation interface in the left sidebar, displaying all user projects with their current status, task counts, and quick access actions. It replaces the bottom navigation paradigm with a project-first approach that emphasizes organizational hierarchy.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| projects | array | true | [] | Valid project objects | Array of project data from API |
| currentProjectId | string | false | null | Valid UUID or null | Currently selected project ID |
| isCollapsed | boolean | false | false | true\|false | Whether sidebar is collapsed (mobile) |
| onProjectSelect | function | true | null | Valid function | Callback when project is selected |
| onProjectCreate | function | true | null | Valid function | Callback for new project creation |
| onProjectEdit | function | false | null | Valid function | Callback for project editing |
| onProjectDelete | function | false | null | Valid function | Callback for project deletion |
| showStats | boolean | false | true | true\|false | Whether to show project statistics |
| isLoading | boolean | false | false | true\|false | Loading state for project data |

## Visual States

### Default State
- **Layout**: Vertical list with project cards
- **Colors**: Light background (#f8f9fa) with project-specific indicators
- **Typography**: Project names in medium weight, stats in lighter color
- **Spacing**: 8px between items, 16px padding inside cards

### Loading State
- **Indicator**: Skeleton cards with shimmer animation
- **Fallback**: "Loading projects..." text with spinner
- **Duration**: Progressive loading with individual project cards appearing
- **Accessibility**: Screen reader announcement of loading status

### Empty State
- **Message**: "No projects yet. Create your first project!"
- **Action**: Prominent "Create Project" button
- **Visual**: Empty state illustration or icon
- **Guidance**: Helpful text explaining project benefits

### Error State
- **Message**: Clear error description (e.g., "Unable to load projects")
- **Recovery**: "Retry" button for network errors
- **Fallback**: Offline mode indicator if applicable
- **Logging**: Error details logged for debugging

### Selected State
- **Highlight**: Selected project has distinct background color
- **Indicator**: Active project marked with colored border/icon
- **Focus**: Clear visual focus state for keyboard navigation
- **Persistence**: Selection maintained across page refreshes

## Accessibility

### Keyboard Navigation
- **Tab Order**: Arrow keys for project list navigation, Enter to select
- **Focus Management**: Focus visible indicator on selected project
- **Shortcuts**: Number keys (1-9) for quick project selection
- **Screen Reader**: Proper ARIA labels and role declarations

### Screen Reader Support
- **aria-label**: "Project navigation list"
- **aria-role**: "navigation"
- **aria-current**: "page" for currently selected project
- **Live Regions**: Updates announced when project list changes

### Focus Management
- **Focus Trapping**: Focus contained within expanded sidebar on mobile
- **Focus Restoration**: Returns focus to project list when modals close
- **Initial Focus**: First project receives focus on component mount

## Responsive Behavior

### Desktop (>1024px)
- **Layout**: Full 240px width sidebar with complete project information
- **Display**: Project names, task counts, completion percentages visible
- **Interactions**: Hover effects with smooth transitions
- **Actions**: Edit/delete buttons visible on hover

### Tablet (768-1024px)
- **Layout**: Collapsible sidebar, 60px collapsed, 240px expanded
- **Trigger**: Hover to expand, click outside to collapse
- **Display**: Icons only when collapsed, full details when expanded
- **Performance**: Smooth slide animation for expand/collapse

### Mobile (<768px)
- **Layout**: Full-width horizontal scrollable list or bottom sheet
- **Display**: Compact project cards with essential information only
- **Interaction**: Swipe gestures for project switching
- **Modal**: Project list in overlay modal triggered by menu button

## Integration Points

### API Integration
- **Project Loading**: `GET /v1/projects` for initial project list
- **Project Creation**: `POST /v1/projects` for new project creation
- **Project Updates**: `PUT /v1/projects/{id}` for project modifications
- **Statistics**: `GET /v1/projects/{id}/statistics` for real-time project stats

### Local Storage
- **Selection Persistence**: Current project ID stored locally
- **UI Preferences**: Sidebar collapse state, sort preferences
- **Cache**: Project list cached for offline functionality
- **Sync**: Local changes synchronized with server when online

### State Management
- **Global State**: Selected project ID shared across application
- **Local State**: Loading states, error states, UI interactions
- **Event Propagation**: Project selection triggers app-wide updates
- **Optimistic Updates**: Immediate UI feedback before API confirmation

## Data Structure

### Project Object Schema
```javascript
{
  id: "uuid-string",
  name: "Project Name",
  description: "Project description",
  color: "#ff6b6b", // Theme color
  is_default: false,
  is_completed: false,
  created_at: "2023-10-06T00:00:00Z",
  updated_at: "2023-10-06T00:00:00Z",
  statistics: {
    total_tasks: 15,
    completed_tasks: 8,
    completion_percent: 53,
    total_pomodoros: 24,
    total_time_seconds: 36000,
    total_time_formatted: "10h 0m",
    last_activity_at: "2023-10-06T10:00:00Z"
  }
}
```

## Wireframe

```
┌─────────────────────────────────────────┐
│                📋 我的项目         [➕] │
├─────────────────────────────────────────┤
│                                         │
│ 📥 Inbox                           [5]  │
│ ████████████████░░░░░░░░  67%           │
│ 12 tasks • 8 pomodoros                  │
│                                         │
│ 💼 Work Project                    [3]  │
│ ████████████████████████  100%         │
│ 5 tasks • 15 pomodoros                  │
│                                         │
│ 📚 Study Project                   [7]  │
│ ████████░░░░░░░░░░░░░░░░  33%           │
│ 15 tasks • 6 pomodoros                  │
│                                         │
│ 🏠 Personal                        [2]  │
│ ████████████░░░░░░░░░░░░  50%           │
│ 4 tasks • 3 pomodoros                   │
│                                         │
├─────────────────────────────────────────┤
│           📊 今日统计                    │
│                                         │
│ 🍅 完成番茄钟    6                       │
│ ⏱️ 专注时间     2h 30m                   │
│ ✅ 完成任务     4                       │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.project-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  height: calc(100% - 120px);
  overflow-y: auto;
}

.project-item {
  padding: 16px;
  border-radius: 12px;
  background: white;
  border: 2px solid transparent;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

.project-item:hover {
  border-color: var(--primary-color);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.project-item.active {
  border-color: var(--primary-color);
  background: var(--primary-light-bg);
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.project-name {
  font-weight: 600;
  font-size: 16px;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: 8px;
}

.project-badge {
  background: var(--primary-color);
  color: white;
  padding: 2px 6px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  min-width: 20px;
  text-align: center;
}

.project-progress {
  width: 100%;
  height: 6px;
  background: var(--border-color);
  border-radius: 3px;
  overflow: hidden;
  margin: 8px 0;
}

.project-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--success-color), var(--primary-color));
  transition: width 0.3s ease;
}

.project-stats {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: var(--text-secondary);
}

.project-actions {
  position: absolute;
  top: 8px;
  right: 8px;
  opacity: 0;
  transition: opacity 0.2s ease;
  display: flex;
  gap: 4px;
}

.project-item:hover .project-actions {
  opacity: 1;
}
```

### JavaScript Structure
```javascript
class ProjectList {
  constructor(props) {
    this.props = props;
    this.state = {
      projects: props.projects || [],
      selectedId: props.currentProjectId,
      isLoading: props.isLoading || false,
      error: null
    };
    this.init();
  }

  init() {
    this.loadProjects();
    this.bindEvents();
    this.setupAccessibility();
  }

  async loadProjects() {
    try {
      this.setState({ isLoading: true, error: null });
      const response = await fetch('/v1/projects', {
        headers: { 'Authorization': 'Bearer ' + this.getToken() }
      });

      if (!response.ok) throw new Error('Failed to load projects');

      const data = await response.json();
      this.setState({
        projects: data.data,
        isLoading: false
      });
    } catch (error) {
      this.setState({
        isLoading: false,
        error: error.message
      });
    }
  }

  selectProject(projectId) {
    this.setState({ selectedId: projectId });
    this.props.onProjectSelect(projectId);

    // Persist selection
    localStorage.setItem('selectedProjectId', projectId);

    // Update global state
    this.updateAppState({ currentProjectId: projectId });
  }

  render() {
    const { projects, isLoading, error, selectedId } = this.state;

    if (isLoading) return this.renderLoadingState();
    if (error) return this.renderErrorState();
    if (projects.length === 0) return this.renderEmptyState();

    return `
      <div class="project-list" role="navigation" aria-label="Project navigation">
        ${projects.map(project => this.renderProjectItem(project)).join('')}
      </div>
    `;
  }

  renderProjectItem(project) {
    const isActive = project.id === this.state.selectedId;
    const progress = project.statistics?.completion_percent || 0;

    return `
      <div class="project-item ${isActive ? 'active' : ''}"
           data-project-id="${project.id}"
           tabindex="0"
           role="button"
           aria-pressed="${isActive}"
           aria-label="Project: ${project.name}, ${project.statistics?.total_tasks || 0} tasks, ${progress}% complete">

        <div class="project-header">
          <div class="project-name">
            <span>${project.name}</span>
          </div>
          <div class="project-badge">
            ${project.statistics?.total_tasks || 0}
          </div>
        </div>

        <div class="project-progress">
          <div class="project-progress-fill" style="width: ${progress}%"></div>
        </div>

        <div class="project-stats">
          <span>${project.statistics?.total_tasks || 0} tasks</span>
          <span>${project.statistics?.total_pomodoros || 0} pomodoros</span>
        </div>

        <div class="project-actions">
          <button class="btn-edit-project" data-project-id="${project.id}" aria-label="Edit project">✏️</button>
          <button class="btn-delete-project" data-project-id="${project.id}" aria-label="Delete project">🗑️</button>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // Project selection
    document.addEventListener('click', (e) => {
      const projectItem = e.target.closest('.project-item');
      if (projectItem) {
        const projectId = projectItem.dataset.projectId;
        this.selectProject(projectId);
      }
    });

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.target.classList.contains('project-item')) {
        this.handleKeyNavigation(e);
      }
    });
  }

  handleKeyNavigation(e) {
    const currentItem = e.target;
    const items = Array.from(document.querySelectorAll('.project-item'));
    const currentIndex = items.indexOf(currentItem);

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        const nextIndex = (currentIndex + 1) % items.length;
        items[nextIndex].focus();
        break;

      case 'ArrowUp':
        e.preventDefault();
        const prevIndex = currentIndex === 0 ? items.length - 1 : currentIndex - 1;
        items[prevIndex].focus();
        break;

      case 'Enter':
      case ' ':
        e.preventDefault();
        const projectId = currentItem.dataset.projectId;
        this.selectProject(projectId);
        break;
    }
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Project list rendering with different data sets
- [ ] Project selection and state management
- [ ] Loading and error state handling
- [ ] Responsive layout behavior

### Integration Tests
- [ ] API integration for project loading and updates
- [ ] Local storage persistence of selected project
- [ ] Cross-component communication (project selection events)
- [ ] Performance under large project lists (100+ projects)

### Accessibility Tests
- [ ] Keyboard navigation through project list
- [ ] Screen reader announcements for project changes
- [ ] Focus management and visual indicators
- [ ] ARIA attributes validation

### Performance Tests
- [ ] Rendering performance with large project lists
- [ ] Smooth animation performance for expand/collapse
- [ ] Memory usage during extended use
- [ ] Network request optimization (caching, debouncing)

## Usage Examples

### Basic Usage
```html
<project-list
  projects="[{projectArray}]"
  currentProjectId="project-1"
  onProjectSelect="handleProjectSelection">
</project-list>
```

### Advanced Usage
```html
<project-list
  projects="[{projectArray}]"
  currentProjectId="project-1"
  isCollapsed="false"
  showStats="true"
  isLoading="false"
  onProjectSelect="handleProjectSelection"
  onProjectCreate="handleProjectCreation"
  onProjectEdit="handleProjectEdit"
  onProjectDelete="handleProjectDelete">
</project-list>
```

### Responsive Usage
```html
<project-list
  projects="[{projectArray}]"
  currentProjectId="project-1"
  isCollapsed="{{isMobile}}"
  showStats="{{!isMobile}}"
  onProjectSelect="handleProjectSelection">
</project-list>
```

This ProjectList component serves as the foundation for project-first navigation, enabling users to efficiently organize and access their work through a clear hierarchical structure while maintaining excellent performance and accessibility standards.