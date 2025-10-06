# Backend Integration Mapping

**Document Type**: Backend Integration Specification
**Target Environment**: Go API + Frontend Components
**API Version**: v1
**Last Updated**: 2025-10-06

## Overview

This document maps the existing Go backend API endpoints to frontend UI components, establishing clear integration points for the project-first UI architecture. It provides comprehensive mapping between backend services and frontend components, including data flow, error handling, and synchronization patterns.

## Backend Architecture Overview

### Current Backend Structure
```
backend/
├── cmd/
│   └── main_mock.go                 # Mock API server (Port 8083)
├── internal/
│   ├── models/                      # Data models
│   │   ├── user.go                 # User authentication model
│   │   ├── project.go              # Project management model
│   │   ├── task.go                 # Task model with pomodoro tracking
│   │   ├── session.go              # Pomodoro session model
│   │   ├── note.go                 # Task notes model
│   │   └── settings.go             # User settings model
│   ├── services/                    # Business logic
│   │   ├── auth.go                 # JWT authentication service
│   │   ├── task.go                 # Task management service
│   │   ├── project.go              # Project service
│   │   ├── session.go              # Pomodoro session service
│   │   └── user.go                 # User management service
│   ├── handlers/                    # HTTP handlers
│   │   ├── auth.go                 # Authentication endpoints
│   │   ├── task.go                 # Task CRUD endpoints
│   │   ├── project.go              # Project endpoints
│   │   └── session.go              # Session endpoints
│   └── middleware/                  # HTTP middleware
│       ├── cors.go                 # CORS handling
│       ├── auth.go                 # JWT validation
│       ├── rate_limit.go           # Rate limiting
│       └── error.go                # Error handling
└── go.mod                          # Go dependencies
```

### Mock API Status (Port 8083)
- ✅ **Running**: Mock endpoints for frontend development
- ✅ **CORS Enabled**: Cross-origin requests from frontend
- ✅ **JSON Responses**: RESTful API with consistent data format
- 🚧 **Database**: PostgreSQL configured but not connected (mock data used)

## API Endpoint Mapping

### 1. Authentication Endpoints

#### POST /api/auth/login
**Frontend Components**: LoginForm, AuthenticationModal
```javascript
// Frontend Usage
const loginResponse = await AuthService.login({
  email: 'user@example.com',
  password: 'password123'
});

// Expected Response
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user-123",
      "email": "user@example.com",
      "name": "John Doe",
      "avatar_url": null,
      "created_at": "2025-01-01T00:00:00Z"
    },
    "expires_at": "2025-01-02T00:00:00Z"
  }
}
```

**Integration Points**:
- **LoginForm**: Submit credentials, handle validation errors
- **AuthStore**: Store JWT token and user data
- **ProjectSidebar**: Show user information and avatar
- **Router**: Redirect to dashboard on success

#### POST /api/auth/logout
**Frontend Components**: UserMenu, NavigationActions
```javascript
// Frontend Usage
await AuthService.logout();
// Clear local storage, redirect to login
```

#### GET /api/auth/me
**Frontend Components**: AppInitialization, UserProfile
```javascript
// Frontend Usage - validate stored token
const currentUser = await AuthService.getCurrentUser();
```

### 2. Project Management Endpoints

#### GET /api/projects
**Frontend Components**: ProjectSidebar, ProjectList, ProjectDropdown
```javascript
// Frontend Usage
const projects = await ProjectService.getAllProjects();

// Expected Response
{
  "success": true,
  "data": [
    {
      "id": "project-123",
      "name": "Work Project",
      "description": "Professional work tasks",
      "color": "#3B82F6",
      "icon": "💼",
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-06T10:00:00Z",
      "task_count": 15,
      "completed_tasks": 8,
      "total_pomodoros": 24,
      "completion_percentage": 53
    }
  ]
}
```

**Integration Points**:
- **ProjectSidebar**: Display project list with progress bars
- **ProjectList**: Full project management interface
- **DailyStats**: Aggregate statistics across projects
- **ProjectHeader**: Current project context display

#### POST /api/projects
**Frontend Components**: ProjectCreationModal, QuickAddProject
```javascript
// Frontend Usage
const newProject = await ProjectService.createProject({
  name: "New Project",
  description: "Project description",
  color: "#10B981",
  icon: "📚"
});
```

