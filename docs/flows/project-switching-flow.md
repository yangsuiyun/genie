# Project Switching Flow

**Flow Type**: Navigation interaction
**Complexity Level**: moderate
**Dependencies**: ProjectSidebar, ProjectList, TaskList, DailyStats
**Estimated Completion Time**: 2-3 seconds per switch

## Flow Metadata

- **flow_name**: ProjectSwitchingFlow
- **flow_type**: navigation_interaction
- **complexity_level**: moderate
- **user_roles**: [authenticated_users]
- **estimated_completion_time**: 2-3 seconds per switch

## Purpose

This flow documents the user interaction for switching between different projects in the project-first UI architecture. It ensures seamless transitions while maintaining context, preserving user state, and providing clear visual feedback throughout the switching process.

## Flow Overview

```
CURRENT STATE: User viewing Project A
↓
[PROJECT SELECTION] → [DATA LOADING] → [UI TRANSITION] → [NEW STATE]
↓
NEW STATE: User viewing Project B with full context
```

## Trigger Conditions

### Primary Triggers
- **Sidebar Click**: User clicks on project item in left sidebar
- **Project Dropdown**: User selects project from header dropdown (mobile)
- **Keyboard Navigation**: User uses keyboard shortcuts (Ctrl+1-9 for project slots)
- **Quick Switcher**: User types project name in quick switcher (Ctrl+P)

### Entry Points
- **Desktop Sidebar**: Direct project list in left navigation
- **Mobile Hamburger**: Project list in slide-out menu
- **Header Context**: Current project dropdown in top bar
- **Search Interface**: Global search results with project filters

### Prerequisites
- **Authentication**: User must be logged in with project access
- **Project Access**: User must have read permission for target project
- **No Active Pomodoro**: Warn if switching during active session
- **Network State**: Handle offline/online project switching gracefully

## Success Path

### Phase 1: Project Selection (0-100ms)

#### Step 1.1: User Initiates Switch
```javascript
// Sidebar project click handler
function onProjectClick(projectId, clickEvent) {
  const currentProject = AppState.getCurrentProject();

  // Prevent unnecessary switches
  if (currentProject?.id === projectId) {
    return; // Already viewing this project
  }

  // Check for active pomodoro session
  const activeSession = SessionService.getActiveSession();
  if (activeSession && activeSession.taskProject !== projectId) {
    showActivePomodoroWarning(projectId, activeSession);
    return;
  }

  // Initiate project switch
  initiateProjectSwitch(projectId, clickEvent);
}
```

#### Step 1.2: Visual Feedback
- **Immediate Response**: Clicked project item highlights with theme color
- **Loading State**: Show subtle loading indicator next to project name
- **Current Project**: Previous project dims to indicate transition
- **Focus Management**: Maintain focus on selected project for accessibility

### Phase 2: Active Session Handling (100-300ms)

#### Step 2.1: Pomodoro Session Conflict
```javascript
function showActivePomodoroWarning(targetProjectId, activeSession) {
  const options = {
    title: "Active Pomodoro Session",
    message: `You have an active session for "${activeSession.task.title}" in ${activeSession.project.name}. What would you like to do?`,
    actions: [
      {
        label: "Continue Session",
        action: () => focusActiveSession(),
        style: "primary",
        description: "Stay in current project and continue working"
      },
      {
        label: "Pause & Switch",
        action: () => pauseSessionAndSwitch(targetProjectId),
        style: "secondary",
        description: "Pause current session and switch projects"
      },
      {
        label: "Complete Session",
        action: () => showSessionCompleteDialog(targetProjectId),
        style: "success",
        description: "Mark current session as complete"
      },
      {
        label: "Cancel Switch",
        action: () => cancelProjectSwitch(),
        style: "tertiary",
        description: "Stay in current project"
      }
    ]
  };

  DialogService.show(options);
}
```

#### Step 2.2: Session State Management
```javascript
async function pauseSessionAndSwitch(targetProjectId) {
  try {
    // Pause current session
    const activeSession = SessionService.getActiveSession();
    await SessionService.pauseSession(activeSession.id, {
      pausedAt: new Date(),
      pauseReason: 'project_switch'
    });

    // Update UI to show paused state
    PomodoroModal.showPausedState();

    // Proceed with project switch
    await performProjectSwitch(targetProjectId);

    // Show session continuation option in new project
    NotificationService.show({
      type: 'info',
      message: `Paused session for "${activeSession.task.title}" is available to resume`,
      action: () => resumePausedSession()
    });

  } catch (error) {
    handleSwitchError(error);
  }
}
```

