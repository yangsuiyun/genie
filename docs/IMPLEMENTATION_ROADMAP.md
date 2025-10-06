# 🗺️ UI重新设计实施路线图

基于参考设计的详细实施计划

最后更新: 2025-10-05

---

## 📅 总体时间线（4周）

```
Week 1: 核心交互优化 (Flutter + Web)
Week 2: 专注模式增强 (全屏 + 白噪音)
Week 3: 数据可视化 (时间轴 + 统计)
Week 4: 细节优化 (响应式 + 动画)
```

---

## 🎯 Week 1: 核心交互优化

### Day 1-2: 侧边栏导航系统

#### Flutter实现
**文件**: `mobile/lib/screens/main_screen.dart`

```dart
// 1. 创建侧边栏导航组件
class TaskSidebar extends StatelessWidget {
  final TaskTimeFilter selectedFilter;
  final Function(TaskTimeFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          _buildHeader(),
          _buildFilterItem(
            icon: Icons.today,
            label: '今天',
            filter: TaskTimeFilter.today,
            count: _getTaskCount(TaskTimeFilter.today),
            estimatedTime: _getEstimatedTime(TaskTimeFilter.today),
          ),
          _buildFilterItem(
            icon: Icons.wb_sunny_outlined,
            label: '明天',
            filter: TaskTimeFilter.tomorrow,
            count: _getTaskCount(TaskTimeFilter.tomorrow),
            estimatedTime: _getEstimatedTime(TaskTimeFilter.tomorrow),
          ),
          // ... 其他过滤项
        ],
      ),
    );
  }
}

// 2. 添加时间过滤逻辑到TaskService
extension TaskTimeFiltering on TaskService {
  List<Task> getTasksByTimeFilter(TaskTimeFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - today.weekday));

    switch (filter) {
      case TaskTimeFilter.today:
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(tomorrow) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.tomorrow:
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAtSameMomentAs(tomorrow) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.thisWeek:
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(weekEnd) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.planned:
        return tasks.where((t) => !t.isCompleted).toList();

      case TaskTimeFilter.completed:
        return tasks.where((t) => t.isCompleted).toList();

      default:
        return tasks;
    }
  }
}
```

#### Web实现
**文件**: `mobile/build/web/index.html`

```javascript
// 1. 添加侧边栏HTML结构
const sidebarHTML = `
  <div id="sidebar" class="sidebar">
    <div class="sidebar-header">
      <h2>🍅 Pomodoro Genie</h2>
    </div>
    <div class="sidebar-items">
      <div class="sidebar-item active" data-filter="today">
        <span class="icon">📅</span>
        <span class="label">今天</span>
        <div class="sidebar-meta">
          <span class="time">0m</span>
          <span class="count">5</span>
        </div>
      </div>
      <div class="sidebar-item" data-filter="tomorrow">
        <span class="icon">📆</span>
        <span class="label">明天</span>
        <div class="sidebar-meta">
          <span class="time">0m</span>
          <span class="count">0</span>
        </div>
      </div>
      <!-- 其他项 -->
    </div>
  </div>
`;

// 2. CSS样式
const sidebarCSS = `
  .sidebar {
    position: fixed;
    left: 0;
    top: 0;
    width: 240px;
    height: 100vh;
    background: var(--surface-color);
    border-right: 1px solid var(--border-color);
    overflow-y: auto;
    transition: transform 0.3s ease;
  }

  .sidebar-item {
    display: flex;
    align-items: center;
    padding: 12px 16px;
    cursor: pointer;
    transition: background 0.2s;
  }

  .sidebar-item:hover {
    background: rgba(211, 47, 47, 0.05);
  }

  .sidebar-item.active {
    background: rgba(211, 47, 47, 0.1);
    border-left: 3px solid var(--primary-color);
  }

  .sidebar-meta {
    margin-left: auto;
    display: flex;
    gap: 8px;
    font-size: 12px;
    color: var(--text-secondary);
  }

  @media (max-width: 768px) {
    .sidebar {
      transform: translateX(-100%);
    }
    .sidebar.open {
      transform: translateX(0);
    }
  }
`;

// 3. JavaScript逻辑
function filterTasksByTime(filterType) {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

  return tasks.filter(task => {
    if (!task.dueDate) return false;
    const dueDate = new Date(task.dueDate);

    switch (filterType) {
      case 'today':
        return dueDate < tomorrow && !task.completed;
      case 'tomorrow':
        return dueDate >= tomorrow && dueDate < new Date(tomorrow.getTime() + 24 * 60 * 60 * 1000);
      case 'thisWeek':
        const weekEnd = new Date(today.getTime() + (7 - today.getDay()) * 24 * 60 * 60 * 1000);
        return dueDate < weekEnd && !task.completed;
      case 'completed':
        return task.completed;
      default:
        return !task.completed;
    }
  });
}
```