#### GET /api/projects/:id
**Frontend Components**: ProjectHeader, ProjectDetails, TaskList
```javascript
// Frontend Usage - detailed project data with tasks
const projectDetails = await ProjectService.getProject(projectId);

// Expected Response
{
  "success": true,
  "data": {
    "id": "project-123",
    "name": "Work Project",
    "description": "Professional work tasks",
    "color": "#3B82F6",
    "icon": "💼",
    "tasks": [
      {
        "id": "task-456",
        "title": "Complete project architecture",
        "description": "Design and implement project structure",
        "status": "in_progress",
        "priority": "high",
        "due_date": "2025-01-15T00:00:00Z",
        "estimated_pomodoros": 5,
        "completed_pomodoros": 2,
        "created_at": "2025-01-01T00:00:00Z"
      }
    ],
    "stats": {
      "total_tasks": 15,
      "completed_tasks": 8,
      "in_progress_tasks": 5,
      "pending_tasks": 2,
      "total_pomodoros": 24,
      "completion_percentage": 53
    }
  }
}
```

**Integration Points**:
- **ProjectHeader**: Project metadata and statistics
- **TaskList**: Display project tasks with filtering
- **ProjectStats**: Real-time project progress
- **TaskCreation**: Create tasks within project context

#### PUT /api/projects/:id
**Frontend Components**: ProjectEditModal, ProjectSettings
```javascript
// Frontend Usage
const updatedProject = await ProjectService.updateProject(projectId, {
  name: "Updated Project Name",
  description: "New description",
  color: "#8B5CF6"
});
```

#### DELETE /api/projects/:id
**Frontend Components**: ProjectActions, DeleteConfirmation
```javascript
// Frontend Usage
await ProjectService.deleteProject(projectId);
// Update UI to remove project from lists
```

### 3. Task Management Endpoints

#### GET /api/projects/:projectId/tasks
**Frontend Components**: TaskList, TaskFilters, SearchInterface
```javascript
// Frontend Usage with filtering and pagination
const tasks = await TaskService.getTasks(projectId, {
  status: 'in_progress',
  priority: 'high',
  page: 1,
  limit: 20,
  search: 'architecture'
});

// Expected Response
{
  "success": true,
  "data": {
    "tasks": [
      {
        "id": "task-456",
        "title": "Complete project architecture",
        "description": "Design and implement project structure",
        "status": "in_progress",
        "priority": "high",
        "due_date": "2025-01-15T00:00:00Z",
        "estimated_pomodoros": 5,
        "completed_pomodoros": 2,
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-06T10:30:00Z",
        "tags": ["architecture", "planning"],
        "subtasks": [
          {
            "id": "subtask-789",
            "title": "Create component diagram",
            "completed": false
          }
        ]
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "has_next": true
    }
  }
}
```

**Integration Points**:
- **TaskList**: Display filtered task list with pagination
- **TaskCard**: Individual task display and actions
- **TaskFilters**: Filter controls and search
- **TaskStats**: Task statistics and progress

#### POST /api/projects/:projectId/tasks
**Frontend Components**: TaskCreationModal, QuickAddTask, TaskForm
```javascript
// Frontend Usage
const newTask = await TaskService.createTask(projectId, {
  title: "New task title",
  description: "Task description",
  priority: "medium",
  due_date: "2025-01-20T00:00:00Z",
  estimated_pomodoros: 3,
  tags: ["development", "frontend"]
});
```

#### GET /api/tasks/:id
**Frontend Components**: TaskDetails, TaskModal, TaskEditForm
```javascript
// Frontend Usage - detailed task with full context
const taskDetails = await TaskService.getTask(taskId);
```

#### PUT /api/tasks/:id
**Frontend Components**: TaskEditModal, InlineTaskEdit, TaskStatusUpdate
```javascript
// Frontend Usage
const updatedTask = await TaskService.updateTask(taskId, {
  title: "Updated task title",
  status: "completed",
  completed_pomodoros: 5
});
```

#### DELETE /api/tasks/:id
**Frontend Components**: TaskActions, DeleteConfirmation
```javascript
// Frontend Usage
await TaskService.deleteTask(taskId);
```

### 4. Pomodoro Session Endpoints