### Phase 3: Data Loading (200-800ms)

#### Step 3.1: Project Data Fetching
```javascript
async function performProjectSwitch(targetProjectId) {
  try {
    // Start loading animation
    LoadingService.start('project-switch');

    // Load project data in parallel
    const [project, tasks, stats, settings] = await Promise.all([
      ProjectService.getProject(targetProjectId),
      TaskService.getTasksForProject(targetProjectId),
      StatsService.getProjectStats(targetProjectId),
      SettingsService.getProjectSettings(targetProjectId)
    ]);

    // Validate data integrity
    validateProjectData(project, tasks, stats);

    // Update application state
    await updateApplicationState(project, tasks, stats, settings);

    // Trigger UI transition
    await animateProjectTransition(project);

  } catch (error) {
    handleProjectLoadError(error, targetProjectId);
  } finally {
    LoadingService.complete('project-switch');
  }
}
```

#### Step 3.2: Optimistic Loading Strategy
```javascript
// Cache-first loading with background refresh
async function loadProjectData(projectId) {
  // Get cached data immediately
  const cachedData = CacheService.getProjectData(projectId);

  if (cachedData && cachedData.isValid()) {
    // Show cached data first for instant UI update
    updateUIWithData(cachedData);

    // Then refresh in background
    refreshProjectDataInBackground(projectId);
  } else {
    // No cache available, load fresh data
    const freshData = await fetchProjectDataFromAPI(projectId);
    updateUIWithData(freshData);
    CacheService.setProjectData(projectId, freshData);
  }
}
```

### Phase 4: UI Transition (300-500ms)

#### Step 4.1: Layout Animation
```javascript
async function animateProjectTransition(newProject) {
  const transitionDuration = 300; // ms

  // 1. Fade out current content
  await AnimationService.fadeOut('.main-content', 150);

  // 2. Update sidebar selection
  updateSidebarSelection(newProject.id);

  // 3. Update header context
  updateProjectHeader(newProject);

  // 4. Load new content with skeleton
  loadContentWithSkeleton(newProject);

  // 5. Fade in new content
  await AnimationService.fadeIn('.main-content', 150);

  // 6. Update document title and metadata
  updateDocumentMetadata(newProject);
}
```

#### Step 4.2: Progressive Content Loading
```html
<!-- Skeleton UI during transition -->
<div class="task-list-skeleton">
  <div class="skeleton-header"></div>
  <div class="skeleton-task"></div>
  <div class="skeleton-task"></div>
  <div class="skeleton-task"></div>
</div>

<!-- Real content replaces skeleton -->
<div class="task-list-content">
  <div class="project-header">{{project.name}}</div>
  <div class="task-item" v-for="task in tasks">{{task.title}}</div>
</div>
```

### Phase 5: State Synchronization (400-600ms)

#### Step 5.1: Component Updates
```javascript
// Update all components with new project context
function synchronizeComponentState(projectData) {
  // Update sidebar
  ProjectSidebar.setActiveProject(projectData.project.id);
  ProjectSidebar.updateStats(projectData.stats);

  // Update main content
  TaskList.loadTasks(projectData.tasks);
  ProjectHeader.setProject(projectData.project);

  // Update statistics
  DailyStats.updateProjectStats(projectData.stats);

  // Update URL and browser history
  Router.updateURL(`/projects/${projectData.project.id}`);

  // Update local storage
  LocalStorage.setCurrentProject(projectData.project.id);
}
```

#### Step 5.2: Analytics and Tracking
```javascript
// Track project switch for analytics
AnalyticsService.trackEvent('project_switched', {
  fromProject: previousProject?.id,
  toProject: newProject.id,
  switchMethod: 'sidebar_click', // or 'keyboard', 'dropdown', etc.
  loadTime: Date.now() - switchStartTime,
  tasksLoaded: tasks.length,
  hasActiveTasks: tasks.some(t => t.status === 'in_progress')
});
```

## Error Paths

### Error 1: Project Access Denied
**Trigger**: User lacks permission to access target project
```javascript
{
  error: "PROJECT_ACCESS_DENIED",
  message: "You don't have permission to access this project",
  action: "show_permission_request",
  recovery: () => ProjectAccessService.requestAccess(projectId)
}
```

