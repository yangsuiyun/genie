# Migration Checklist: Task-First to Project-First UI

**Migration Type**: UI Architecture Transformation
**Source**: Task-centric bottom navigation web app
**Target**: Project-first sidebar navigation architecture
**Estimated Migration Time**: 8-12 hours

## Overview

This checklist guides the migration from the current task-first UI architecture (implemented in `mobile/build/web/index.html`) to the new project-first UI design. The migration involves restructuring navigation, reorganizing components, and updating data flows while preserving all existing functionality.

## Pre-Migration Analysis

### Current Architecture Assessment
```html
<!-- Current HTML Structure Analysis -->
CURRENT LAYOUT:
<body>
  <div class="app-container">
    <div class="top-bar">🍅 Pomodoro Genie</div>              ← KEEP: Header bar
    <div class="content-area">
      <div class="tab-content">                               ← REPLACE: Tab content
        <div class="timer-tab">...</div>                      ← MOVE: To modal overlay
        <div class="tasks-tab">...</div>                      ← RESTRUCTURE: Main content
        <div class="reports-tab">...</div>                    ← MOVE: To stats sidebar
        <div class="settings-tab">...</div>                   ← MOVE: To sidebar bottom
      </div>
    </div>
    <div class="bottom-nav">                                  ← REMOVE: Bottom navigation
      <div class="nav-item timer">⏰ 计时器</div>
      <div class="nav-item tasks">📋 任务</div>
      <div class="nav-item reports">📊 报告</div>
      <div class="nav-item settings">⚙️ 设置</div>
    </div>
  </div>
</body>
```

### Current Components Inventory
- ✅ **Timer Components**: Timer display, controls, session management
- ✅ **Task Management**: Task CRUD, priority settings, progress tracking
- ✅ **Statistics**: Daily/weekly reports, productivity insights
- ✅ **Settings**: Timer durations, notifications, theme preferences
- ✅ **Data Persistence**: localStorage integration with full offline support
- ✅ **Notifications**: Audio alerts and browser notifications

### Current Data Structures
```javascript
// Current localStorage schema (PRESERVE)
const currentDataStructure = {
  // Task data (NO CHANGES NEEDED)
  'pomodoro_tasks': [
    {
      id: 'task-123',
      title: 'Task title',
      completed: false,
      priority: 'high',
      pomodoros: 0,
      estimatedPomodoros: 3,
      createdAt: '2025-01-01T00:00:00Z'
    }
  ],

  // Settings data (NO CHANGES NEEDED)
  'pomodoro_settings': {
    workDuration: 25,
    shortBreakDuration: 5,
    longBreakDuration: 15,
    autoStartBreaks: false,
    soundEnabled: true,
    notificationsEnabled: true,
    currentTheme: 0
  },

  // Session data (NO CHANGES NEEDED)
  'pomodoro_sessions': [
    {
      id: 'session-456',
      taskId: 'task-123',
      startTime: '2025-01-01T10:00:00Z',
      duration: 1500,
      completed: true
    }
  ]
};
```

## Migration Phase 1: Infrastructure Setup (1-2 hours)

### 1.1 Project Structure Creation
- [ ] **Create project data layer**
  ```javascript
  // NEW: Add project grouping to existing tasks
  const projectGrouping = {
    'project-default': {
      id: 'project-default',
      name: 'Personal Tasks',
      color: '#3B82F6',
      icon: '📋',
      tasks: [] // Existing tasks go here
    }
  };
  ```

- [ ] **Update localStorage schema**
  ```javascript
  // Migration script for existing data
  function migrateToProjectFirst() {
    const existingTasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');

    // Create default project for existing tasks
    const defaultProject = {
      id: 'project-inbox',
      name: 'Inbox',
      description: 'Uncategorized tasks',
      color: '#6B7280',
      icon: '📥',
      created_at: new Date().toISOString()
    };

    // Add project reference to existing tasks
    const migratedTasks = existingTasks.map(task => ({
      ...task,
      project_id: 'project-inbox'
    }));

    // Save migrated data
    localStorage.setItem('pomodoro_projects', JSON.stringify([defaultProject]));
    localStorage.setItem('pomodoro_tasks', JSON.stringify(migratedTasks));
    localStorage.setItem('current_project', 'project-inbox');
  }
  ```