#### POST /api/tasks/:taskId/sessions
**Frontend Components**: PomodoroModal, TimerDisplay, SessionStart
```javascript
// Frontend Usage - start new pomodoro session
const session = await SessionService.createSession(taskId, {
  type: "work",
  duration: 1500, // 25 minutes in seconds
  settings: {
    auto_start_break: false,
    break_duration: 300 // 5 minutes
  }
});

// Expected Response
{
  "success": true,
  "data": {
    "id": "session-789",
    "task_id": "task-456",
    "type": "work",
    "duration": 1500,
    "status": "active",
    "started_at": "2025-01-06T10:00:00Z",
    "remaining_time": 1500,
    "sequence_position": 3,
    "break_after": true
  }
}
```

**Integration Points**:
- **PomodoroModal**: Session creation and management
- **TimerDisplay**: Real-time countdown display
- **TaskCard**: Show active session indicator
- **SessionHistory**: Track completed sessions

#### PUT /api/sessions/:id
**Frontend Components**: TimerControls, PauseResumeActions
```javascript
// Frontend Usage - update session (pause/resume/progress)
const updatedSession = await SessionService.updateSession(sessionId, {
  status: "paused",
  remaining_time: 1200,
  paused_at: "2025-01-06T10:05:00Z"
});
```

#### POST /api/sessions/:id/complete
**Frontend Components**: SessionCompletion, BreakPrompt, TaskProgress
```javascript
// Frontend Usage - complete session and update task
const completedSession = await SessionService.completeSession(sessionId, {
  actual_duration: 1500,
  interrupted: false,
  completion_notes: "Focused session, good progress"
});
```

#### GET /api/sessions
**Frontend Components**: SessionHistory, DailyStats, Analytics
```javascript
// Frontend Usage - get session history for statistics
const sessions = await SessionService.getSessions({
  user_id: currentUser.id,
  date_from: "2025-01-01",
  date_to: "2025-01-06",
  task_id: taskId // optional
});
```

### 5. Statistics and Analytics Endpoints

#### GET /api/users/:userId/stats
**Frontend Components**: DailyStats, WeeklyReport, ProductivityDashboard
```javascript
// Frontend Usage - comprehensive user statistics
const userStats = await StatsService.getUserStats(userId, {
  period: "week", // day, week, month, year
  timezone: "America/New_York"
});

// Expected Response
{
  "success": true,
  "data": {
    "period": "week",
    "summary": {
      "total_pomodoros": 28,
      "total_focus_time": 11200, // seconds
      "completed_tasks": 12,
      "average_session_length": 1450,
      "productivity_score": 85
    },
    "daily_breakdown": [
      {
        "date": "2025-01-06",
        "pomodoros": 6,
        "focus_time": 2250,
        "tasks_completed": 3,
        "most_productive_hour": 14
      }
    ],
    "project_breakdown": [
      {
        "project_id": "project-123",
        "project_name": "Work Project",
        "pomodoros": 18,
        "focus_time": 7200,
        "tasks_completed": 8
      }
    ],
    "time_distribution": {
      "0": 0, "1": 0, "2": 0, "3": 0,
      "9": 2, "10": 4, "11": 3, "14": 6, "15": 4
    }
  }
}
```

**Integration Points**:
- **DailyStats**: Today's statistics in sidebar
- **WeeklyChart**: 7-day productivity trend
- **HeatMap**: Time distribution visualization
- **ProjectStats**: Per-project analytics

#### GET /api/projects/:projectId/stats
**Frontend Components**: ProjectHeader, ProjectAnalytics
```javascript
// Frontend Usage - project-specific statistics
const projectStats = await StatsService.getProjectStats(projectId);
```

## Data Flow Patterns

### 1. Real-time Data Updates

#### WebSocket Integration (Future Enhancement)
```javascript
// Planned WebSocket connection for real-time updates
class RealTimeUpdates {
  constructor() {
    this.socket = new WebSocket('ws://localhost:8083/ws');
    this.setupEventHandlers();
  }

  setupEventHandlers() {
    this.socket.onmessage = (event) => {
      const data = JSON.parse(event.data);

      switch (data.type) {
        case 'task_updated':
          TaskStore.updateTask(data.task);
          break;
        case 'session_completed':
          SessionStore.addCompletedSession(data.session);
          StatsStore.refreshStats();
          break;
        case 'project_stats_changed':
          ProjectStore.updateProjectStats(data.project_id, data.stats);
          break;
      }
    };
  }
}
```

### 2. Optimistic Updates

