# 🎨 Pomodoro Genie 前端项目优先架构设计

## 📋 设计概述

基于用户需求分析和当前实现状况，重新设计前端界面为**项目优先**架构，将项目管理作为核心功能，任务作为项目的执行单元，番茄钟作为任务执行的工具。

## 🎯 设计目标

### 主要改进点
1. **项目优先导航**: 将底部导航改为左侧边栏，项目列表优先显示
2. **任务-番茄钟解耦**: 每个任务添加独立番茄钟按钮，按需启动专注模式
3. **简化核心功能**: 去除智能项目建议、项目模板、快速切换等复杂特性
4. **直观项目管理**: 支持直接创建"Inbox"项目，所有任务归属于项目

## 🏗️ 整体布局架构

```
┌─────────────────────────────────────────────────────────────┐
│                     顶部标题栏                                │
│  🍅 Pomodoro Genie    [用户头像] [设置] [通知]                  │
├───────────────┬─────────────────────────────────────────────┤
│               │                                             │
│   左侧边栏     │              主内容区域                      │
│   (200px)     │            (flex-grow: 1)                  │
│               │                                             │
│ 📋 项目列表    │   📊 项目详情 / 📝 任务列表 / 🍅 番茄钟界面    │
│               │                                             │
│ ├─ 📁 Inbox   │                                             │
│ ├─ 📁 Work    │                                             │
│ ├─ 📁 Study   │                                             │
│ └─ ➕ 新建项目  │                                             │
│               │                                             │
│ 📈 今日统计    │                                             │
│ 🔔 快捷操作    │                                             │
│               │                                             │
└───────────────┴─────────────────────────────────────────────┘
```

## 🧭 左侧边栏设计

### 项目列表区域
```html
<div class="sidebar">
  <!-- 项目标题 -->
  <div class="sidebar-header">
    <h3>📋 我的项目</h3>
    <button class="btn-add-project">➕</button>
  </div>

  <!-- 项目列表 -->
  <div class="project-list">
    <div class="project-item active" data-project="inbox">
      <span class="project-icon">📥</span>
      <span class="project-name">Inbox</span>
      <span class="task-count">5</span>
    </div>

    <div class="project-item" data-project="work">
      <span class="project-icon">💼</span>
      <span class="project-name">工作项目</span>
      <span class="task-count">12</span>
    </div>

    <div class="project-item" data-project="study">
      <span class="project-icon">📚</span>
      <span class="project-name">学习计划</span>
      <span class="task-count">8</span>
    </div>
  </div>

  <!-- 今日统计 -->
  <div class="daily-stats">
    <h4>📊 今日统计</h4>
    <div class="stat-item">
      <span>🍅 完成番茄钟</span>
      <span class="stat-value">6</span>
    </div>
    <div class="stat-item">
      <span>⏱️ 专注时间</span>
      <span class="stat-value">2h 30m</span>
    </div>
    <div class="stat-item">
      <span>✅ 完成任务</span>
      <span class="stat-value">4</span>
    </div>
  </div>
</div>
```

### 样式规范
```css
.sidebar {
  width: 240px;
  background: #f8f9fa;
  border-right: 1px solid #e9ecef;
  padding: 20px 16px;
  height: 100vh;
  overflow-y: auto;
}

.project-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  margin: 4px 0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.project-item:hover {
  background: #e9ecef;
}

.project-item.active {
  background: #007bff;
  color: white;
}

.task-count {
  margin-left: auto;
  background: rgba(0,0,0,0.1);
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
}
```

## 📝 主内容区域设计