**Recovery Actions**:
- Show permission request dialog
- Offer to contact project admin
- Return to current project with error notification

### Error 2: Network Failure During Switch
**Trigger**: API calls fail due to network issues
```javascript
{
  error: "PROJECT_LOAD_FAILED",
  message: "Unable to load project data. Using cached version.",
  action: "use_cached_data",
  recovery: () => loadCachedProjectData(projectId)
}
```

**Recovery Actions**:
- Fall back to cached project data
- Show offline mode indicator
- Retry loading when connection restored

### Error 3: Data Integrity Issues
**Trigger**: Loaded project data is corrupted or inconsistent
```javascript
{
  error: "PROJECT_DATA_INVALID",
  message: "Project data appears corrupted. Refreshing...",
  action: "force_refresh",
  recovery: () => forceRefreshProjectData(projectId)
}
```

**Recovery Actions**:
- Clear cache and reload from server
- Show data validation error dialog
- Offer to report the issue

### Error 4: Active Session Conflicts
**Trigger**: Complex session state during project switch
```javascript
{
  error: "SESSION_CONFLICT",
  message: "Session state conflict detected during project switch",
  action: "resolve_session_state",
  recovery: () => SessionConflictResolver.resolve()
}
```

**Recovery Actions**:
- Pause all active sessions
- Show session resolution dialog
- Allow manual session state management

## Performance Requirements

### Response Time Targets
- **Click to Visual Feedback**: < 50ms
- **Data Loading Start**: < 100ms
- **UI Transition**: < 300ms total
- **Complete Load**: < 800ms for typical project
- **Large Project Load**: < 2s for 500+ tasks

### Loading Optimization
```javascript
// Intelligent preloading based on user patterns
class ProjectPreloader {
  static preloadLikelyProjects() {
    const recentProjects = UserBehaviorService.getRecentProjects();
    const frequentProjects = UserBehaviorService.getFrequentProjects();

    // Preload data for likely next projects
    [...recentProjects, ...frequentProjects]
      .slice(0, 3) // Limit preloading
      .forEach(projectId => {
        ProjectService.preloadProject(projectId);
      });
  }
}
```

### Memory Management
- **Cache Limit**: Maximum 5 projects cached simultaneously
- **Cache Strategy**: LRU eviction for oldest unused projects
- **Memory Usage**: < 100MB total for all cached projects
- **Cleanup**: Automatic cleanup of stale cache data

## Accessibility Features

### Keyboard Navigation
```javascript
const keyboardShortcuts = {
  'Ctrl+1-9': 'Switch to project in position 1-9',
  'Ctrl+P': 'Open project quick switcher',
  'Alt+Left': 'Previous project in history',
  'Alt+Right': 'Next project in history',
  'Escape': 'Cancel project switch operation'
};
```

### Screen Reader Support
```html
<!-- Project switch announcements -->
<div aria-live="polite" aria-atomic="true">
  Switching to project: {{projectName}}. Loading {{taskCount}} tasks.
</div>

<!-- Loading state announcements -->
<div aria-live="polite">
  Project data loaded. Now viewing {{projectName}} with {{completedTasks}} completed tasks.
</div>

<!-- Focus management -->
<button aria-label="Switch to {{projectName}} project. {{taskCount}} tasks, {{completedCount}} completed">
  {{projectName}}
</button>
```

### Visual Accessibility
- **High Contrast**: Enhanced project selection indicators
- **Focus Indicators**: Clear focus rings on project items
- **Loading States**: Progress indicators for visually impaired users
- **Color Independence**: Project switching works without color dependence

## Mobile Considerations

### Touch Interactions
```javascript
// Mobile-specific project switching
class MobileProjectSwitcher {
  handleProjectTap(projectId, touchEvent) {
    // Immediate visual feedback
    this.showTouchFeedback(touchEvent.target);

    // Handle double-tap for quick switch
    if (this.isDoubleTap(touchEvent)) {
      this.quickSwitchToProject(projectId);
    } else {
      this.normalSwitchToProject(projectId);
    }
  }

  // Swipe gestures for project navigation
  handleSwipeGesture(direction) {
    if (direction === 'left') {
      this.switchToNextProject();
    } else if (direction === 'right') {
      this.switchToPreviousProject();
    }
  }
}
```