#### Task Status Updates
```javascript
// Frontend implementation for immediate UI feedback
class OptimisticTaskUpdates {
  async updateTaskStatus(taskId, newStatus) {
    // 1. Update UI immediately
    TaskStore.updateTaskOptimistic(taskId, { status: newStatus });

    try {
      // 2. Send API request
      const updatedTask = await TaskService.updateTask(taskId, { status: newStatus });

      // 3. Confirm with server response
      TaskStore.confirmTaskUpdate(taskId, updatedTask);
    } catch (error) {
      // 4. Revert on error
      TaskStore.revertTaskUpdate(taskId);
      ErrorHandler.showUpdateError(error);
    }
  }
}
```

### 3. Caching Strategy

#### API Response Caching
```javascript
class APICache {
  constructor() {
    this.cache = new Map();
    this.ttl = 5 * 60 * 1000; // 5 minutes
  }

  async get(endpoint, params = {}) {
    const cacheKey = this.generateCacheKey(endpoint, params);
    const cached = this.cache.get(cacheKey);

    if (cached && Date.now() - cached.timestamp < this.ttl) {
      return cached.data;
    }

    // Fetch fresh data
    const data = await this.fetchFromAPI(endpoint, params);

    // Cache the response
    this.cache.set(cacheKey, {
      data,
      timestamp: Date.now()
    });

    return data;
  }

  invalidate(pattern) {
    // Invalidate cache entries matching pattern
    for (const [key] of this.cache) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }
}
```

## Error Handling Patterns

### 1. API Error Responses

#### Standard Error Format
```javascript
// Backend error response format
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Task title is required",
    "details": {
      "field": "title",
      "value": "",
      "constraint": "min_length"
    }
  }
}
```

#### Frontend Error Handling
```javascript
class APIErrorHandler {
  static handle(error, context = {}) {
    const { code, message, details } = error.response?.data?.error || {};

    switch (code) {
      case 'VALIDATION_ERROR':
        FormValidator.showFieldError(details.field, message);
        break;

      case 'UNAUTHORIZED':
        AuthService.redirectToLogin();
        break;

      case 'NOT_FOUND':
        Router.showNotFoundPage();
        break;

      case 'RATE_LIMITED':
        NotificationService.show({
          type: 'warning',
          message: 'Too many requests. Please try again later.',
          duration: 5000
        });
        break;

      default:
        NotificationService.show({
          type: 'error',
          message: message || 'An unexpected error occurred',
          duration: 5000
        });
    }
  }
}
```

### 2. Network Failure Handling

#### Offline Mode Support
```javascript
class OfflineHandler {
  constructor() {
    this.isOnline = navigator.onLine;
    this.pendingRequests = [];

    window.addEventListener('online', this.handleOnline.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));
  }

  async makeRequest(endpoint, options) {
    if (!this.isOnline) {
      // Queue request for when online
      return this.queueRequest(endpoint, options);
    }

    try {
      return await APIClient.request(endpoint, options);
    } catch (error) {
      if (this.isNetworkError(error)) {
        return this.queueRequest(endpoint, options);
      }
      throw error;
    }
  }

  handleOnline() {
    this.isOnline = true;
    this.processPendingRequests();
    NotificationService.show({
      type: 'success',
      message: 'Connection restored. Syncing data...'
    });
  }

  handleOffline() {
    this.isOnline = false;
    NotificationService.show({
      type: 'info',
      message: 'Working offline. Changes will sync when connected.'
    });
  }
}
```

## Authentication Integration

### JWT Token Management
```javascript
class AuthTokenManager {
  constructor() {
    this.token = localStorage.getItem('auth_token');
    this.refreshToken = localStorage.getItem('refresh_token');
  }

  setTokens(token, refreshToken) {
    this.token = token;
    this.refreshToken = refreshToken;
    localStorage.setItem('auth_token', token);
    localStorage.setItem('refresh_token', refreshToken);

    // Set default authorization header
    APIClient.setDefaultHeader('Authorization', `Bearer ${token}`);
  }

  async refreshTokenIfNeeded() {
    if (!this.token || this.isTokenExpiringSoon()) {
      try {
        const response = await APIClient.post('/api/auth/refresh', {
          refresh_token: this.refreshToken
        });

        this.setTokens(response.data.token, response.data.refresh_token);
      } catch (error) {
        // Refresh failed, redirect to login
        this.clearTokens();
        Router.redirectToLogin();
      }
    }
  }

  isTokenExpiringSoon() {
    if (!this.token) return true;

    try {
      const payload = JSON.parse(atob(this.token.split('.')[1]));
      const expiresAt = payload.exp * 1000;
      const fiveMinutesFromNow = Date.now() + (5 * 60 * 1000);

      return expiresAt < fiveMinutesFromNow;
    } catch {
      return true;
    }
  }
}
```

