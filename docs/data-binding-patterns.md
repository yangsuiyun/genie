# Data Binding Patterns

**Document Type**: Data Flow Specification
**Frontend Architecture**: Component-based with State Management
**Backend Integration**: RESTful API with Real-time Updates
**Last Updated**: 2025-10-06

## Overview

This document defines the data binding patterns and component data flow for the project-first UI architecture. It establishes standardized patterns for data synchronization between frontend components and backend services, including loading states, error handling, and real-time updates.

## Data Flow Architecture

### State Management Hierarchy
```
Application State (Global)
├── AuthState
│   ├── currentUser: User | null
│   ├── token: string | null
│   └── isAuthenticated: boolean
├── ProjectState
│   ├── projects: Project[]
│   ├── currentProject: Project | null
│   └── projectStats: Map<projectId, Stats>
├── TaskState
│   ├── tasksByProject: Map<projectId, Task[]>
│   ├── currentTask: Task | null
│   └── taskFilters: FilterState
├── SessionState
│   ├── activeSession: Session | null
│   ├── sessionHistory: Session[]
│   └── timerState: TimerState
└── UIState
    ├── sidebarCollapsed: boolean
    ├── activeModal: string | null
    └── loadingStates: Map<string, boolean>
```

### Component Data Binding Model
```javascript
// Base component data binding interface
interface ComponentDataBinding {
  // Data sources
  dataSource: DataSource;
  dependencies: string[];

  // Update patterns
  updateStrategy: 'immediate' | 'debounced' | 'batched';
  refreshInterval?: number;

  // Loading states
  loadingStates: LoadingStateMap;
  errorHandling: ErrorHandlingConfig;

  // Synchronization
  syncStrategy: 'optimistic' | 'pessimistic' | 'eventual';
  conflictResolution: ConflictResolutionStrategy;
}
```

## Component Data Binding Patterns

### 1. ProjectSidebar Component

#### Data Dependencies
```javascript
class ProjectSidebarBinding {
  static dependencies = [
    'projects',           // All user projects
    'currentProject',     // Active project context
    'dailyStats',        // Today's productivity stats
    'userSettings'       // Sidebar display preferences
  ];

  static dataFlow = {
    // Primary data binding
    projects: {
      source: 'ProjectStore.projects',
      updateStrategy: 'immediate',
      loadingState: 'projects_loading',
      errorState: 'projects_error'
    },

    // Current project highlighting
    currentProject: {
      source: 'ProjectStore.currentProject',
      updateStrategy: 'immediate',
      dependencies: ['projects'],
      transform: (project, projects) => {
        // Ensure current project exists in projects list
        return projects.find(p => p.id === project?.id) || null;
      }
    },

    // Real-time statistics
    dailyStats: {
      source: 'StatsStore.dailyStats',
      updateStrategy: 'debounced',
      debounceMs: 500,
      refreshInterval: 60000, // 1 minute
      fallback: () => StatsStore.getDefaultStats()
    }
  };

  // Component data synchronization
  static async initializeData() {
    try {
      // Load projects with loading state
      UIStore.setLoading('projects_loading', true);

      const projects = await ProjectService.getAllProjects();
      ProjectStore.setProjects(projects);

      // Load current project if stored
      const savedProjectId = LocalStorage.getCurrentProjectId();
      if (savedProjectId) {
        const currentProject = projects.find(p => p.id === savedProjectId);
        if (currentProject) {
          ProjectStore.setCurrentProject(currentProject);
        }
      }

      // Load daily statistics
      const stats = await StatsService.getDailyStats();
      StatsStore.setDailyStats(stats);

    } catch (error) {
      ErrorHandler.handleDataLoadError('projects', error);
    } finally {
      UIStore.setLoading('projects_loading', false);
    }
  }

  // Real-time update handling
  static onProjectUpdate(updatedProject) {
    ProjectStore.updateProject(updatedProject);

    // Update current project if it's the one that changed
    if (ProjectStore.currentProject?.id === updatedProject.id) {
      ProjectStore.setCurrentProject(updatedProject);
    }
  }
}
```