### 1.2 CSS Layout Migration
- [ ] **Update root layout structure**
  ```css
  /* NEW: Grid layout for sidebar + main content */
  .app-container {
    display: grid;
    grid-template-columns: 240px 1fr;
    grid-template-rows: auto 1fr;
    grid-template-areas:
      "sidebar header"
      "sidebar main";
    height: 100vh;
  }

  /* REMOVE: Bottom navigation styles */
  .bottom-nav { display: none; }

  /* UPDATE: Content area to main grid area */
  .content-area {
    grid-area: main;
    overflow-y: auto;
  }
  ```

- [ ] **Create sidebar layout styles**
  ```css
  /* NEW: Sidebar navigation */
  .project-sidebar {
    grid-area: sidebar;
    background: var(--surface-color);
    border-right: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .project-list {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
  }

  .daily-stats {
    border-top: 1px solid var(--border-color);
    padding: 16px;
    background: var(--background-color);
  }
  ```

## Migration Phase 2: Navigation Restructure (2-3 hours)

### 2.1 Remove Bottom Navigation
- [ ] **Delete bottom navigation HTML**
  ```html
  <!-- REMOVE ENTIRE BLOCK -->
  <div class="bottom-nav">
    <div class="nav-item timer">⏰ 计时器</div>
    <div class="nav-item tasks">📋 任务</div>
    <div class="nav-item reports">📊 报告</div>
    <div class="nav-item settings">⚙️ 设置</div>
  </div>
  ```

- [ ] **Remove bottom navigation JavaScript**
  ```javascript
  // REMOVE: Bottom navigation event handlers
  // DELETE: showTab() function
  // DELETE: updateActiveTab() function
  ```

### 2.2 Create Project Sidebar
- [ ] **Add sidebar HTML structure**
  ```html
  <!-- NEW: Add after top-bar -->
  <div class="project-sidebar">
    <div class="sidebar-header">
      <h3>📋 我的项目</h3>
      <button class="add-project-btn" onclick="showProjectModal()">➕</button>
    </div>

    <div class="project-list" id="projectList">
      <!-- Projects will be populated by JavaScript -->
    </div>

    <div class="daily-stats">
      <h4>📊 今日统计</h4>
      <div class="stat-item">
        <span>🍅 完成番茄钟</span>
        <span id="dailyPomodoros">0</span>
      </div>
      <div class="stat-item">
        <span>⏱️ 专注时间</span>
        <span id="dailyFocusTime">0h 0m</span>
      </div>
      <div class="stat-item">
        <span>✅ 完成任务</span>
        <span id="dailyTasks">0</span>
      </div>
    </div>

    <div class="sidebar-footer">
      <button onclick="showSettings()">⚙️ 设置</button>
      <button onclick="showReports()">📊 报告</button>
    </div>
  </div>
  ```

### 2.3 Update Main Content Area
- [ ] **Restructure main content**
  ```html
  <!-- UPDATE: Main content structure -->
  <div class="main-content">
    <div class="project-header">
      <h2 id="currentProjectName">📥 Inbox</h2>
      <div class="project-actions">
        <button onclick="addTask()">➕ 新建任务</button>
      </div>
    </div>

    <div class="task-list-container">
      <!-- Existing task list content moves here -->
    </div>
  </div>
  ```

## Migration Phase 3: Component Reorganization (3-4 hours)

### 3.1 Timer to Modal Conversion
- [ ] **Convert timer tab to modal overlay**
  ```html
  <!-- MOVE: Timer content to modal -->
  <div id="pomodoroModal" class="modal" style="display: none;">
    <div class="modal-content pomodoro-modal">
      <div class="modal-header">
        <h3 id="currentTaskTitle">Focus Session</h3>
        <button class="close-btn" onclick="closePomodoroModal()">✕</button>
      </div>

      <!-- MOVE: Existing timer HTML here -->
      <div class="timer-display">
        <!-- Existing timer content -->
      </div>

      <div class="timer-controls">
        <!-- Existing control buttons -->
      </div>

      <div class="session-info">
        <p>Session <span id="currentSession">1</span> of <span id="totalSessions">4</span></p>
        <p>Task: <span id="modalTaskTitle">Current task</span></p>
      </div>
    </div>
  </div>
  ```