### 1. 项目详情视图
```html
<div class="main-content">
  <!-- 项目头部 -->
  <div class="project-header">
    <div class="project-info">
      <h1>💼 工作项目</h1>
      <p class="project-description">日常工作任务和会议安排</p>
    </div>
    <div class="project-actions">
      <button class="btn btn-primary">➕ 新建任务</button>
      <button class="btn btn-secondary">⚙️ 项目设置</button>
    </div>
  </div>

  <!-- 项目统计 -->
  <div class="project-stats">
    <div class="stat-card">
      <div class="stat-value">24</div>
      <div class="stat-label">总任务</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">12</div>
      <div class="stat-label">已完成</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">50%</div>
      <div class="stat-label">完成率</div>
    </div>
    <div class="stat-card">
      <div class="stat-value">36</div>
      <div class="stat-label">番茄钟</div>
    </div>
  </div>

  <!-- 任务列表 -->
  <div class="task-section">
    <h3>📋 任务列表</h3>
    <div class="task-filters">
      <button class="filter-btn active">全部</button>
      <button class="filter-btn">待开始</button>
      <button class="filter-btn">进行中</button>
      <button class="filter-btn">已完成</button>
    </div>

    <div class="task-list">
      <!-- 任务项模板见下节 -->
    </div>
  </div>
</div>
```

### 2. 任务卡片设计（核心改进）
```html
<div class="task-item" data-task-id="task-001">
  <div class="task-main">
    <div class="task-checkbox">
      <input type="checkbox" id="task-001">
      <label for="task-001"></label>
    </div>

    <div class="task-content">
      <h4 class="task-title">完成项目架构设计</h4>
      <p class="task-description">设计前端项目优先架构，包括左侧边栏和任务管理</p>
      <div class="task-meta">
        <span class="priority high">🔴 高优先级</span>
        <span class="due-date">📅 10月8日</span>
        <span class="pomodoro-count">🍅 2/5</span>
      </div>
    </div>
  </div>

  <div class="task-actions">
    <!-- 核心改进：独立番茄钟按钮 -->
    <button class="btn-pomodoro" data-task-id="task-001">
      🍅 开始番茄钟
    </button>
    <button class="btn-edit">✏️</button>
    <button class="btn-delete">🗑️</button>
  </div>
</div>
```

### 任务卡片样式
```css
.task-item {
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  padding: 16px;
  margin: 8px 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.task-item:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform: translateY(-1px);
}

.task-main {
  display: flex;
  align-items: flex-start;
  flex-grow: 1;
  gap: 12px;
}

.btn-pomodoro {
  background: #ff6b6b;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-pomodoro:hover {
  background: #ff5252;
  transform: scale(1.05);
}
```

## 🍅 番茄钟界面设计

### 专注模式弹窗
```html
<div class="pomodoro-modal" id="pomodoroModal">
  <div class="modal-content">
    <div class="modal-header">
      <h3>🍅 专注模式</h3>
      <button class="btn-close">&times;</button>
    </div>

    <div class="current-task">
      <h4>当前任务</h4>
      <p>完成项目架构设计</p>
      <div class="task-progress">
        <span>番茄钟进度: 2/5</span>
        <div class="progress-bar">
          <div class="progress-fill" style="width: 40%"></div>
        </div>
      </div>
    </div>

    <div class="timer-display">
      <div class="timer-circle">
        <svg class="timer-svg">
          <circle class="timer-background" cx="120" cy="120" r="100"></circle>
          <circle class="timer-progress" cx="120" cy="120" r="100"></circle>
        </svg>
        <div class="timer-text">
          <div class="time-remaining">25:00</div>
          <div class="timer-label">工作时间</div>
        </div>
      </div>
    </div>

    <div class="timer-controls">
      <button class="btn btn-large btn-primary" id="startPauseBtn">
        ▶️ 开始
      </button>
      <button class="btn btn-large btn-secondary" id="resetBtn">
        🔄 重置
      </button>
      <button class="btn btn-large btn-tertiary" id="skipBtn">
        ⏭️ 跳过
      </button>
    </div>

    <div class="session-info">
      <div class="session-type">工作时间</div>
      <div class="session-progress">第 3 轮，共 4 轮</div>
    </div>
  </div>
</div>
```

### 番茄钟模态框样式
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