#### Reactive Data Binding
```javascript
// React hook for sidebar data binding
function useProjectSidebarData() {
  const projects = useSelector(state => state.projects.projects);
  const currentProject = useSelector(state => state.projects.currentProject);
  const dailyStats = useSelector(state => state.stats.dailyStats);
  const isLoading = useSelector(state => state.ui.loadingStates.projects_loading);

  // Subscribe to real-time updates
  useEffect(() => {
    const unsubscribe = RealtimeService.subscribe('projects', {
      onUpdate: ProjectSidebarBinding.onProjectUpdate,
      onStatsUpdate: (stats) => StatsStore.setDailyStats(stats)
    });

    return unsubscribe;
  }, []);

  // Memoized computed data
  const sidebarData = useMemo(() => ({
    projects: projects.map(project => ({
      ...project,
      isActive: project.id === currentProject?.id,
      progressPercentage: Math.round((project.completed_tasks / project.total_tasks) * 100) || 0
    })),
    currentProject,
    dailyStats,
    isLoading
  }), [projects, currentProject, dailyStats, isLoading]);

  return sidebarData;
}
```

### 2. TaskList Component

#### Data Binding Configuration
```javascript
class TaskListBinding {
  static dependencies = [
    'tasks',              // Project tasks
    'currentProject',     // Project context
    'taskFilters',       // Active filters
    'activeSession'      // Current pomodoro session
  ];

  static dataFlow = {
    // Task data with filtering
    tasks: {
      source: 'TaskStore.getTasksForProject',
      parameters: ['currentProject.id', 'taskFilters'],
      updateStrategy: 'immediate',
      pagination: {
        enabled: true,
        pageSize: 20,
        loadMore: 'scroll'
      },
      sorting: {
        default: [['priority', 'desc'], ['created_at', 'desc']],
        options: ['priority', 'due_date', 'title', 'status']
      }
    },

    // Filter state binding
    taskFilters: {
      source: 'TaskStore.filters',
      updateStrategy: 'debounced',
      debounceMs: 300,
      persistence: 'localStorage',
      key: 'task_filters'
    },

    // Active session awareness
    activeSession: {
      source: 'SessionStore.activeSession',
      updateStrategy: 'immediate',
      transform: (session) => ({
        taskId: session?.task_id,
        isActive: !!session,
        timeRemaining: session?.remaining_time
      })
    }
  };

  // Optimistic task updates
  static async updateTask(taskId, updates) {
    // 1. Update UI immediately (optimistic)
    TaskStore.updateTaskOptimistic(taskId, updates);

    try {
      // 2. Send to backend
      const updatedTask = await TaskService.updateTask(taskId, updates);

      // 3. Confirm with server response
      TaskStore.confirmTaskUpdate(taskId, updatedTask);

      // 4. Update related data
      if (updates.status === 'completed') {
        await this.refreshProjectStats();
      }

    } catch (error) {
      // 5. Revert optimistic update
      TaskStore.revertTaskUpdate(taskId);
      ErrorHandler.showTaskUpdateError(error);
    }
  }

  // Batch operations for performance
  static async updateMultipleTasks(taskUpdates) {
    const batchId = generateBatchId();

    try {
      // Optimistic updates
      taskUpdates.forEach(({ taskId, updates }) => {
        TaskStore.updateTaskOptimistic(taskId, updates, batchId);
      });

      // Batch API call
      const results = await TaskService.batchUpdate(taskUpdates);

      // Confirm all updates
      results.forEach((result, index) => {
        TaskStore.confirmTaskUpdate(taskUpdates[index].taskId, result);
      });

    } catch (error) {
      // Revert entire batch
      TaskStore.revertBatch(batchId);
      ErrorHandler.showBatchUpdateError(error);
    }
  }
}
```