- [ ] **Update timer activation**
  ```javascript
  // NEW: Start pomodoro from task context
  function startPomodoroForTask(taskId) {
    const task = getTaskById(taskId);

    // Set current task context
    document.getElementById('currentTaskTitle').textContent = task.title;
    document.getElementById('modalTaskTitle').textContent = task.title;

    // Show modal and start timer
    document.getElementById('pomodoroModal').style.display = 'flex';
    startTimer(taskId);
  }

  // UPDATE: Task cards to include pomodoro buttons
  function renderTaskCard(task) {
    return `
      <div class="task-item" data-task-id="${task.id}">
        <div class="task-content">
          <h4>${task.title}</h4>
          <p class="task-priority priority-${task.priority}">${task.priority}</p>
        </div>
        <div class="task-actions">
          <button onclick="startPomodoroForTask('${task.id}')" class="pomodoro-btn">
            🍅 开始番茄钟
          </button>
          <button onclick="editTask('${task.id}')">✏️</button>
          <button onclick="deleteTask('${task.id}')">🗑️</button>
        </div>
      </div>
    `;
  }
  ```

### 3.2 Project Management Integration
- [ ] **Add project management functions**
  ```javascript
  // NEW: Project management system
  class ProjectManager {
    constructor() {
      this.projects = JSON.parse(localStorage.getItem('pomodoro_projects') || '[]');
      this.currentProject = localStorage.getItem('current_project') || null;
    }

    createProject(name, icon = '📁', color = '#3B82F6') {
      const project = {
        id: 'project-' + Date.now(),
        name,
        icon,
        color,
        description: '',
        created_at: new Date().toISOString()
      };

      this.projects.push(project);
      this.saveProjects();
      this.renderProjectList();
      return project;
    }

    switchToProject(projectId) {
      this.currentProject = projectId;
      localStorage.setItem('current_project', projectId);

      // Update UI
      this.updateProjectHeader();
      this.filterTasksByProject();
      this.highlightActiveProject();
    }

    updateProjectHeader() {
      const project = this.projects.find(p => p.id === this.currentProject);
      if (project) {
        document.getElementById('currentProjectName').textContent =
          `${project.icon} ${project.name}`;
      }
    }

    filterTasksByProject() {
      const tasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');
      const projectTasks = tasks.filter(task => task.project_id === this.currentProject);
      renderTaskList(projectTasks);
    }

    renderProjectList() {
      const container = document.getElementById('projectList');
      container.innerHTML = this.projects.map(project => `
        <div class="project-item ${project.id === this.currentProject ? 'active' : ''}"
             onclick="projectManager.switchToProject('${project.id}')">
          <div class="project-icon">${project.icon}</div>
          <div class="project-info">
            <div class="project-name">${project.name}</div>
            <div class="project-stats">
              ${this.getProjectTaskCount(project.id)} tasks
            </div>
          </div>
          <div class="project-progress">
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${this.getProjectProgress(project.id)}%"></div>
            </div>
          </div>
        </div>
      `).join('');
    }

    getProjectTaskCount(projectId) {
      const tasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');
      return tasks.filter(task => task.project_id === projectId).length;
    }

    getProjectProgress(projectId) {
      const tasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');
      const projectTasks = tasks.filter(task => task.project_id === projectId);
      if (projectTasks.length === 0) return 0;

      const completedTasks = projectTasks.filter(task => task.completed).length;
      return Math.round((completedTasks / projectTasks.length) * 100);
    }
  }

  // Initialize project manager
  const projectManager = new ProjectManager();
  ```