### Mobile UI Adaptations
- **Hamburger Menu**: Project list in slide-out navigation
- **Bottom Sheet**: Project picker as bottom sheet on mobile
- **Gesture Support**: Swipe between projects like tabs
- **Touch Targets**: 44px minimum for project selection items

## Offline Behavior

### Cached Project Switching
```javascript
// Offline project switching
class OfflineProjectSwitcher {
  async switchProject(projectId) {
    if (!NetworkService.isOnline()) {
      return this.switchToLocalProject(projectId);
    }

    try {
      return await this.switchToRemoteProject(projectId);
    } catch (error) {
      // Fall back to local if remote fails
      return this.switchToLocalProject(projectId);
    }
  }

  switchToLocalProject(projectId) {
    const cachedProject = CacheService.getProject(projectId);

    if (!cachedProject) {
      throw new Error('Project not available offline');
    }

    this.updateUIWithCachedData(cachedProject);
    this.showOfflineIndicator();
  }
}
```

### Data Synchronization
- **Sync on Reconnect**: Automatically sync changes when back online
- **Conflict Resolution**: Handle conflicts between local and remote changes
- **Queue Management**: Queue project switches for retry when offline
- **Cache Validation**: Verify cache freshness on network restore

## Integration Points

### API Endpoints
```javascript
// Project switching API calls
const ProjectSwitchingAPI = {
  // Get project with tasks and stats
  getProjectData: (projectId) =>
    GET `/api/projects/${projectId}?include=tasks,stats,settings`,

  // Update user's current project
  setCurrentProject: (projectId) =>
    PUT `/api/users/current-project`, { projectId },

  // Log project switch for analytics
  logProjectSwitch: (switchData) =>
    POST `/api/analytics/project-switch`, switchData,

  // Preload project data
  preloadProject: (projectId) =>
    GET `/api/projects/${projectId}/preload`
};
```

### Component Communication
```javascript
// Event system for project switching
EventBus.on('project:switch:start', (projectId) => {
  LoadingIndicator.show();
  Sidebar.highlightProject(projectId);
});

EventBus.on('project:switch:complete', (projectData) => {
  LoadingIndicator.hide();
  TaskList.updateTasks(projectData.tasks);
  ProjectHeader.updateProject(projectData.project);
  DailyStats.updateStats(projectData.stats);
});

EventBus.on('project:switch:error', (error) => {
  LoadingIndicator.hide();
  ErrorHandler.showProjectSwitchError(error);
  Sidebar.revertToCurrentProject();
});
```

### State Management
```javascript
// Global state updates for project switching
const ProjectSwitchingState = {
  currentProject: null,
  isLoading: false,
  switchHistory: [],
  cachedProjects: new Map(),

  switchToProject: async (projectId) => {
    this.isLoading = true;
    this.addToHistory(this.currentProject?.id);

    try {
      const projectData = await loadProjectData(projectId);
      this.currentProject = projectData.project;
      this.cacheProjectData(projectId, projectData);
    } finally {
      this.isLoading = false;
    }
  }
};
```

## Testing Scenarios

### Happy Path Testing
- ✅ Switch between projects using sidebar navigation
- ✅ Verify all project data loads correctly
- ✅ Confirm UI updates reflect new project context
- ✅ Test keyboard shortcuts for project switching

### Error Path Testing
- ✅ Handle network failure during project switch
- ✅ Test access denied scenarios
- ✅ Verify graceful degradation with cached data
- ✅ Test active session conflict resolution

### Performance Testing
- ✅ Measure switch time with various project sizes
- ✅ Test memory usage with multiple cached projects
- ✅ Verify smooth animations during transitions
- ✅ Test preloading effectiveness

### Accessibility Testing
- ✅ Complete project switch using only keyboard
- ✅ Test with screen reader for proper announcements
- ✅ Verify focus management during modal operations
- ✅ Test high contrast mode support

## Success Metrics

### User Experience Metrics
- **Switch Completion Rate**: >95% successful project switches
- **Switch Speed**: <800ms average for typical project
- **Error Recovery Rate**: >90% successful error recovery
- **User Satisfaction**: Positive feedback on switching speed

### Technical Performance Metrics
- **API Response Time**: <400ms for project data loading
- **UI Transition Time**: <300ms for visual transitions
- **Cache Hit Rate**: >80% for recently accessed projects
- **Memory Efficiency**: <100MB for project data cache

This project switching flow ensures seamless navigation between projects while maintaining performance, accessibility, and data integrity throughout the user experience.