#### Task Data Virtualization
```javascript
// Virtual scrolling for large task lists
function useVirtualizedTasks(projectId, filters) {
  const [virtualizedData, setVirtualizedData] = useState({
    visibleTasks: [],
    totalCount: 0,
    loadedRanges: []
  });

  const [scrollPosition, setScrollPosition] = useState(0);
  const itemHeight = 120; // pixels per task card
  const viewportHeight = 800; // visible area height
  const bufferSize = 5; // extra items to render

  // Calculate visible range
  const visibleRange = useMemo(() => {
    const startIndex = Math.floor(scrollPosition / itemHeight);
    const endIndex = Math.ceil((scrollPosition + viewportHeight) / itemHeight);

    return {
      start: Math.max(0, startIndex - bufferSize),
      end: Math.min(virtualizedData.totalCount, endIndex + bufferSize)
    };
  }, [scrollPosition, virtualizedData.totalCount]);

  // Load data for visible range
  useEffect(() => {
    const loadVisibleTasks = async () => {
      const { start, end } = visibleRange;

      // Check if range is already loaded
      const isRangeLoaded = virtualizedData.loadedRanges.some(range =>
        range.start <= start && range.end >= end
      );

      if (!isRangeLoaded) {
        const tasks = await TaskService.getTasks(projectId, {
          ...filters,
          offset: start,
          limit: end - start
        });

        setVirtualizedData(prev => ({
          ...prev,
          visibleTasks: mergeTasks(prev.visibleTasks, tasks.data, start),
          totalCount: tasks.total,
          loadedRanges: [...prev.loadedRanges, { start, end }]
        }));
      }
    };

    loadVisibleTasks();
  }, [visibleRange, projectId, filters]);

  return {
    visibleTasks: virtualizedData.visibleTasks,
    totalCount: virtualizedData.totalCount,
    onScroll: setScrollPosition,
    itemHeight,
    totalHeight: virtualizedData.totalCount * itemHeight
  };
}
```

### 3. PomodoroModal Component

#### Session Data Binding
```javascript
class PomodoroModalBinding {
  static dependencies = [
    'activeSession',      // Current session data
    'currentTask',       // Associated task
    'timerState',        // Timer countdown state
    'userSettings'       // Timer preferences
  ];

  static dataFlow = {
    // Active session binding
    activeSession: {
      source: 'SessionStore.activeSession',
      updateStrategy: 'immediate',
      required: true,
      onError: () => ModalService.close('pomodoro')
    },

    // Real-time timer updates
    timerState: {
      source: 'TimerWorker.state',
      updateStrategy: 'immediate',
      frequency: 1000, // 1 second updates
      transform: (state) => ({
        timeRemaining: state.remaining,
        isRunning: state.status === 'running',
        isPaused: state.status === 'paused',
        progress: (state.duration - state.remaining) / state.duration
      })
    },

    // Task context
    currentTask: {
      source: 'TaskStore.getTask',
      parameters: ['activeSession.task_id'],
      updateStrategy: 'immediate',
      cache: true
    }
  };

  // Timer control methods
  static async startTimer(sessionId) {
    try {
      // Update UI immediately
      SessionStore.updateSessionState(sessionId, 'running');

      // Start backend session
      const session = await SessionService.startSession(sessionId);

      // Start timer worker
      TimerWorker.start({
        sessionId: session.id,
        duration: session.remaining_time,
        onTick: this.onTimerTick,
        onComplete: this.onTimerComplete
      });

    } catch (error) {
      SessionStore.revertSessionState(sessionId);
      ErrorHandler.showTimerError(error);
    }
  }

  static onTimerTick = (remaining) => {
    // Update local state
    TimerStore.setRemainingTime(remaining);

    // Periodic backend sync (every 30 seconds)
    if (remaining % 30 === 0) {
      SessionService.updateProgress(
        SessionStore.activeSession.id,
        remaining
      ).catch(error => {
        console.warn('Progress sync failed:', error);
      });
    }
  };

  static onTimerComplete = async () => {
    const session = SessionStore.activeSession;

    try {
      // Complete session on backend
      const completedSession = await SessionService.completeSession(session.id);

      // Update task progress
      TaskStore.incrementPomodoroCount(session.task_id);

      // Update local state
      SessionStore.setActiveSession(null);
      SessionStore.addCompletedSession(completedSession);

      // Show completion notification
      NotificationService.showPomodoroComplete(completedSession);

      // Determine next action (break/continue)
      this.showCompletionActions(completedSession);

    } catch (error) {
      ErrorHandler.showSessionCompleteError(error);
    }
  };
}
```

### 4. Real-time Data Synchronization