### 3.3 Daily Statistics Integration
- [ ] **Update statistics display**
  ```javascript
  // UPDATE: Statistics to show in sidebar
  function updateDailyStats() {
    const sessions = JSON.parse(localStorage.getItem('pomodoro_sessions') || '[]');
    const tasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');

    const today = new Date().toDateString();
    const todaySessions = sessions.filter(session =>
      new Date(session.startTime).toDateString() === today && session.completed
    );

    const todayTasks = tasks.filter(task =>
      task.completed && new Date(task.completedAt || 0).toDateString() === today
    );

    // Update sidebar stats
    document.getElementById('dailyPomodoros').textContent = todaySessions.length;
    document.getElementById('dailyTasks').textContent = todayTasks.length;

    const totalMinutes = todaySessions.reduce((sum, session) => sum + (session.duration / 60), 0);
    const hours = Math.floor(totalMinutes / 60);
    const minutes = Math.round(totalMinutes % 60);
    document.getElementById('dailyFocusTime').textContent = `${hours}h ${minutes}m`;
  }
  ```

## Migration Phase 4: Mobile Responsiveness (1-2 hours)

### 4.1 Responsive Layout
- [ ] **Add mobile breakpoints**
  ```css
  /* MOBILE: Hide sidebar, show hamburger */
  @media (max-width: 768px) {
    .app-container {
      grid-template-columns: 1fr;
      grid-template-areas:
        "header"
        "main";
    }

    .project-sidebar {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100vh;
      z-index: 1000;
      transform: translateX(-100%);
      transition: transform 0.3s ease;
    }

    .project-sidebar.open {
      transform: translateX(0);
    }

    .mobile-menu-btn {
      display: block;
    }
  }

  @media (min-width: 769px) {
    .mobile-menu-btn {
      display: none;
    }
  }
  ```

- [ ] **Add mobile navigation controls**
  ```html
  <!-- ADD: Mobile hamburger menu -->
  <div class="top-bar">
    <button class="mobile-menu-btn" onclick="toggleMobileSidebar()">☰</button>
    <span>🍅 Pomodoro Genie</span>
  </div>
  ```

### 4.2 Touch Interactions
- [ ] **Add touch gesture support**
  ```javascript
  // NEW: Mobile sidebar toggle
  function toggleMobileSidebar() {
    const sidebar = document.querySelector('.project-sidebar');
    sidebar.classList.toggle('open');
  }

  // NEW: Touch gestures for mobile
  let touchStartX = 0;
  let touchEndX = 0;

  document.addEventListener('touchstart', e => {
    touchStartX = e.changedTouches[0].screenX;
  });

  document.addEventListener('touchend', e => {
    touchEndX = e.changedTouches[0].screenX;
    handleSwipeGesture();
  });

  function handleSwipeGesture() {
    const swipeDistance = touchEndX - touchStartX;
    const sidebar = document.querySelector('.project-sidebar');

    if (swipeDistance > 100 && touchStartX < 50) {
      // Swipe right from left edge - open sidebar
      sidebar.classList.add('open');
    } else if (swipeDistance < -100 && sidebar.classList.contains('open')) {
      // Swipe left - close sidebar
      sidebar.classList.remove('open');
    }
  }
  ```

## Migration Phase 5: Data Migration & Testing (1-2 hours)

### 5.1 Data Migration Script
- [ ] **Create migration utility**
  ```javascript
  // MIGRATION: One-time data migration script
  function performDataMigration() {
    const migrationVersion = localStorage.getItem('migration_version');

    if (migrationVersion !== '2.0') {
      console.log('Performing data migration to project-first architecture...');

      // Migrate existing tasks to project structure
      const existingTasks = JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]');

      // Create default inbox project
      const inboxProject = {
        id: 'project-inbox',
        name: 'Inbox',
        description: 'Uncategorized tasks',
        icon: '📥',
        color: '#6B7280',
        created_at: new Date().toISOString()
      };

      // Update tasks with project reference
      const migratedTasks = existingTasks.map(task => ({
        ...task,
        project_id: task.project_id || 'project-inbox'
      }));

      // Save migrated data
      localStorage.setItem('pomodoro_projects', JSON.stringify([inboxProject]));
      localStorage.setItem('pomodoro_tasks', JSON.stringify(migratedTasks));
      localStorage.setItem('current_project', 'project-inbox');
      localStorage.setItem('migration_version', '2.0');

      console.log('Migration completed successfully!');
      return true;
    }

    return false;
  }

  // Run migration on app initialization
  document.addEventListener('DOMContentLoaded', () => {
    const migrated = performDataMigration();
    if (migrated) {
      alert('Welcome to the new project-first interface! Your tasks have been organized in the Inbox project.');
    }

    // Initialize new UI
    initializeProjectFirstUI();
  });
  ```