.timer-background {
  fill: none;
  stroke: #e9ecef;
  stroke-width: 8;
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

.timer-label {
  font-size: 16px;
  color: #666;
  margin-top: 8px;
}
```

## 📱 响应式设计

### 移动端适配 (< 768px)
```css
@media (max-width: 768px) {
  .layout {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    height: auto;
    order: 2;
    border-right: none;
    border-top: 1px solid #e9ecef;
  }

  .main-content {
    order: 1;
    padding: 16px;
  }

  .project-list {
    display: flex;
    overflow-x: auto;
    gap: 8px;
  }

  .project-item {
    flex-shrink: 0;
    min-width: 120px;
  }

  .task-item {
    flex-direction: column;
    align-items: stretch;
  }

  .task-actions {
    margin-top: 12px;
    display: flex;
    gap: 8px;
  }

  .pomodoro-modal .modal-content {
    width: 95vw;
    padding: 24px 16px;
  }

  .timer-circle {
    width: 200px;
    height: 200px;
  }
}
```

### 平板端适配 (768px - 1024px)
```css
@media (min-width: 768px) and (max-width: 1024px) {
  .sidebar {
    width: 220px;
  }

  .project-stats {
    grid-template-columns: repeat(2, 1fr);
  }

  .task-list {
    padding: 0 16px;
  }
}
```

## 🔧 核心交互逻辑

### 1. 项目切换交互
```javascript
class ProjectManager {
  constructor() {
    this.currentProject = 'inbox';
    this.projects = this.loadProjects();
    this.initEventListeners();
  }

  initEventListeners() {
    // 项目切换
    document.querySelectorAll('.project-item').forEach(item => {
      item.addEventListener('click', (e) => {
        const projectId = e.currentTarget.dataset.project;
        this.switchProject(projectId);
      });
    });

    // 新建项目
    document.querySelector('.btn-add-project').addEventListener('click', () => {
      this.showCreateProjectModal();
    });
  }

  switchProject(projectId) {
    // 更新激活状态
    document.querySelectorAll('.project-item').forEach(item => {
      item.classList.remove('active');
    });
    document.querySelector(`[data-project="${projectId}"]`).classList.add('active');

    // 切换主内容
    this.currentProject = projectId;
    this.loadProjectTasks(projectId);
    this.updateProjectHeader(projectId);
    this.updateProjectStats(projectId);
  }

  loadProjectTasks(projectId) {
    const tasks = this.getTasksByProject(projectId);
    const taskList = document.querySelector('.task-list');
    taskList.innerHTML = tasks.map(task => this.renderTaskItem(task)).join('');

    // 重新绑定任务事件
    this.initTaskEventListeners();
  }
}
```

### 2. 任务-番茄钟交互
```javascript
class TaskPomodoroManager {
  constructor() {
    this.currentTask = null;
    this.pomodoroModal = document.getElementById('pomodoroModal');
    this.timer = new PomodoroTimer();
  }

  initTaskEventListeners() {
    // 任务番茄钟按钮
    document.querySelectorAll('.btn-pomodoro').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const taskId = e.currentTarget.dataset.taskId;
        this.startPomodoroForTask(taskId);
      });
    });
  }

  startPomodoroForTask(taskId) {
    const task = this.getTaskById(taskId);
    if (!task) return;

    this.currentTask = task;
    this.showPomodoroModal(task);
    this.timer.start(25 * 60); // 25分钟
  }

  showPomodoroModal(task) {
    // 更新模态框内容
    document.querySelector('.current-task p').textContent = task.title;
    document.querySelector('.task-progress span').textContent =
      `番茄钟进度: ${task.completedPomodoros}/${task.targetPomodoros}`;

    const progressPercent = (task.completedPomodoros / task.targetPomodoros) * 100;
    document.querySelector('.progress-fill').style.width = `${progressPercent}%`;

    // 显示模态框
    this.pomodoroModal.classList.add('show');
    document.body.classList.add('modal-open');
  }

  onPomodoroComplete() {
    if (this.currentTask) {
      this.currentTask.completedPomodoros++;
      this.updateTaskProgress(this.currentTask);
      this.saveTask(this.currentTask);
    }

    // 显示完成通知
    this.showNotification('🍅 番茄钟完成！', '是时候休息一下了');

    // 自动开始休息时间
    this.timer.start(5 * 60); // 5分钟休息
  }
}
```

### 3. 数据持久化策略
```javascript
class DataManager {
  constructor() {
    this.storageKey = 'pomodoroGenie';
    this.data = this.loadData();
  }