#### WebSocket Integration Pattern
```javascript
class RealtimeDataSync {
  constructor() {
    this.socket = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.subscriptions = new Map();
  }

  connect() {
    const token = AuthStore.getToken();
    this.socket = new WebSocket(`ws://localhost:8083/ws?token=${token}`);

    this.socket.onopen = this.onConnect.bind(this);
    this.socket.onmessage = this.onMessage.bind(this);
    this.socket.onclose = this.onDisconnect.bind(this);
    this.socket.onerror = this.onError.bind(this);
  }

  onMessage(event) {
    const message = JSON.parse(event.data);

    switch (message.type) {
      case 'task_updated':
        this.handleTaskUpdate(message.data);
        break;

      case 'project_updated':
        this.handleProjectUpdate(message.data);
        break;

      case 'session_completed':
        this.handleSessionComplete(message.data);
        break;

      case 'stats_updated':
        this.handleStatsUpdate(message.data);
        break;
    }
  }

  handleTaskUpdate(taskData) {
    // Update task in store
    TaskStore.updateTaskFromServer(taskData);

    // Notify subscribers
    this.notifySubscribers('task_updated', taskData);

    // Update UI if task is currently visible
    if (UIStore.isTaskVisible(taskData.id)) {
      UIStore.refreshTaskDisplay(taskData.id);
    }
  }

  // Subscribe to specific data updates
  subscribe(dataType, callback) {
    if (!this.subscriptions.has(dataType)) {
      this.subscriptions.set(dataType, new Set());
    }

    this.subscriptions.get(dataType).add(callback);

    // Return unsubscribe function
    return () => {
      this.subscriptions.get(dataType)?.delete(callback);
    };
  }

  notifySubscribers(dataType, data) {
    const callbacks = this.subscriptions.get(dataType);
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error('Subscription callback error:', error);
        }
      });
    }
  }
}
```

### 5. Offline Data Handling

#### Offline Queue Pattern
```javascript
class OfflineDataQueue {
  constructor() {
    this.queue = [];
    this.isOnline = navigator.onLine;
    this.storage = new OfflineStorage();

    window.addEventListener('online', this.processQueue.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));

    // Load persisted queue on init
    this.loadPersistedQueue();
  }

  // Queue data operations when offline
  queueOperation(operation) {
    const queueItem = {
      id: generateUniqueId(),
      timestamp: Date.now(),
      operation,
      attempts: 0,
      maxAttempts: 3
    };

    this.queue.push(queueItem);
    this.persistQueue();

    // Try to process immediately if online
    if (this.isOnline) {
      this.processQueue();
    }

    return queueItem.id;
  }

  async processQueue() {
    if (!this.isOnline || this.queue.length === 0) return;

    const processing = [...this.queue];
    this.queue = [];

    for (const item of processing) {
      try {
        await this.executeOperation(item.operation);

        // Operation succeeded, remove from queue
        NotificationService.showSyncSuccess(item.operation);

      } catch (error) {
        item.attempts++;

        if (item.attempts < item.maxAttempts) {
          // Retry later
          this.queue.push(item);
        } else {
          // Max attempts reached, show error
          NotificationService.showSyncError(item.operation, error);
        }
      }
    }

    this.persistQueue();
  }

  async executeOperation(operation) {
    switch (operation.type) {
      case 'create_task':
        return await TaskService.createTask(operation.projectId, operation.data);

      case 'update_task':
        return await TaskService.updateTask(operation.taskId, operation.data);

      case 'complete_session':
        return await SessionService.completeSession(operation.sessionId, operation.data);

      default:
        throw new Error(`Unknown operation type: ${operation.type}`);
    }
  }

  // Offline data storage
  saveOfflineData(key, data) {
    this.storage.set(key, {
      data,
      timestamp: Date.now(),
      isOffline: true
    });
  }

  getOfflineData(key) {
    const stored = this.storage.get(key);
    return stored?.isOffline ? stored.data : null;
  }
}
```

### 6. Error Recovery Patterns

#### Automatic Error Recovery
```javascript
class DataErrorRecovery {
  static strategies = {
    'network_error': 'retry_with_backoff',
    'validation_error': 'show_user_error',
    'auth_error': 'refresh_token_and_retry',
    'conflict_error': 'merge_or_prompt_user'
  };

  static async handleDataError(error, context) {
    const strategy = this.strategies[error.type] || 'show_generic_error';

    switch (strategy) {
      case 'retry_with_backoff':
        return this.retryWithBackoff(context.operation, error);

      case 'refresh_token_and_retry':
        return this.refreshTokenAndRetry(context.operation, error);

      case 'merge_or_prompt_user':
        return this.handleDataConflict(context.data, error);

      default:
        return this.showGenericError(error);
    }
  }

