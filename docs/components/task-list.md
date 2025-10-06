# TaskList Component

**Component Type**: content
**Complexity Level**: complex
**Dependencies**: TaskCard, PomodoroModal, API integration, State management
**Estimated Implementation Time**: 10 hours

## Component Metadata

- **component_name**: TaskList
- **component_type**: content
- **complexity_level**: complex
- **dependencies**: [TaskCard, PomodoroModal, API integration, State management, localStorage]
- **estimated_implementation_time**: 10 hours

## Purpose

The TaskList component serves as the primary content area displaying all tasks for the selected project. It provides comprehensive task management functionality including filtering, sorting, bulk operations, and seamless integration with individual task pomodoro sessions. This component is central to the project-first architecture.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| projectId | string | true | null | Valid UUID | Current project ID for task filtering |
| tasks | array | false | [] | Valid task objects | Array of task data (optional, loads from API) |
| filter | string | false | 'all' | all\|pending\|in_progress\|completed | Current filter setting |
| sortBy | string | false | 'created_at' | Valid sort field | Sort criteria for task ordering |
| sortOrder | string | false | 'desc' | asc\|desc | Sort direction |
| searchQuery | string | false | '' | string | Search/filter text |
| isLoading | boolean | false | false | true\|false | Loading state indicator |
| onTaskSelect | function | false | null | Valid function | Callback when task is selected |
| onTaskUpdate | function | true | null | Valid function | Callback for task updates |
| onTaskDelete | function | true | null | Valid function | Callback for task deletion |
| onTaskCreate | function | true | null | Valid function | Callback for new task creation |
| onPomodoroStart | function | true | null | Valid function | Callback when pomodoro starts |
| selectedTaskIds | array | false | [] | Valid UUID array | Currently selected tasks for bulk operations |
| showCompleted | boolean | false | true | true\|false | Whether to show completed tasks |
| viewMode | string | false | 'list' | list\|grid\|compact | Display mode for tasks |

## Visual States

### Default State
- **Layout**: Vertical list with task cards, proper spacing and hover effects
- **Header**: Filter tabs, sort dropdown, search input, add task button
- **Tasks**: Individual task cards with all information visible
- **Actions**: Bulk operation toolbar when multiple tasks selected

### Loading State
- **Skeleton**: 3-5 skeleton task cards with shimmer animation
- **Toolbar**: Disabled state for all interactive elements
- **Message**: "Loading tasks..." for screen readers
- **Progressive**: Individual task cards appear as they load

### Empty State
- **No Tasks**: "No tasks in this project yet"
- **Create CTA**: Prominent "Create First Task" button
- **Illustration**: Simple icon or graphic
- **Guidance**: Helpful text about task management

### Filtered Empty State
- **Message**: "No tasks match your current filters"
- **Actions**: "Clear filters" button, alternative filter suggestions
- **Context**: Show current filter settings clearly
- **Recovery**: Easy way to return to all tasks view

### Error State
- **Message**: Clear error description with context
- **Retry**: Prominent retry button for network errors
- **Fallback**: Show cached tasks if available
- **Support**: Link to help or contact information

### Selection Mode
- **Visual**: Selected tasks highlighted with checkboxes
- **Toolbar**: Bulk actions toolbar appears (edit, delete, move, etc.)
- **Counter**: "X tasks selected" indicator
- **Actions**: Clear selection, select all/none options

## Accessibility

### Keyboard Navigation
- **Tab Order**: Filter tabs → search → sort → task cards → bulk actions
- **Task Navigation**: Arrow keys to navigate between tasks
- **Selection**: Space bar to select/deselect, Ctrl+A for select all
- **Actions**: Enter to open task, P to start pomodoro

### Screen Reader Support
- **aria-label**: "Task list for [project name]"
- **aria-live**: "polite" for filter and sort updates
- **Role**: "list" for task container, "listitem" for each task
- **Status**: Announce "X tasks shown, Y completed" after updates