### 5.2 Testing Checklist
- [ ] **Functional Testing**
  - [ ] All existing tasks remain accessible
  - [ ] Timer functionality works with task context
  - [ ] Statistics calculate correctly
  - [ ] Settings persist across sessions
  - [ ] localStorage data integrity maintained

- [ ] **UI Testing**
  - [ ] Sidebar navigation works on desktop
  - [ ] Mobile hamburger menu functions properly
  - [ ] Responsive design adapts to screen sizes
  - [ ] Project switching updates main content
  - [ ] Modal overlays display correctly

- [ ] **Data Testing**
  - [ ] Migration script runs without errors
  - [ ] Existing data preserved after migration
  - [ ] New project structure created correctly
  - [ ] Task-project relationships established
  - [ ] Statistics reflect migrated data

## Migration Validation

### Pre-Migration Backup
```javascript
// CRITICAL: Create backup before migration
function createPreMigrationBackup() {
  const backup = {
    timestamp: new Date().toISOString(),
    tasks: localStorage.getItem('pomodoro_tasks'),
    sessions: localStorage.getItem('pomodoro_sessions'),
    settings: localStorage.getItem('pomodoro_settings'),
    userData: localStorage.getItem('user_data')
  };

  localStorage.setItem('pre_migration_backup', JSON.stringify(backup));
  console.log('Pre-migration backup created successfully');
}
```

### Post-Migration Validation
```javascript
// VALIDATION: Verify migration success
function validateMigration() {
  const checks = {
    projectsExist: !!localStorage.getItem('pomodoro_projects'),
    tasksHaveProjects: JSON.parse(localStorage.getItem('pomodoro_tasks') || '[]')
      .every(task => task.project_id),
    currentProjectSet: !!localStorage.getItem('current_project'),
    backupExists: !!localStorage.getItem('pre_migration_backup')
  };

  const allPassed = Object.values(checks).every(check => check);

  if (allPassed) {
    console.log('✅ Migration validation passed');
    return true;
  } else {
    console.error('❌ Migration validation failed:', checks);
    return false;
  }
}
```

## Rollback Procedure

### Emergency Rollback
```javascript
// ROLLBACK: Restore from backup if needed
function rollbackMigration() {
  const backup = JSON.parse(localStorage.getItem('pre_migration_backup') || '{}');

  if (backup.timestamp) {
    localStorage.setItem('pomodoro_tasks', backup.tasks);
    localStorage.setItem('pomodoro_sessions', backup.sessions);
    localStorage.setItem('pomodoro_settings', backup.settings);
    localStorage.setItem('user_data', backup.userData);

    // Remove new data
    localStorage.removeItem('pomodoro_projects');
    localStorage.removeItem('current_project');
    localStorage.removeItem('migration_version');

    alert('Migration rolled back successfully. Please refresh the page.');
    return true;
  }

  return false;
}
```

## Success Criteria

### Migration Complete When:
- [ ] **✅ All existing functionality preserved**
  - Timer, tasks, statistics, settings work as before
- [ ] **✅ New project-first navigation implemented**
  - Sidebar with project list replaces bottom navigation
- [ ] **✅ Data migration successful**
  - All tasks moved to project structure
  - No data loss during migration
- [ ] **✅ Mobile responsiveness maintained**
  - Works on mobile devices with hamburger menu
- [ ] **✅ Performance maintained or improved**
  - Loading times remain fast
  - localStorage operations efficient

### Post-Migration Benefits:
- **Better Organization**: Tasks grouped by projects
- **Improved Navigation**: Sidebar scales better than bottom tabs
- **Enhanced Context**: Timer sessions linked to specific tasks
- **Future-Ready**: Architecture supports backend integration
- **Mobile-Friendly**: Responsive design with modern navigation patterns

This migration checklist ensures a smooth transition from task-first to project-first architecture while preserving all existing functionality and data.