## Performance Optimization

### 1. Request Batching
```javascript
class RequestBatcher {
  constructor() {
    this.batches = new Map();
    this.batchTimeout = 50; // ms
  }

  async batchRequest(endpoint, data) {
    const batchKey = endpoint;

    if (!this.batches.has(batchKey)) {
      this.batches.set(batchKey, {
        requests: [],
        timeout: setTimeout(() => this.executeBatch(batchKey), this.batchTimeout)
      });
    }

    const batch = this.batches.get(batchKey);

    return new Promise((resolve, reject) => {
      batch.requests.push({ data, resolve, reject });
    });
  }

  async executeBatch(batchKey) {
    const batch = this.batches.get(batchKey);
    this.batches.delete(batchKey);

    try {
      const response = await APIClient.post(`${batchKey}/batch`, {
        requests: batch.requests.map(r => r.data)
      });

      // Resolve individual requests
      response.data.forEach((result, index) => {
        batch.requests[index].resolve(result);
      });
    } catch (error) {
      // Reject all requests in batch
      batch.requests.forEach(request => {
        request.reject(error);
      });
    }
  }
}
```

### 2. Lazy Loading
```javascript
class LazyDataLoader {
  static async loadProjectTasks(projectId, options = {}) {
    const {
      immediate = 10,  // Load first 10 tasks immediately
      total = 100      // Load up to 100 tasks total
    } = options;

    // Load initial tasks immediately
    const initialTasks = await TaskService.getTasks(projectId, {
      limit: immediate,
      page: 1
    });

    // Load remaining tasks in background
    if (initialTasks.pagination.has_next) {
      setTimeout(() => {
        this.loadRemainingTasks(projectId, immediate, total);
      }, 100);
    }

    return initialTasks;
  }

  static async loadRemainingTasks(projectId, skip, limit) {
    const remainingTasks = await TaskService.getTasks(projectId, {
      limit: limit - skip,
      page: 2
    });

    // Add to task store without triggering UI refresh
    TaskStore.addTasksBackground(remainingTasks.tasks);
  }
}
```

## Testing Integration

### Mock API Testing
```javascript
// Mock API response simulation for testing
class MockAPIServer {
  static setupMocks() {
    // Mock successful project fetch
    jest.spyOn(ProjectService, 'getAllProjects').mockResolvedValue({
      success: true,
      data: [
        {
          id: 'project-123',
          name: 'Test Project',
          task_count: 5,
          completion_percentage: 60
        }
      ]
    });

    // Mock task creation
    jest.spyOn(TaskService, 'createTask').mockResolvedValue({
      success: true,
      data: {
        id: 'task-456',
        title: 'New Test Task',
        status: 'pending'
      }
    });
  }
}
```

### Integration Test Examples
```javascript
describe('Backend Integration', () => {
  beforeEach(() => {
    MockAPIServer.setupMocks();
  });

  test('project switching loads correct data', async () => {
    const component = render(<ProjectSidebar />);

    // Click on project
    fireEvent.click(screen.getByText('Work Project'));

    // Verify API calls
    expect(ProjectService.getProject).toHaveBeenCalledWith('project-123');
    expect(TaskService.getTasks).toHaveBeenCalledWith('project-123');

    // Verify UI updates
    await waitFor(() => {
      expect(screen.getByText('15 tasks')).toBeInTheDocument();
    });
  });

  test('pomodoro session creation works correctly', async () => {
    const component = render(<TaskCard taskId="task-456" />);

    // Start pomodoro
    fireEvent.click(screen.getByText('🍅 Start'));

    // Verify session creation
    expect(SessionService.createSession).toHaveBeenCalledWith('task-456', {
      type: 'work',
      duration: 1500
    });
  });
});
```

This comprehensive backend integration mapping ensures seamless communication between the Go API and frontend components while maintaining data consistency, error handling, and optimal performance throughout the application.