### Focus Management
- **Restoration**: Focus returns to appropriate element after modals
- **Skip Links**: "Skip to task content" for header-heavy interfaces
- **Indicators**: Clear visual focus states for all interactive elements
- **Trapping**: Focus management within modal dialogs

## Responsive Behavior

### Desktop (>1024px)
- **Layout**: Full list view with complete task information
- **Columns**: Optional multi-column layout for wide screens
- **Sidebar**: Task detail panel can open alongside list
- **Bulk Actions**: Full toolbar with all available actions

### Tablet (768-1024px)
- **Layout**: Single column with slightly reduced task card size
- **Touch**: Enhanced touch targets for better interaction
- **Swipe**: Swipe gestures for common actions (mark complete, delete)
- **Compact**: Some non-essential information hidden to save space

### Mobile (<768px)
- **Layout**: Full-width cards with vertical stacking
- **Gestures**: Swipe left/right for actions, pull to refresh
- **Modal**: Task editing in full-screen modal
- **FAB**: Floating action button for new task creation
- **Filter**: Collapsible filter/sort interface

## Integration Points

### API Integration
- **Task Loading**: `GET /v1/projects/{id}/tasks` for project-specific tasks
- **Task Creation**: `POST /v1/tasks` for new task creation
- **Task Updates**: `PUT /v1/tasks/{id}` for modifications
- **Task Deletion**: `DELETE /v1/tasks/{id}` for removal
- **Bulk Operations**: `PATCH /v1/tasks/bulk` for multiple task operations

### Real-time Updates
- **WebSocket**: Live updates when tasks change in other sessions
- **Optimistic Updates**: Immediate UI feedback before API confirmation
- **Conflict Resolution**: Handle concurrent edits gracefully
- **Sync Status**: Show sync status and handle offline scenarios

### State Management
- **Global State**: Current project, selected tasks, filter preferences
- **Local State**: UI interactions, temporary selections, modal states
- **Persistence**: Filter and sort preferences saved to localStorage
- **Cache**: Task data cached for offline access and performance

### Pomodoro Integration
- **Session Start**: Direct integration with PomodoroModal component
- **Task Context**: Current task information passed to pomodoro session
- **Progress Tracking**: Update task pomodoro count after sessions
- **Active Indicator**: Show which task has active pomodoro session

## Data Structure

### Task Object Schema
```javascript
{
  id: "uuid-string",
  title: "Task title",
  description: "Task description",
  status: "pending", // pending | in_progress | completed
  priority: "medium", // low | medium | high | urgent
  project_id: "uuid-string",
  created_at: "2023-10-06T00:00:00Z",
  updated_at: "2023-10-06T00:00:00Z",
  due_date: "2023-10-08T00:00:00Z",
  completed_at: null,
  pomodoro_count: 3,
  estimated_pomodoros: 5,
  tags: ["frontend", "urgent"],
  assignee_id: "uuid-string",
  subtasks: [
    {
      id: "uuid-string",
      title: "Subtask title",
      completed: false
    }
  ]
}
```

### Filter State Schema
```javascript
{
  status: "all", // all | pending | in_progress | completed
  priority: "all", // all | low | medium | high | urgent
  tags: [],
  assignee: "all",
  dateRange: {
    start: null,
    end: null
  },
  search: "",
  sortBy: "created_at",
  sortOrder: "desc"
}
```