  static async retryWithBackoff(operation, error, attempt = 1) {
    const maxAttempts = 3;
    const baseDelay = 1000; // 1 second

    if (attempt > maxAttempts) {
      throw new Error(`Operation failed after ${maxAttempts} attempts: ${error.message}`);
    }

    // Exponential backoff
    const delay = baseDelay * Math.pow(2, attempt - 1);
    await new Promise(resolve => setTimeout(resolve, delay));

    try {
      return await operation();
    } catch (retryError) {
      return this.retryWithBackoff(operation, retryError, attempt + 1);
    }
  }

  static async handleDataConflict(localData, serverError) {
    const serverData = serverError.conflictData;

    // Attempt automatic merge
    const mergeResult = this.attemptAutoMerge(localData, serverData);

    if (mergeResult.success) {
      return mergeResult.data;
    }

    // Show conflict resolution UI
    return new Promise((resolve) => {
      ConflictResolutionModal.show({
        localData,
        serverData,
        onResolve: resolve
      });
    });
  }

  static attemptAutoMerge(local, server) {
    // Simple merge strategy for common cases
    if (local.updated_at > server.updated_at) {
      // Local is newer, use local data
      return { success: true, data: local };
    }

    // Try to merge non-conflicting fields
    const merged = { ...server };

    Object.keys(local).forEach(key => {
      if (key !== 'updated_at' && key !== 'version') {
        if (local[key] !== server[key]) {
          // Conflict detected, cannot auto-merge
          return { success: false };
        }
      }
    });

    return { success: true, data: merged };
  }
}
```

## Performance Optimization Patterns

### 1. Data Memoization
```javascript
class DataMemoization {
  static cache = new Map();
  static ttl = 5 * 60 * 1000; // 5 minutes

  static memoize(key, fetchFunction, options = {}) {
    const { ttl = this.ttl, dependencies = [] } = options;

    return async (...args) => {
      const cacheKey = this.generateCacheKey(key, args, dependencies);
      const cached = this.cache.get(cacheKey);

      if (cached && Date.now() - cached.timestamp < ttl) {
        return cached.data;
      }

      const data = await fetchFunction(...args);

      this.cache.set(cacheKey, {
        data,
        timestamp: Date.now()
      });

      return data;
    };
  }

  // Invalidate cache when dependencies change
  static invalidateByPrefix(prefix) {
    for (const [key] of this.cache) {
      if (key.startsWith(prefix)) {
        this.cache.delete(key);
      }
    }
  }
}

// Usage example
const memoizedGetTasks = DataMemoization.memoize(
  'getTasks',
  TaskService.getTasks,
  { dependencies: ['project', 'filters'] }
);
```

### 2. Intelligent Prefetching
```javascript
class DataPrefetcher {
  static prefetchRules = [
    {
      trigger: 'project_selected',
      prefetch: ['project_tasks', 'project_stats'],
      condition: (projectId) => !ProjectCache.has(projectId)
    },
    {
      trigger: 'task_hovered',
      prefetch: ['task_details'],
      delay: 500,
      condition: (taskId) => !TaskCache.has(taskId)
    }
  ];

  static onTrigger(eventType, data) {
    const rules = this.prefetchRules.filter(rule => rule.trigger === eventType);

    rules.forEach(rule => {
      if (!rule.condition || rule.condition(data)) {
        const prefetchFn = () => this.executePrefetch(rule.prefetch, data);

        if (rule.delay) {
          setTimeout(prefetchFn, rule.delay);
        } else {
          prefetchFn();
        }
      }
    });
  }

  static async executePrefetch(dataTypes, context) {
    const promises = dataTypes.map(type => {
      switch (type) {
        case 'project_tasks':
          return TaskService.getTasks(context.projectId);
        case 'project_stats':
          return StatsService.getProjectStats(context.projectId);
        case 'task_details':
          return TaskService.getTask(context.taskId);
        default:
          return Promise.resolve();
      }
    });

    try {
      await Promise.all(promises);
    } catch (error) {
      // Prefetch errors should not affect user experience
      console.debug('Prefetch error:', error);
    }
  }
}
```

This comprehensive data binding pattern specification ensures efficient, reliable, and maintainable data flow between frontend components and backend services while providing excellent user experience through optimistic updates, error recovery, and performance optimization.