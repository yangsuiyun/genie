# ProjectHeader Component

**Component Type**: content
**Complexity Level**: moderate
**Dependencies**: ProjectSelector, StatsSummary, ActionMenu
**Estimated Implementation Time**: 6 hours

## Component Metadata

- **component_name**: ProjectHeader
- **component_type**: content
- **complexity_level**: moderate
- **dependencies**: [ProjectSelector, StatsSummary, ActionMenu, API integration]
- **estimated_implementation_time**: 6 hours

## Purpose

The ProjectHeader component serves as the primary header for the main content area, displaying the current project information, key statistics, and project-level actions. It provides context for all tasks and activities within the selected project while offering quick access to project management functions.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| project | object | true | null | Valid project object | Current project data |
| statistics | object | false | null | Valid stats object | Project statistics |
| isLoading | boolean | false | false | true\|false | Loading state for project data |
| canEdit | boolean | false | true | true\|false | User permission to edit project |
| canDelete | boolean | false | false | true\|false | User permission to delete project |
| onProjectEdit | function | false | null | Valid function | Callback for project editing |
| onProjectDelete | function | false | null | Valid function | Callback for project deletion |
| onProjectComplete | function | false | null | Valid function | Callback for project completion |
| onSettingsOpen | function | false | null | Valid function | Callback for project settings |
| showBreadcrumb | boolean | false | true | true\|false | Whether to show navigation breadcrumb |
| compactMode | boolean | false | false | true\|false | Compact display for smaller screens |

## Visual States

### Default State
- **Layout**: Horizontal layout with project info on left, actions on right
- **Typography**: Project name prominent, statistics clearly visible
- **Colors**: Project theme color accents, neutral background
- **Actions**: Edit, settings, and completion buttons visible

### Loading State
- **Skeleton**: Animated placeholders for project name and statistics
- **Actions**: Disabled state for all interactive elements
- **Animation**: Subtle shimmer effect on placeholder elements
- **Duration**: Brief loading period with progressive data appearance

### Empty Project State
- **Display**: "No project selected" message with guidance
- **Action**: Prominent "Select Project" or "Create Project" button
- **Visual**: Subdued styling to indicate inactive state
- **Context**: Clear explanation of project-first workflow

### Error State
- **Message**: Clear error description (e.g., "Unable to load project")
- **Recovery**: Retry button or fallback to cached data
- **Visual**: Error styling with appropriate color coding
- **Actions**: Disabled project actions until error resolved

### Completed Project State
- **Indicator**: Completed project badge/checkmark
- **Style**: Subtle green accent and completion date
- **Actions**: Different action set (archive, reopen, duplicate)
- **Context**: Clear indication that project is finished

## Accessibility

### Keyboard Navigation
- **Tab Order**: Project name → statistics → action buttons
- **Activation**: Enter key for primary actions, Space for toggles
- **Shortcuts**: E for edit, S for settings, C for complete

### Screen Reader Support
- **aria-label**: "Project header for [project name]"
- **Role**: "banner" for main project context
- **aria-live**: "polite" for statistics updates
- **Description**: Project status and key metrics announced

### Focus Management
- **Indicators**: Clear visual focus states for all interactive elements
- **Navigation**: Logical tab order through header components
- **Restoration**: Focus returns appropriately after modal dialogs
- **Skip Links**: "Skip to project content" option

## Responsive Behavior

### Desktop (>1024px)
- **Layout**: Full horizontal layout with all information visible
- **Statistics**: Complete statistics display with detailed breakdowns
- **Actions**: Full action menu with text labels
- **Spacing**: Generous padding and margins for comfortable viewing

### Tablet (768-1024px)
- **Layout**: Slightly condensed with abbreviated statistics
- **Actions**: Icon + text buttons, some secondary actions in dropdown
- **Breakpoint**: Statistics may wrap to second line
- **Touch**: Enhanced touch targets for tablet interaction

### Mobile (<768px)
- **Layout**: Vertical stack or compact horizontal with overflow menu
- **Statistics**: Essential statistics only, details in expandable section
- **Actions**: Icon-only buttons in hamburger menu
- **Navigation**: Breadcrumb may be hidden or simplified

## Integration Points

### Project Data API
- **Project Info**: Real-time project data from `/v1/projects/{id}`
- **Statistics**: Live statistics from `/v1/projects/{id}/statistics`
- **Updates**: Optimistic updates for project modifications
- **Permissions**: User permissions for project actions

### Navigation Context
- **Breadcrumb**: Integration with app navigation state
- **Deep Links**: Support for direct project URL navigation
- **History**: Browser back/forward navigation support
- **State**: Sync with global app state management

### Action Integration
- **Edit Modal**: Launch project editing interface
- **Settings Panel**: Open project configuration sidebar
- **Completion**: Handle project completion workflow
- **Deletion**: Confirm and execute project deletion