## Wireframe

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📋 任务列表                                    [搜索...] [筛选] [➕ 新建任务]  │
├─────────────────────────────────────────────────────────────────────────────┤
│  [全部] [待开始] [进行中] [已完成]                          按创建时间 ↓     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ ☐ 完成项目架构设计                                   [🍅开始番茄钟]     │ │
│  │   设计前端项目优先架构，包括左侧边栏和任务管理系统                     │ │
│  │   🔴高优先级  📅10月8日  🍅2/5  👤张三              ✏️ 🗑️           │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ ☐ 实现响应式布局                                     [🍅开始番茄钟]     │ │
│  │   为移动端和桌面端创建响应式设计                                         │ │
│  │   🟡中优先级  📅10月9日  🍅1/3  👤李四              ✏️ 🗑️           │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ ☑ 编写API文档                                                          │ │
│  │   完成后端API接口文档编写和测试                                         │ │
│  │   ✅已完成  📅10月7日  🍅5/5  👤王五                                   │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ ☐ 用户测试计划                                       [🍅开始番茄钟]     │ │
│  │   制定用户测试计划和执行方案                                             │ │
│  │   🟢低优先级  📅10月10日  🍅0/2  👤赵六             ✏️ 🗑️           │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  显示 4 个任务，1 个已完成                               [批量操作] [导出]   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.task-list {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
}

.task-list-header {
  padding: 24px;
  background: var(--surface-color);
  border-bottom: 1px solid var(--border-color);
  position: sticky;
  top: 0;
  z-index: 10;
}

.task-list-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.task-list-controls {
  display: flex;
  gap: 16px;
  align-items: center;
  flex-wrap: wrap;
}

.filter-tabs {
  display: flex;
  gap: 8px;
  padding: 8px;
  background: var(--background-light);
  border-radius: 8px;
}

.filter-tab {
  padding: 8px 16px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: var(--text-secondary);
  cursor: pointer;
  transition: var(--transition);
  font-weight: 500;
}

.filter-tab.active {
  background: var(--primary-color);
  color: white;
}

.filter-tab:hover:not(.active) {
  background: var(--border-color);
  color: var(--text-primary);
}

.search-input {
  flex: 1;
  min-width: 200px;
  padding: 10px 16px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  font-size: 14px;
  transition: var(--transition);
}

.search-input:focus {
  outline: none;
  border-color: var(--primary-color);
  box-shadow: 0 0 0 3px rgba(211, 47, 47, 0.1);
}

.sort-dropdown {
  padding: 10px 16px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  background: var(--surface-color);
  cursor: pointer;
  font-size: 14px;
}

.task-list-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.task-list-items {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.task-list-items.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
}

.task-list-items.compact .task-card {
  padding: 12px 16px;
}

.bulk-actions-toolbar {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--primary-color);
  color: white;
  padding: 12px 24px;
  border-radius: 24px;
  box-shadow: var(--shadow-heavy);
  display: flex;
  gap: 16px;
  align-items: center;
  animation: slideUp 0.3s ease-out;
  z-index: 100;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(100%);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}

.task-list-footer {
  padding: 16px 24px;
  background: var(--surface-color);
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: var(--text-secondary);
}

/* Empty states */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-secondary);
}

.empty-state-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.6;
}

.empty-state-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--text-primary);
}

.empty-state-description {
  margin-bottom: 24px;
  line-height: 1.5;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .task-list-header {
    padding: 16px;
  }

  .task-list-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .filter-tabs {
    overflow-x: auto;
    flex-wrap: nowrap;
  }

  .search-input {
    min-width: auto;
    width: 100%;
  }

  .task-list-content {
    padding: 16px;
  }

  .bulk-actions-toolbar {
    left: 16px;
    right: 16px;
    transform: none;
    width: calc(100% - 32px);
  }
}
```

### JavaScript Structure
```javascript
class TaskList {
  constructor(props) {
    this.props = props;
    this.state = {
      tasks: props.tasks || [],
      filteredTasks: [],
      isLoading: props.isLoading || false,
      error: null,
      selectedTaskIds: props.selectedTaskIds || [],
      filter: props.filter || 'all',
      searchQuery: props.searchQuery || '',
      sortBy: props.sortBy || 'created_at',
      sortOrder: props.sortOrder || 'desc'
    };
    this.init();
  }

  init() {
    this.loadTasks();
    this.bindEvents();
    this.setupRealTimeUpdates();
  }