  loadData() {
    const stored = localStorage.getItem(this.storageKey);
    return stored ? JSON.parse(stored) : {
      projects: [
        {
          id: 'inbox',
          name: 'Inbox',
          description: '默认项目收集箱',
          icon: '📥',
          isDefault: true,
          createdAt: new Date().toISOString()
        }
      ],
      tasks: [],
      sessions: [],
      settings: {
        workDuration: 25,
        shortBreak: 5,
        longBreak: 15,
        longBreakInterval: 4
      }
    };
  }

  saveData() {
    localStorage.setItem(this.storageKey, JSON.stringify(this.data));
  }

  createProject(name, description, icon = '📁') {
    const project = {
      id: generateId(),
      name,
      description,
      icon,
      isDefault: false,
      createdAt: new Date().toISOString(),
      tasks: []
    };

    this.data.projects.push(project);
    this.saveData();
    return project;
  }

  createTask(projectId, title, description = '') {
    const task = {
      id: generateId(),
      projectId,
      title,
      description,
      status: 'pending',
      priority: 'medium',
      completedPomodoros: 0,
      targetPomodoros: 1,
      createdAt: new Date().toISOString()
    };

    this.data.tasks.push(task);
    this.saveData();
    return task;
  }

  getTasksByProject(projectId) {
    return this.data.tasks.filter(task => task.projectId === projectId);
  }

  getProjectStats(projectId) {
    const tasks = this.getTasksByProject(projectId);
    const completedTasks = tasks.filter(task => task.status === 'completed');
    const totalPomodoros = tasks.reduce((sum, task) => sum + task.completedPomodoros, 0);

    return {
      totalTasks: tasks.length,
      completedTasks: completedTasks.length,
      completionRate: tasks.length > 0 ? (completedTasks.length / tasks.length * 100).toFixed(1) : 0,
      totalPomodoros
    };
  }
}
```

## 🎨 主题和视觉设计

### 颜色方案
```css
:root {
  /* 主色调 */
  --primary-color: #ff6b6b;
  --primary-hover: #ff5252;
  --primary-light: #ffebee;

  /* 辅助色 */
  --secondary-color: #4ecdc4;
  --accent-color: #45b7d1;
  --warning-color: #ffa726;
  --success-color: #66bb6a;

  /* 中性色 */
  --background-color: #f8f9fa;
  --surface-color: #ffffff;
  --border-color: #e9ecef;
  --text-primary: #333333;
  --text-secondary: #666666;
  --text-disabled: #999999;

  /* 阴影 */
  --shadow-light: 0 2px 4px rgba(0,0,0,0.05);
  --shadow-medium: 0 4px 12px rgba(0,0,0,0.1);
  --shadow-heavy: 0 8px 24px rgba(0,0,0,0.15);

  /* 圆角 */
  --radius-small: 4px;
  --radius-medium: 8px;
  --radius-large: 12px;
  --radius-round: 50%;

  /* 间距 */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
}
```

### 优先级颜色标识
```css
.priority {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
}

.priority.low {
  background: #e8f5e8;
  color: #2e7d32;
}

.priority.medium {
  background: #fff3e0;
  color: #f57c00;
}

.priority.high {
  background: #ffebee;
  color: #d32f2f;
}