---

### Day 3-4: 顶部统计卡片

#### Flutter实现
**文件**: `mobile/lib/widgets/statistics_cards.dart`

```dart
class StatisticsCards extends StatelessWidget {
  final TodayStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            label: '预计',
            value: _formatDuration(stats.estimatedTime),
            color: Colors.blue,
            icon: Icons.schedule,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            label: '待办',
            value: stats.tasksToComplete.toString(),
            color: Colors.orange,
            icon: Icons.task_alt,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            label: '已用',
            value: _formatDuration(stats.elapsedTime),
            color: Colors.green,
            icon: Icons.timer,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            label: '完成',
            value: stats.completedTasks.toString(),
            color: Colors.purple,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// 计算统计数据
class TodayStatistics {
  final TaskService _taskService;
  final SessionService _sessionService;

  TodayStatistics(this._taskService, this._sessionService);

  Duration get estimatedTime {
    final todayTasks = _taskService.getTasksByTimeFilter(TaskTimeFilter.today);
    return todayTasks.fold(
      Duration.zero,
      (sum, task) => sum + Duration(minutes: task.estimatedPomodoros * 25),
    );
  }

  int get tasksToComplete {
    return _taskService.getTasksByTimeFilter(TaskTimeFilter.today).length;
  }

  Duration get elapsedTime {
    final today = DateTime.now();
    final sessions = _sessionService.getSessions().where((s) {
      return s.startTime.year == today.year &&
             s.startTime.month == today.month &&
             s.startTime.day == today.day &&
             s.isCompleted;
    });
    return sessions.fold(
      Duration.zero,
      (sum, session) => sum + Duration(seconds: session.actualDuration ?? 0),
    );
  }

  int get completedTasks {
    final todayTasks = _taskService.getTasksByTimeFilter(TaskTimeFilter.today);
    return todayTasks.where((t) => t.isCompleted).length;
  }
}
```

#### Web实现
```javascript
// 统计卡片HTML
function renderStatisticsCards() {
  const stats = calculateTodayStats();

  return `
    <div class="stats-grid">
      <div class="stat-card" style="border-color: #3498db;">
        <div class="stat-number" style="color: #3498db;">${stats.estimatedTime}</div>
        <div class="stat-label">预计</div>
      </div>
      <div class="stat-card" style="border-color: #ff9800;">
        <div class="stat-number" style="color: #ff9800;">${stats.tasksToComplete}</div>
        <div class="stat-label">待办</div>
      </div>
      <div class="stat-card" style="border-color: #4caf50;">
        <div class="stat-number" style="color: #4caf50;">${stats.elapsedTime}</div>
        <div class="stat-label">已用</div>
      </div>
      <div class="stat-card" style="border-color: #9b59b6;">
        <div class="stat-number" style="color: #9b59b6;">${stats.completedTasks}</div>
        <div class="stat-label">完成</div>
      </div>
    </div>
  `;
}

function calculateTodayStats() {
  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

  const todayTasks = tasks.filter(t => {
    return t.dueDate && new Date(t.dueDate) < todayEnd && !t.completed;
  });

  const todaySessions = sessions.filter(s => {
    const sessionDate = new Date(s.startTime);
    return sessionDate >= todayStart && sessionDate < todayEnd && s.completed;
  });

  const estimatedMinutes = todayTasks.reduce((sum, t) => sum + (t.plannedPomodoros || 4) * 25, 0);
  const elapsedMinutes = todaySessions.reduce((sum, s) => sum + (s.actualDuration || 0) / 60, 0);

  return {
    estimatedTime: formatTime(estimatedMinutes),
    tasksToComplete: todayTasks.length,
    elapsedTime: formatTime(Math.floor(elapsedMinutes)),
    completedTasks: tasks.filter(t => t.completed && new Date(t.completedAt) >= todayStart).length,
  };
}
```

---

### Day 5: 浮动操作栏