## Data Structure

### Project Object Schema
```javascript
{
  id: "uuid-string",
  name: "Project Name",
  description: "Project description",
  color: "#ff6b6b",
  is_default: false,
  is_completed: false,
  completion_date: null,
  created_at: "2023-10-06T00:00:00Z",
  updated_at: "2023-10-06T00:00:00Z",
  owner_id: "uuid-string",
  team_members: ["uuid-1", "uuid-2"],
  settings: {
    visibility: "private",
    notifications: true,
    auto_archive: false
  }
}
```

### Statistics Object Schema
```javascript
{
  total_tasks: 15,
  completed_tasks: 8,
  completion_percent: 53,
  in_progress_tasks: 4,
  pending_tasks: 3,
  total_pomodoros: 24,
  total_time_seconds: 36000,
  total_time_formatted: "10h 0m",
  avg_pomodoro_duration: 1500,
  last_activity_at: "2023-10-06T10:00:00Z",
  team_productivity: {
    daily_average: 3.2,
    weekly_trend: "up"
  }
}
```

## Wireframe

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Home > Projects > Work Project                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  💼 Work Project                                              [⚙️] [✏️] [⋮] │
│  Frontend development and UI/UX improvements                                │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  📊 项目统计                                                             │ │
│  │                                                                         │ │
│  │  📋 24 总任务    ✅ 12 已完成    🔄 8 进行中    ⏳ 4 待开始             │ │
│  │  🍅 36 番茄钟    ⏱️ 15h 30m     📈 67% 完成率   🎯 本周 +15%           │ │
│  │                                                                         │ │
│  │  进度条: ████████████████████████████░░░░░░░░░░░░  67%                  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  最后活动: 2小时前 • 创建于: 2023年10月1日                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.project-header {
  background: var(--surface-color);
  border-bottom: 1px solid var(--border-color);
  padding: 24px;
  position: sticky;
  top: 0;
  z-index: 50;
  box-shadow: var(--shadow-light);
}

.project-header.compact {
  padding: 16px;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  font-size: 14px;
  color: var(--text-secondary);
}

.breadcrumb-link {
  color: var(--primary-color);
  text-decoration: none;
  transition: var(--transition);
}

.breadcrumb-link:hover {
  text-decoration: underline;
}

.breadcrumb-separator {
  color: var(--text-disabled);
}

.project-title-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
}

.project-info {
  flex: 1;
}

.project-title {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.project-icon {
  font-size: 24px;
  color: var(--project-color);
}

.project-name {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
}

.project-description {
  color: var(--text-secondary);
  font-size: 16px;
  line-height: 1.5;
  margin-bottom: 16px;
}

.project-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

.action-btn {
  padding: 8px 16px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  background: var(--surface-color);
  color: var(--text-primary);
  cursor: pointer;
  transition: var(--transition);
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}

.action-btn:hover {
  border-color: var(--primary-color);
  background: var(--primary-light-bg);
}

.action-btn.primary {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.action-btn.primary:hover {
  background: var(--primary-dark);
}

.project-statistics {
  background: var(--background-light);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 16px;
}

.stats-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  font-weight: 600;
  color: var(--text-primary);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.stat-item {
  text-align: center;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-color);
  display: block;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: var(--text-secondary);
  font-weight: 500;
}

.progress-section {
  margin-top: 16px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: var(--border-color);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--success-color), var(--primary-color));
  transition: width 0.5s ease;
  border-radius: 4px;
}

.progress-text {
  text-align: right;
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.project-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: var(--text-secondary);
  margin-top: 16px;
}

.project-meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .project-header {
    padding: 16px;
  }

  .project-title-section {
    flex-direction: column;
    gap: 16px;
  }

  .project-name {
    font-size: 24px;
  }

  .project-actions {
    align-self: stretch;
    justify-content: space-between;
  }

  .action-btn {
    flex: 1;
    justify-content: center;
    padding: 12px;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }

  .project-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}

/* Loading states */
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}

.skeleton.title {
  height: 32px;
  width: 200px;
  margin-bottom: 8px;
}

.skeleton.description {
  height: 16px;
  width: 300px;
  margin-bottom: 16px;
}

.skeleton.stat {
  height: 20px;
  width: 60px;
}

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
```

### JavaScript Structure
```javascript
class ProjectHeader {
  constructor(props) {
    this.props = props;
    this.state = {
      project: props.project || null,
      statistics: props.statistics || null,
      isLoading: props.isLoading || false,
      error: null
    };
    this.init();
  }

  init() {
    if (!this.state.project && this.props.projectId) {
      this.loadProject();
    }
    this.bindEvents();
  }