.priority.urgent {
  background: #fce4ec;
  color: #c2185b;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}
```

## 🚀 实现路线图

### Phase 1: 基础架构 (Week 1)
1. **布局重构**
   - 将底部导航改为左侧边栏
   - 实现响应式布局系统
   - 建立基础组件库

2. **项目管理核心**
   - 实现项目创建/编辑/删除
   - 项目列表展示和切换
   - 默认 Inbox 项目支持

### Phase 2: 任务增强 (Week 2)
1. **任务-项目关联**
   - 修改任务数据结构添加 projectId
   - 实现任务在项目间的分组显示
   - 项目统计数据计算

2. **番茄钟集成**
   - 任务独立番茄钟按钮
   - 专注模式弹窗界面
   - 任务进度跟踪

### Phase 3: 体验优化 (Week 3)
1. **交互细节**
   - 动画过渡效果
   - 拖拽排序功能
   - 键盘快捷键支持

2. **数据持久化**
   - 改进 localStorage 数据结构
   - 数据迁移和备份机制
   - 离线同步策略

### Phase 4: 高级功能 (Week 4+)
1. **性能优化**
   - 虚拟滚动优化
   - 懒加载实现
   - 缓存策略

2. **扩展功能**
   - 项目模板系统
   - 高级过滤和搜索
   - 数据导出功能

## 📋 验收标准

### 功能完整性
- [ ] 左侧边栏项目导航完全替代底部导航
- [ ] 所有任务必须归属于项目（默认Inbox）
- [ ] 每个任务具有独立番茄钟启动按钮
- [ ] 番茄钟弹窗显示当前任务信息和进度
- [ ] 项目切换时正确加载对应任务列表
- [ ] 项目统计数据实时更新

### 用户体验
- [ ] 界面响应速度 < 100ms
- [ ] 移动端操作体验流畅
- [ ] 视觉设计一致性和美观度
- [ ] 操作流程符合用户直觉
- [ ] 错误状态和加载状态提示完善

### 技术质量
- [ ] 代码结构清晰，模块化良好
- [ ] 数据持久化稳定可靠
- [ ] 浏览器兼容性良好
- [ ] 性能表现满足使用需求
- [ ] 可维护性和可扩展性

---

## 📋 完整组件规范

基于详细设计文档，以下是所有UI组件的完整规范和集成指南：

### 核心导航组件

#### ProjectSidebar 组件
**文件**: `docs/components/project-sidebar.md`
- **功能**: 左侧项目导航容器，包含项目列表、统计信息和设置入口
- **尺寸**: 240px宽度（桌面），60px宽度（平板收缩），100%宽度（移动端覆盖）
- **响应式行为**: 桌面显示完整内容，平板悬停展开，移动端滑出覆盖
- **集成**: 包含ProjectList和DailyStats子组件

#### ProjectList 组件
**文件**: `docs/components/project-list.md`
- **功能**: 项目列表显示和管理，支持项目创建、切换、进度显示
- **数据绑定**: 动态加载项目列表，实时更新任务计数和完成度
- **交互**: 点击切换项目，右键菜单，键盘导航支持
- **状态管理**: 当前活跃项目高亮，加载状态指示

#### DailyStats 组件
**文件**: `docs/components/daily-stats.md`
- **功能**: 今日生产力统计展示（番茄钟、专注时间、完成任务、连续天数）
- **数据源**: 从SessionService和TaskService聚合当日数据
- **更新频率**: 实时更新，session完成时触发刷新
- **显示模式**: 完整模式（桌面）和紧凑模式（移动端）

### 主要内容组件

#### TaskList 组件
**文件**: `docs/components/task-list.md`
- **功能**: 任务列表展示，支持过滤、排序、搜索、批量操作
- **虚拟化**: 支持1000+任务的性能优化
- **集成**: 与TaskCard和TaskActions组件协作
- **数据流**: 项目切换时自动过滤，实时同步任务状态

#### TaskCard 组件
**文件**: `docs/components/task-card.md`
- **功能**: 单个任务卡片展示，包含任务信息、优先级、进度、操作按钮
- **状态**: 支持待开始、进行中、已完成、已删除等状态
- **交互**: 点击展开详情，拖拽排序，右键菜单
- **番茄钟集成**: 每个任务卡片包含独立的"🍅 开始番茄钟"按钮

#### ProjectHeader 组件
**文件**: `docs/components/project-header.md`
- **功能**: 当前项目信息展示，包含项目名称、描述、统计数据、操作按钮
- **动态内容**: 根据选中项目动态更新内容
- **操作**: 新建任务、项目设置、查看统计等快速入口
- **响应式**: 移动端隐藏部分次要信息，保留核心操作

### 交互组件

#### PomodoroModal 组件
**文件**: `docs/components/pomodoro-modal.md`
- **功能**: 番茄钟专注模式弹窗，显示当前任务信息和计时器
- **全屏覆盖**: 提供沉浸式专注体验
- **任务关联**: 显示当前任务标题、项目信息、番茄钟进度
- **会话管理**: 自动管理工作/休息循环，支持手动跳过和暂停

#### TimerDisplay 组件
**文件**: `docs/components/timer-display.md`
- **功能**: 高精度倒计时显示，支持圆形进度条和数字显示
- **背景计时**: 使用Web Worker确保计时准确性
- **视觉效果**: 动态进度条、颜色变化（工作时间红色，休息时间绿色）
- **通知集成**: 支持声音提醒和桌面通知

#### TaskActions 组件
**文件**: `docs/components/task-actions.md`
- **功能**: 任务操作按钮组，包含编辑、删除、标记完成等操作
- **权限控制**: 根据任务状态和用户权限显示不同操作
- **快速操作**: 支持批量操作和键盘快捷键
- **响应式**: 移动端使用下拉菜单，桌面端显示完整按钮

## 🔄 组件交互流程

### 完整的数据流向图

```
用户操作 → 组件事件 → 状态管理 → 数据服务 → 后端API
    ↓           ↓           ↓           ↓         ↓
  UI反馈 ← 组件更新 ← 状态变更 ← 数据同步 ← API响应
```

#### 1. 项目切换流程
**文件**: `docs/flows/project-switching-flow.md`
1. 用户点击ProjectList中的项目项
2. ProjectList触发项目切换事件
3. 全局状态管理更新currentProject
4. TaskList自动过滤并重新渲染任务
5. ProjectHeader更新项目信息
6. DailyStats刷新项目相关统计

#### 2. 任务到番茄钟流程
**文件**: `docs/flows/task-pomodoro-flow.md`
1. 用户点击TaskCard中的"🍅 开始番茄钟"按钮
2. TaskActions验证任务状态和权限
3. PomodoroModal打开并显示任务信息
4. TimerDisplay初始化25分钟工作计时
5. 计时完成后更新任务番茄钟计数
6. DailyStats实时刷新统计数据

#### 3. 响应式布局切换
**文件**: `docs/flows/responsive-breakpoint-flow.md`
1. 窗口大小改变触发媒体查询
2. ProjectSidebar根据断点调整显示模式
3. TaskList调整卡片布局（网格→列表→堆叠）
4. PomodoroModal调整尺寸和位置
5. 所有组件保持功能完整性

## 🔗 后端集成规范

### API端点映射
**文件**: `docs/backend-integration.md`

#### 项目管理API
- `GET /api/projects` → ProjectList组件数据源
- `POST /api/projects` → 新建项目功能
- `PUT /api/projects/:id` → 项目编辑功能
- `DELETE /api/projects/:id` → 项目删除功能

#### 任务管理API
- `GET /api/projects/:id/tasks` → TaskList组件数据源
- `POST /api/tasks` → TaskCard创建功能
- `PUT /api/tasks/:id` → 任务状态更新
- `DELETE /api/tasks/:id` → 任务删除功能

#### 番茄钟会话API
- `POST /api/sessions` → PomodoroModal会话创建
- `PUT /api/sessions/:id` → TimerDisplay进度同步
- `POST /api/sessions/:id/complete` → 会话完成处理

#### 统计数据API
- `GET /api/users/:id/stats` → DailyStats数据源
- `GET /api/projects/:id/stats` → ProjectHeader统计信息

### 数据绑定模式
**文件**: `docs/data-binding-patterns.md`

#### 响应式数据绑定
所有组件采用单向数据流模式，通过全局状态管理统一协调：

```javascript
// 状态管理示例
const AppState = {
  projects: [],
  currentProject: null,
  tasks: [],
  activeSession: null,
  dailyStats: {}
};

// 组件数据绑定
ProjectList.bindData(AppState.projects);
TaskList.bindData(AppState.tasks);
DailyStats.bindData(AppState.dailyStats);
```

#### 性能优化模式
- **虚拟滚动**: TaskList支持大量任务的高性能渲染
- **智能缓存**: API响应缓存5分钟，减少网络请求
- **增量更新**: 只更新变化的组件部分，避免全量重渲染
- **预加载策略**: 鼠标悬停时预加载相关数据

## 📱 响应式设计集成

### 断点管理
所有组件遵循统一的响应式断点：
- **移动端**: <480px（单列布局）
- **大移动端**: 481-767px（紧凑布局）
- **平板**: 768-1023px（混合布局）
- **桌面**: 1024px+（完整布局）

### 组件适配策略
每个组件在不同断点下的行为已在各自规范文档中详细定义：

#### 导航适配
- ProjectSidebar: 桌面固定 → 平板悬停 → 移动覆盖
- ProjectList: 垂直列表 → 水平滚动 → 折叠菜单

#### 内容适配
- TaskList: 网格布局 → 双列布局 → 单列堆叠
- TaskCard: 水平排列 → 垂直排列 → 紧凑模式

#### 交互适配
- PomodoroModal: 居中弹窗 → 全屏显示 → 底部弹起
- TaskActions: 按钮组 → 下拉菜单 → 滑动操作

## 🧪 实施验证清单

### 组件开发完成标准
基于各组件规范文档，每个组件需满足：

- [ ] **功能完整性**: 所有props和方法按规范实现
- [ ] **视觉一致性**: UI严格遵循设计规范
- [ ] **响应式适配**: 三个断点下表现正常
- [ ] **无障碍访问**: 支持键盘导航和屏幕阅读器
- [ ] **性能要求**: 渲染时间<100ms，内存使用合理
- [ ] **错误处理**: 网络异常、数据缺失等场景处理完善
- [ ] **单元测试**: 核心功能和边界条件测试覆盖

### 集成验证场景
基于交互流程文档，需验证：

- [ ] **完整用户路径**: 从项目选择到番茄钟完成的端到端流程
- [ ] **组件协作**: 组件间数据传递和状态同步无误
- [ ] **异常恢复**: 网络中断、数据冲突等异常场景处理
- [ ] **性能压力**: 大量项目和任务下的系统响应性能
- [ ] **跨浏览器**: Chrome、Firefox、Safari等主流浏览器兼容

### 迁移验证要求
基于迁移清单，确保：

- [ ] **数据保持**: 现有用户数据完整迁移到新架构
- [ ] **功能对等**: 所有原有功能在新界面中可用
- [ ] **用户适应**: 提供清晰的界面变更说明和引导
- [ ] **回滚准备**: 如有重大问题可快速回滚到原版本

---

**设计文档版本**: v2.0 (集成完整组件规范)
**最后更新**: 2025-10-06
**状态**: 详细设计完成，准备实施

此版本集成了所有组件的详细规范、交互流程、后端集成模式和响应式设计要求。文档现在提供了从概念设计到具体实施的完整指导，确保开发团队能够按照统一标准实现高质量的项目优先UI架构。