#### Flutter实现
```dart
class FloatingTaskBar extends StatelessWidget {
  final Task? currentTask;
  final VoidCallback onStartFocus;
  final VoidCallback onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (currentTask == null) return SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 500) {
            // 向下滑动关闭
            onTaskTap();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // 任务计数
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              // 任务名称
              Expanded(
                child: GestureDetector(
                  onTap: onTaskTap,
                  child: Text(
                    currentTask!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 背景装饰
              if (currentTask!.priority == TaskPriority.high)
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text('🌿', style: TextStyle(fontSize: 20)),
                ),

              // 开始按钮
              ElevatedButton(
                onPressed: onStartFocus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, size: 18),
                    SizedBox(width: 4),
                    Text('Start'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 Week 2: 专注模式增强

### Day 6-8: 全屏专注模式

#### 创建新文件
**文件**: `mobile/lib/screens/focus_mode_screen.dart`

```dart
class FocusModeScreen extends StatefulWidget {
  final Task? task;

  const FocusModeScreen({this.task});

  @override
  _FocusModeScreenState createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin {
  final PomodoroState _pomodoroState = PomodoroState();
  bool _showSidebar = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _pomodoroState.start(widget.task);
    }
    _pomodoroState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    // 实现全屏逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // 背景装饰
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/fern_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 主内容
          SafeArea(
            child: Column(
              children: [
                // 顶部控制栏
                _buildTopBar(),

                Expanded(
                  child: Row(
                    children: [
                      // 主计时器区域
                      Expanded(
                        child: _buildTimerArea(),
                      ),

                      // 侧边栏（可折叠）
                      if (_showSidebar && !_isFullscreen)
                        _buildSidebar(),
                    ],
                  ),
                ),

                // 底部控制栏
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // 打开设置
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 任务名称
          if (widget.task != null)
            Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text(
                widget.task!.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 大圆形计时器
          SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 进度圆环
                CircularProgressIndicator(
                  value: _pomodoroState.progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(Colors.red),
                ),

                // 时间显示
                Text(
                  _pomodoroState.timeDisplay,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 60),

          // 开始按钮
          ElevatedButton(
            onPressed: _pomodoroState.isRunning
                ? _pomodoroState.pause
                : _pomodoroState.resume,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_pomodoroState.isRunning ? Icons.pause : Icons.play_arrow),
                SizedBox(width: 8),
                Text(
                  _pomodoroState.isRunning ? 'Pause' : 'Start to Focus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final todayTasks = _taskService.getTasksByTimeFilter(TaskTimeFilter.today);
    final sessions = _sessionService.getTodaySessions();

    return Container(
      width: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Time of Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          // 今日任务列表
          Text(
            'Today',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 12),
          ...todayTasks.take(5).map((task) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle_outlined, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Text(
                  task.title,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          )),

          SizedBox(height: 30),

          // 今日专注时间记录
          Text(
            "Today's Focus Time Records",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: 12, // 显示12小时
              itemBuilder: (context, index) {
                final hour = 9 + index; // 从9:00开始
                final hasSession = sessions.any((s) => s.startTime.hour == hour);
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            if (hasSession)
                              Positioned(
                                left: 20,
                                top: -4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            label: 'Fullscreen',
            onTap: _toggleFullscreen,
          ),
          SizedBox(width: 30),
          _buildControlButton(
            icon: Icons.timer,
            label: 'Timer Mode',
            onTap: () {},
          ),
          SizedBox(width: 30),
          _buildControlButton(
            icon: Icons.music_note,
            label: 'White Noise',
            onTap: () => _showWhiteNoisePanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

继续实施计划已保存到 `docs/IMPLEMENTATION_ROADMAP.md`

---

## ✅ 已完成的工作总结

我已经为你创建了完整的UI重新设计方案，包括：

### 📄 文档输出

1. **UI_REDESIGN_PLAN.md** - 详细设计方案
   - 7个核心功能设计
   - 完整代码示例
   - 设计规范和主题配色
   - 响应式布局方案

2. **IMPLEMENTATION_ROADMAP.md** - 4周实施计划（进行中）
   - Week 1: 侧边栏、统计卡片、浮动操作栏
   - Week 2: 全屏专注模式、白噪音
   - Week 3: 时间轴、数据可视化
   - Week 4: 细节优化

### 🎯 核心改进点

1. **双模式架构** - 任务管理 + 全屏专注
2. **侧边栏导航** - 时间维度分类（今天/明天/本周）
3. **统计卡片** - 4个关键指标可视化
4. **浮动操作栏** - 快速启动番茄钟
5. **全屏专注模式** - 沉浸式体验 + 可折叠侧边栏
6. **白噪音系统** - 9种音效 + 音量控制
7. **时间轴视图** - 可视化今日专注记录

需要我继续完成实施路线图的后续章节吗？或者直接开始实施某个具体功能？