  async loadProject() {
    try {
      this.setState({ isLoading: true, error: null });

      const [projectResponse, statsResponse] = await Promise.all([
        fetch(`/v1/projects/${this.props.projectId}`, {
          headers: { 'Authorization': 'Bearer ' + this.getToken() }
        }),
        fetch(`/v1/projects/${this.props.projectId}/statistics`, {
          headers: { 'Authorization': 'Bearer ' + this.getToken() }
        })
      ]);

      if (!projectResponse.ok || !statsResponse.ok) {
        throw new Error('Failed to load project data');
      }

      const project = await projectResponse.json();
      const statistics = await statsResponse.json();

      this.setState({
        project: project.data,
        statistics: statistics.data,
        isLoading: false
      });

    } catch (error) {
      console.error('Failed to load project:', error);
      this.setState({
        isLoading: false,
        error: error.message
      });
    }
  }

  render() {
    const { project, statistics, isLoading, error } = this.state;
    const { compactMode, showBreadcrumb } = this.props;

    if (isLoading) return this.renderLoadingState();
    if (error) return this.renderErrorState();
    if (!project) return this.renderEmptyState();

    return `
      <div class="project-header ${compactMode ? 'compact' : ''}"
           role="banner"
           aria-label="Project header for ${project.name}">

        ${showBreadcrumb ? this.renderBreadcrumb() : ''}

        <div class="project-title-section">
          <div class="project-info">
            <div class="project-title">
              <span class="project-icon" style="color: ${project.color}">
                ${this.getProjectIcon(project)}
              </span>
              <h1 class="project-name">${project.name}</h1>
              ${project.is_completed ? '<span class="completion-badge">✅</span>' : ''}
            </div>
            ${project.description ? `<p class="project-description">${project.description}</p>` : ''}
          </div>

          <div class="project-actions">
            ${this.renderActionButtons()}
          </div>
        </div>

        ${statistics ? this.renderStatistics() : ''}

        <div class="project-meta">
          <div class="project-meta-item">
            <span>最后活动:</span>
            <span>${this.formatLastActivity(statistics?.last_activity_at)}</span>
          </div>
          <div class="project-meta-item">
            <span>创建于:</span>
            <span>${this.formatDate(project.created_at)}</span>
          </div>
        </div>
      </div>
    `;
  }

  renderBreadcrumb() {
    return `
      <nav class="breadcrumb" aria-label="Breadcrumb navigation">
        <a href="#/" class="breadcrumb-link">Home</a>
        <span class="breadcrumb-separator">></span>
        <a href="#/projects" class="breadcrumb-link">Projects</a>
        <span class="breadcrumb-separator">></span>
        <span class="breadcrumb-current">${this.state.project.name}</span>
      </nav>
    `;
  }

  renderActionButtons() {
    const { project } = this.state;
    const { canEdit, canDelete } = this.props;

    const buttons = [];

    if (canEdit) {
      buttons.push(`
        <button class="action-btn"
                onclick="this.handleEditProject()"
                aria-label="Edit project">
          <span>✏️</span>
          <span>Edit</span>
        </button>
      `);
    }

    buttons.push(`
      <button class="action-btn"
              onclick="this.handleProjectSettings()"
              aria-label="Project settings">
        <span>⚙️</span>
        <span>Settings</span>
      </button>
    `);

    if (!project.is_completed) {
      buttons.push(`
        <button class="action-btn primary"
                onclick="this.handleCompleteProject()"
                aria-label="Mark project as complete">
          <span>✅</span>
          <span>Complete</span>
        </button>
      `);
    }

    buttons.push(`
      <button class="action-btn"
              onclick="this.handleMoreActions()"
              aria-label="More actions">
        <span>⋮</span>
      </button>
    `);

    return buttons.join('');
  }

  renderStatistics() {
    const { statistics } = this.state;
    if (!statistics) return '';

    return `
      <div class="project-statistics" role="region" aria-label="Project statistics">
        <div class="stats-header">
          <span>📊</span>
          <span>项目统计</span>
        </div>

        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-value">${statistics.total_tasks}</span>
            <span class="stat-label">总任务</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.completed_tasks}</span>
            <span class="stat-label">已完成</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.in_progress_tasks || 0}</span>
            <span class="stat-label">进行中</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.pending_tasks || 0}</span>
            <span class="stat-label">待开始</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.total_pomodoros}</span>
            <span class="stat-label">番茄钟</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.total_time_formatted}</span>
            <span class="stat-label">总时间</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">${statistics.completion_percent}%</span>
            <span class="stat-label">完成率</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">+${statistics.team_productivity?.weekly_trend || 0}%</span>
            <span class="stat-label">本周</span>
          </div>
        </div>

        <div class="progress-section">
          <div class="progress-bar">
            <div class="progress-fill"
                 style="width: ${statistics.completion_percent}%"
                 role="progressbar"
                 aria-valuenow="${statistics.completion_percent}"
                 aria-valuemin="0"
                 aria-valuemax="100"
                 aria-label="Project completion progress">
            </div>
          </div>
          <div class="progress-text">${statistics.completion_percent}%</div>
        </div>
      </div>
    `;
  }