  async loadTasks() {
    if (!this.props.projectId) return;

    try {
      this.setState({ isLoading: true, error: null });

      const response = await fetch(`/v1/projects/${this.props.projectId}/tasks`, {
        headers: { 'Authorization': 'Bearer ' + this.getToken() }
      });

      if (!response.ok) throw new Error('Failed to load tasks');

      const data = await response.json();

      this.setState({
        tasks: data.data,
        isLoading: false
      });

      this.applyFiltersAndSort();

    } catch (error) {
      console.error('Failed to load tasks:', error);
      this.setState({
        isLoading: false,
        error: error.message
      });
    }
  }

  applyFiltersAndSort() {
    let filtered = [...this.state.tasks];

    // Apply status filter
    if (this.state.filter !== 'all') {
      filtered = filtered.filter(task => task.status === this.state.filter);
    }

    // Apply search filter
    if (this.state.searchQuery) {
      const query = this.state.searchQuery.toLowerCase();
      filtered = filtered.filter(task =>
        task.title.toLowerCase().includes(query) ||
        task.description.toLowerCase().includes(query)
      );
    }

    // Apply sorting
    filtered.sort((a, b) => {
      const aValue = a[this.state.sortBy];
      const bValue = b[this.state.sortBy];

      if (this.state.sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

    this.setState({ filteredTasks: filtered });
  }

  setFilter(filter) {
    this.setState({ filter }, () => {
      this.applyFiltersAndSort();
      this.savePreferences();
    });
  }

  setSearch(query) {
    this.setState({ searchQuery: query }, () => {
      this.applyFiltersAndSort();
    });
  }

  setSort(sortBy, sortOrder) {
    this.setState({ sortBy, sortOrder }, () => {
      this.applyFiltersAndSort();
      this.savePreferences();
    });
  }

  toggleTaskSelection(taskId) {
    const { selectedTaskIds } = this.state;
    const isSelected = selectedTaskIds.includes(taskId);

    if (isSelected) {
      this.setState({
        selectedTaskIds: selectedTaskIds.filter(id => id !== taskId)
      });
    } else {
      this.setState({
        selectedTaskIds: [...selectedTaskIds, taskId]
      });
    }
  }

  selectAllTasks() {
    const allTaskIds = this.state.filteredTasks.map(task => task.id);
    this.setState({ selectedTaskIds: allTaskIds });
  }

  clearSelection() {
    this.setState({ selectedTaskIds: [] });
  }

  async handleTaskUpdate(taskId, updates) {
    try {
      // Optimistic update
      this.updateTaskInState(taskId, updates);

      const response = await fetch(`/v1/tasks/${taskId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + this.getToken()
        },
        body: JSON.stringify(updates)
      });

      if (!response.ok) throw new Error('Failed to update task');

      const updatedTask = await response.json();
      this.updateTaskInState(taskId, updatedTask.data);

      this.props.onTaskUpdate?.(updatedTask.data);

    } catch (error) {
      console.error('Failed to update task:', error);
      // Revert optimistic update
      this.loadTasks();
    }
  }

  updateTaskInState(taskId, updates) {
    this.setState(prevState => ({
      tasks: prevState.tasks.map(task =>
        task.id === taskId ? { ...task, ...updates } : task
      )
    }), () => {
      this.applyFiltersAndSort();
    });
  }

  handlePomodoroStart(taskId) {
    const task = this.state.tasks.find(t => t.id === taskId);
    if (task && this.props.onPomodoroStart) {
      this.props.onPomodoroStart(task);
    }
  }

  render() {
    const { filteredTasks, isLoading, error, selectedTaskIds } = this.state;

    if (isLoading) return this.renderLoadingState();
    if (error) return this.renderErrorState();

    return `
      <div class="task-list" role="main" aria-label="Task list for current project">
        ${this.renderHeader()}
        ${this.renderContent()}
        ${this.renderFooter()}
        ${selectedTaskIds.length > 0 ? this.renderBulkActions() : ''}
      </div>
    `;
  }

  renderHeader() {
    return `
      <div class="task-list-header">
        <div class="task-list-title">
          <h2>📋 任务列表</h2>
          <div class="header-actions">
            <input type="text"
                   class="search-input"
                   placeholder="搜索任务..."
                   value="${this.state.searchQuery}"
                   onInput="this.handleSearchInput(event)">
            <select class="sort-dropdown" onchange="this.handleSortChange(event)">
              <option value="created_at:desc">按创建时间 ↓</option>
              <option value="created_at:asc">按创建时间 ↑</option>
              <option value="priority:desc">按优先级 ↓</option>
              <option value="due_date:asc">按截止日期 ↑</option>
            </select>
            <button class="btn btn-primary" onclick="this.handleCreateTask()">
              ➕ 新建任务
            </button>
          </div>
        </div>

        <div class="task-list-controls">
          <div class="filter-tabs" role="tablist">
            ${this.renderFilterTab('all', '全部')}
            ${this.renderFilterTab('pending', '待开始')}
            ${this.renderFilterTab('in_progress', '进行中')}
            ${this.renderFilterTab('completed', '已完成')}
          </div>
        </div>
      </div>
    `;
  }

  renderFilterTab(filter, label) {
    const isActive = this.state.filter === filter;
    const count = this.getFilterCount(filter);

    return `
      <button class="filter-tab ${isActive ? 'active' : ''}"
              role="tab"
              aria-selected="${isActive}"
              onclick="this.setFilter('${filter}')">
        ${label} ${count > 0 ? `(${count})` : ''}
      </button>
    `;
  }

  renderContent() {
    const { filteredTasks } = this.state;

    if (filteredTasks.length === 0) {
      return this.renderEmptyState();
    }

    return `
      <div class="task-list-content">
        <div class="task-list-items ${this.props.viewMode || 'list'}"
             role="list"
             aria-label="${filteredTasks.length} tasks">
          ${filteredTasks.map(task => this.renderTaskItem(task)).join('')}
        </div>
      </div>
    `;
  }

  renderTaskItem(task) {
    const isSelected = this.state.selectedTaskIds.includes(task.id);

    return `
      <task-card
        task-id="${task.id}"
        task-data='${JSON.stringify(task)}'
        is-selected="${isSelected}"
        onTaskUpdate="this.handleTaskUpdate"
        onPomodoroStart="this.handlePomodoroStart"
        onTaskSelect="this.toggleTaskSelection">
      </task-card>
    `;
  }

  renderEmptyState() {
    const isFiltered = this.state.filter !== 'all' || this.state.searchQuery;

    if (isFiltered) {
      return `
        <div class="empty-state">
          <div class="empty-state-icon">🔍</div>
          <div class="empty-state-title">没有找到匹配的任务</div>
          <div class="empty-state-description">
            尝试调整搜索条件或筛选器
          </div>
          <button class="btn btn-secondary" onclick="this.clearFilters()">
            清除筛选器
          </button>
        </div>
      `;
    } else {
      return `
        <div class="empty-state">
          <div class="empty-state-icon">📋</div>
          <div class="empty-state-title">这个项目还没有任务</div>
          <div class="empty-state-description">
            创建第一个任务来开始管理您的工作
          </div>
          <button class="btn btn-primary" onclick="this.handleCreateTask()">
            创建第一个任务
          </button>
        </div>
      `;
    }
  }

  renderBulkActions() {
    const { selectedTaskIds } = this.state;

    return `
      <div class="bulk-actions-toolbar" role="toolbar" aria-label="Bulk actions">
        <span>${selectedTaskIds.length} 个任务已选择</span>
        <button class="btn btn-small" onclick="this.handleBulkComplete()">
          标记完成
        </button>
        <button class="btn btn-small" onclick="this.handleBulkDelete()">
          删除
        </button>
        <button class="btn btn-small" onclick="this.clearSelection()">
          清除选择
        </button>
      </div>
    `;
  }

  renderFooter() {
    const { filteredTasks, tasks } = this.state;
    const completedCount = filteredTasks.filter(t => t.status === 'completed').length;

    return `
      <div class="task-list-footer">
        <span>显示 ${filteredTasks.length} 个任务，${completedCount} 个已完成</span>
        <div class="footer-actions">
          <button class="btn btn-small btn-secondary">批量操作</button>
          <button class="btn btn-small btn-secondary">导出</button>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // Search input debouncing
    let searchTimeout;
    this.handleSearchInput = (event) => {
      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(() => {
        this.setSearch(event.target.value);
      }, 300);
    };

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.ctrlKey || e.metaKey) {
        switch (e.key) {
          case 'a':
            e.preventDefault();
            this.selectAllTasks();
            break;
          case 'n':
            e.preventDefault();
            this.handleCreateTask();
            break;
        }
      }
    });
  }

  getFilterCount(filter) {
    if (filter === 'all') return this.state.tasks.length;
    return this.state.tasks.filter(task => task.status === filter).length;
  }

  savePreferences() {
    const preferences = {
      filter: this.state.filter,
      sortBy: this.state.sortBy,
      sortOrder: this.state.sortOrder
    };
    localStorage.setItem('taskListPreferences', JSON.stringify(preferences));
  }

  setupRealTimeUpdates() {
    // WebSocket or polling for real-time updates
    if (window.WebSocket) {
      this.ws = new WebSocket(`wss://api.example.com/ws/projects/${this.props.projectId}/tasks`);
      this.ws.onmessage = (event) => {
        const update = JSON.parse(event.data);
        this.handleRealTimeUpdate(update);
      };
    }
  }

  handleRealTimeUpdate(update) {
    switch (update.type) {
      case 'task_created':
        this.setState(prevState => ({
          tasks: [...prevState.tasks, update.task]
        }), () => this.applyFiltersAndSort());
        break;

      case 'task_updated':
        this.updateTaskInState(update.task.id, update.task);
        break;

      case 'task_deleted':
        this.setState(prevState => ({
          tasks: prevState.tasks.filter(t => t.id !== update.taskId)
        }), () => this.applyFiltersAndSort());
        break;
    }
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Task filtering and search functionality
- [ ] Sorting and view mode switching
- [ ] Task selection and bulk operations
- [ ] State management and data flow

### Integration Tests
- [ ] API integration for CRUD operations
- [ ] Real-time updates via WebSocket
- [ ] Integration with PomodoroModal component
- [ ] Local storage persistence

### Accessibility Tests
- [ ] Keyboard navigation through all interactive elements
- [ ] Screen reader announcements for dynamic content
- [ ] Focus management during task operations
- [ ] ARIA attributes and semantic markup

### Performance Tests
- [ ] Rendering performance with large task lists (1000+ tasks)
- [ ] Search and filter performance
- [ ] Memory usage during extended use
- [ ] Network request optimization and caching

## Usage Examples

### Basic Usage
```html
<task-list
  projectId="project-123"
  onTaskUpdate="handleTaskUpdate"
  onTaskDelete="handleTaskDelete"
  onTaskCreate="handleTaskCreate"
  onPomodoroStart="handlePomodoroStart">
</task-list>
```

### Advanced Usage with Filters
```html
<task-list
  projectId="project-123"
  filter="in_progress"
  sortBy="priority"
  sortOrder="desc"
  viewMode="grid"
  showCompleted="false"
  onTaskUpdate="handleTaskUpdate"
  onTaskDelete="handleTaskDelete"
  onTaskCreate="handleTaskCreate"
  onPomodoroStart="handlePomodoroStart">
</task-list>
```

### Mobile Optimized Usage
```html
<task-list
  projectId="project-123"
  viewMode="compact"
  selectedTaskIds="[]"
  onTaskUpdate="handleTaskUpdate"
  onTaskDelete="handleTaskDelete"
  onTaskCreate="handleTaskCreate"
  onPomodoroStart="handlePomodoroStart">
</task-list>
```

This TaskList component serves as the central hub for task management within the project-first architecture, providing comprehensive functionality while maintaining excellent performance and accessibility standards.