  renderLoadingState() {
    return `
      <div class="project-header" aria-label="Loading project information">
        <div class="project-title-section">
          <div class="project-info">
            <div class="skeleton title"></div>
            <div class="skeleton description"></div>
          </div>
        </div>
        <div class="project-statistics">
          <div class="stats-grid">
            ${Array(8).fill(0).map(() => '<div class="stat-item"><div class="skeleton stat"></div></div>').join('')}
          </div>
        </div>
      </div>
    `;
  }

  renderErrorState() {
    return `
      <div class="project-header error" role="alert">
        <div class="error-message">
          <h2>❌ Unable to load project</h2>
          <p>${this.state.error}</p>
          <button class="btn btn-primary" onclick="this.loadProject()">
            Retry
          </button>
        </div>
      </div>
    `;
  }

  renderEmptyState() {
    return `
      <div class="project-header empty">
        <div class="empty-message">
          <h2>📋 No project selected</h2>
          <p>Select a project from the sidebar to view its details and tasks.</p>
          <button class="btn btn-primary" onclick="this.handleSelectProject()">
            Select Project
          </button>
        </div>
      </div>
    `;
  }

  getProjectIcon(project) {
    // Map project types to appropriate icons
    const iconMap = {
      'work': '💼',
      'personal': '🏠',
      'study': '📚',
      'health': '🏃',
      'default': '📋'
    };

    return iconMap[project.type] || iconMap.default;
  }

  formatLastActivity(timestamp) {
    if (!timestamp) return 'No activity';

    const now = new Date();
    const activity = new Date(timestamp);
    const diffMs = now - activity;
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffHours / 24);

    if (diffHours < 1) return '刚刚';
    if (diffHours < 24) return `${diffHours}小时前`;
    if (diffDays < 7) return `${diffDays}天前`;
    return this.formatDate(timestamp);
  }

  formatDate(timestamp) {
    return new Date(timestamp).toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }

  handleEditProject() {
    if (this.props.onProjectEdit) {
      this.props.onProjectEdit(this.state.project);
    }
  }

  handleProjectSettings() {
    if (this.props.onSettingsOpen) {
      this.props.onSettingsOpen(this.state.project);
    }
  }

  handleCompleteProject() {
    if (this.props.onProjectComplete) {
      this.props.onProjectComplete(this.state.project);
    }
  }

  handleMoreActions() {
    // Show dropdown menu with additional actions
    this.showActionMenu();
  }

  bindEvents() {
    // Listen for project updates
    document.addEventListener('projectUpdated', (event) => {
      if (event.detail.projectId === this.state.project?.id) {
        this.setState({ project: event.detail.project });
      }
    });

    // Listen for statistics updates
    document.addEventListener('projectStatsUpdated', (event) => {
      if (event.detail.projectId === this.state.project?.id) {
        this.setState({ statistics: event.detail.statistics });
      }
    });
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Project data loading and display
- [ ] Statistics calculation and formatting
- [ ] Action button functionality and permissions
- [ ] Responsive layout behavior

### Integration Tests
- [ ] API integration for project and statistics data
- [ ] Real-time updates for project changes
- [ ] Navigation integration with breadcrumbs
- [ ] Modal integration for project editing

### Accessibility Tests
- [ ] Keyboard navigation through all interactive elements
- [ ] Screen reader announcements for project information
- [ ] ARIA attributes and semantic markup validation
- [ ] Focus management during project operations

### Performance Tests
- [ ] Rendering performance with complex project data
- [ ] Statistics update performance
- [ ] Memory usage during extended use
- [ ] Network request optimization

## Usage Examples

### Basic Usage
```html
<project-header
  project="{projectObject}"
  statistics="{statisticsObject}"
  onProjectEdit="handleProjectEdit"
  onProjectComplete="handleProjectComplete">
</project-header>
```

### With Permissions
```html
<project-header
  project="{projectObject}"
  statistics="{statisticsObject}"
  canEdit="true"
  canDelete="false"
  onProjectEdit="handleProjectEdit"
  onProjectDelete="handleProjectDelete"
  onProjectComplete="handleProjectComplete">
</project-header>
```

### Compact Mobile Mode
```html
<project-header
  project="{projectObject}"
  statistics="{statisticsObject}"
  compactMode="true"
  showBreadcrumb="false"
  onProjectEdit="handleProjectEdit">
</project-header>
```

This ProjectHeader component provides essential project context and management capabilities while maintaining the project-first architecture focus and ensuring excellent user experience across all device types.