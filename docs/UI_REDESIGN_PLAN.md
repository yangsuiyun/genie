# 🎨 Pomodoro Genie UI/UX 重新设计方案

基于参考设计优化当前项目交互体验

最后更新: 2025-10-05

---

## 📋 设计目标

参考应用展示的核心设计理念：
1. **沉浸式专注体验** - 全屏计时器，最小化干扰
2. **清晰的信息架构** - 侧边栏时间维度分类
3. **快速任务启动** - 底部浮动操作栏
4. **数据可视化** - 统计卡片 + 时间轴视图
5. **环境辅助** - 白噪音 + 全屏模式

---

## 🎯 当前问题分析

### Flutter应用 (mobile/lib/main.dart)
❌ **问题1**: 底部导航占据屏幕空间，4个Tab平铺不够聚焦
❌ **问题2**: 番茄钟界面缺少全屏专注模式
❌ **问题3**: 任务列表没有时间维度分类（今天/明天/本周）
❌ **问题4**: 缺少时间轴记录视图
❌ **问题5**: 没有白噪音功能

### Web应用 (mobile/build/web/index.html)
❌ **问题1**: 4个Tab平铺在底部，移动端体验一般
❌ **问题2**: 番茄钟界面没有全屏模式
❌ **问题3**: 缺少侧边栏导航
❌ **问题4**: 统计数据展示不够直观（缺少顶部卡片）
❌ **问题5**: 没有时间轴视图

---

## 🏗️ 新架构设计

### 方案A: 双模式切换（推荐）

#### 模式1: 任务管理模式
```
┌──────────────────────────────────────────────┐
│  [≡] Pomodoro Genie      [🔔] [⚙️]          │ ← 顶部导航
├──────┬───────────────────────────────────────┤
│      │  Today                    🔥 0m / 5   │ ← 统计卡片区
│ 📅   │  ┌─────┬─────┬─────┬─────┐           │
│Today │  │ 0m  │  5  │ 0m  │  0  │           │
│ 0m 5 │  │预计 │待办 │已用 │完成 │           │
│      │  └─────┴─────┴─────┴─────┘           │
│ 📆   │                                        │
│Tomo  │  Tasks · 0m                           │
│ 0m 0 │  ○ ▶ bazel              🔴🔴  1 Oct  │ ← 任务列表
│      │  ○ ▶ genie                    1 Oct  │
│ 📊   │  ○ ▶ teleport审计             1 Oct  │
│Week  │  ○ ▶ teleport构建            12 Sep  │
│ 0m 3 │  ○ ▶ Cybertron规划           12 Sep  │
│      │                                        │
│ 📋   │  [+ Add a task to "Tasks"]            │
│Plan  │                                        │
│ 0m 5 │                                        │
│      │                                        │
│ ✓    │                                        │
│Done  │                                        │
│      │                                        │
├──────┴───────────────────────────────────────┤
│ [5] bazel 🌿                  [▶ Start]      │ ← 浮动操作栏
└──────────────────────────────────────────────┘
```

#### 模式2: 专注计时模式（全屏）
```
┌──────────────────────────────────────────────┐
│ [×]                            [⚙️]          │ ← 最小化控制
│                                              │
│              bazel                           │
│                                              │
│         ╭─────────────╮                     │
│         │             │                     │
│         │             │                     │
│         │   25:00     │                     │ ← 大圆形计时器
│         │             │                     │
│         │             │                     │
│         ╰─────────────╯                     │
│                                              │
│         [▶ Start to Focus]                  │
│                                              │
│  [⛶]    [⏱️]    [🎵]                       │ ← 控制栏
│ 全屏   计时器  白噪音                        │
│                                              │
│                                              │
│  ┌──────────────────────────┐              │
│  │ Focus Time of Today       │              │ ← 侧边栏（可折叠）
│  │                           │              │
│  │ Today                     │              │
│  │  ○ bazel                 │              │
│  │  ○ genie                 │              │
│  │  ○ teleport审计          │              │
│  │                           │              │
│  │ Today's Focus Records     │              │
│  │  17:00 ─────●────         │              │
│  │  18:00 ─────●────         │              │
│  └──────────────────────────┘              │
└──────────────────────────────────────────────┘
```

---

## 📱 详细功能设计

### 1. 侧边栏导航（任务管理模式）

**时间维度分类：**
```dart
enum TaskTimeFilter {
  today,      // 今天 - 显示今日到期或计划的任务
  tomorrow,   // 明天 - 显示明天到期的任务
  thisWeek,   // 本周 - 显示本周内的任务
  planned,    // 计划中 - 所有未完成任务
  completed,  // 已完成
  allTasks,   // 所有任务
}
```

**侧边栏项目显示：**
- 图标 + 标签名称
- 预计时间 (如：0m, 2h 30m)
- 任务数量 (如：5)
- 当前选中项高亮显示

**实现要点：**
```dart
class TaskSidebarItem {
  final IconData icon;
  final String label;
  final TaskTimeFilter filter;
  final int taskCount;
  final Duration estimatedTime;
  final Color? highlightColor;
}
```

---

### 2. 顶部统计卡片

**4个关键指标：**
```dart
class TodayStatistics {
  final Duration estimatedTime;   // 预计时间 (所有任务总计)
  final int tasksToComplete;      // 待完成任务数
  final Duration elapsedTime;     // 已用时间 (已完成番茄钟总时长)
  final int completedTasks;       // 已完成任务数
}
```

**卡片布局：**
```
┌──────┬──────┬──────┬──────┐
│  0m  │   5  │  0m  │   0  │
│ 预计 │ 待办 │ 已用 │ 完成 │
└──────┴──────┴──────┴──────┘
```

**颜色方案：**
- 预计时间: 蓝色 (#3498db)
- 待办任务: 橙色 (#ff9800)
- 已用时间: 绿色 (#4caf50)
- 完成任务: 紫色 (#9b59b6)

---

### 3. 浮动操作栏（底部）

**布局设计：**
```
┌────────────────────────────────────────┐
│ [5] bazel 🌿            [▶ Start]     │
└────────────────────────────────────────┘
  ↑          ↑                ↑
任务计数  当前任务名      快速启动按钮
```

**交互逻辑：**
- 显示当前选中任务
- 点击任务名 → 打开任务详情/切换任务
- 点击"Start" → 进入全屏专注模式
- 支持拖拽关闭（向下滑动）
- 黑色背景 + 圆角 + 阴影

**实现：**
```dart
class FloatingTaskBar extends StatelessWidget {
  final Task? currentTask;
  final VoidCallback onStartFocus;
  final VoidCallback onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
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
        child: Row(/* ... */),
      ),
    );
  }
}
```

---

### 4. 全屏专注模式

**进入方式：**
1. 点击底部浮动栏的"Start"按钮
2. 从番茄钟界面点击"全屏"按钮
3. 快捷键: F11 或 Cmd+Shift+F

**界面元素：**
- 顶部：最小化控制（关闭按钮 + 设置）
- 中央：大圆形计时器（280px → 400px）
- 当前任务名称（顶部显示）
- 背景：深色主题 + 装饰图案（可选）
- 底部：控制栏（全屏/计时器/白噪音）
- 右侧：可折叠侧边栏（今日任务 + 时间轴）

**退出方式：**
- 点击顶部关闭按钮
- 按Esc键
- 完成番茄钟后自动退出（可配置）

**动画效果：**
```dart
class FocusModeTransition extends PageRouteBuilder {
  FocusModeTransition({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        );
}
```

---

### 5. 白噪音功能

**音效类型：**
```dart
enum WhiteNoiseType {
  none,           // 无
  rain,           // 雨声
  ocean,          // 海浪
  forest,         // 森林
  cafe,           // 咖啡厅
  fireplace,      // 壁炉
  whitenoise,     // 白噪音
  brownnoise,     // 棕噪音
  pinknoise,      // 粉红噪音
}
```

**控制面板：**
```
┌────────────────────────────┐
│  White Noise               │
│                            │
│  [🌧️ Rain]    [🌊 Ocean]  │
│  [🌲 Forest]  [☕ Cafe]    │
│  [🔥 Fire]    [📻 White]   │
│                            │
│  Volume: ▓▓▓▓▓▓▓▓░░ 80%    │
│                            │
│  [Mix Sounds] [Timer Off]  │
└────────────────────────────┘
```

**实现方案：**
- 使用`audioplayers`包播放音频
- 支持音量调节（0-100%）
- 支持定时器（15/30/60分钟后自动停止）
- 支持混音（同时播放多个音效）
- 音频文件存储：`assets/sounds/whitenoise/`

```dart
class WhiteNoiseService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  WhiteNoiseType _currentType = WhiteNoiseType.none;
  double _volume = 0.8;

  Future<void> play(WhiteNoiseType type) async {
    final audioFile = _getAudioFile(type);
    await _audioPlayer.play(AssetSource(audioFile));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(_volume);
    _currentType = type;
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentType = WhiteNoiseType.none;
  }

  String _getAudioFile(WhiteNoiseType type) {
    switch (type) {
      case WhiteNoiseType.rain:
        return 'sounds/whitenoise/rain.mp3';
      case WhiteNoiseType.ocean:
        return 'sounds/whitenoise/ocean.mp3';
      // ... 其他音效
      default:
        return '';
    }
  }
}
```

---

### 6. 时间轴视图

**设计目标：**
- 可视化展示今日专注时间分布
- 显示每个时间段的番茄钟记录
- 快速识别高效时段

**布局：**
```
Today's Focus Time Records
─────────────────────────────
09:00 ─────────────────
10:00 ───●─────────────  bazel (25m)
11:00 ─────────────────
12:00 ─────────────────
13:00 ─────────────────
14:00 ─────────────────
15:00 ───●─────────────  genie (25m)
16:00 ───●───●─────────  genie (50m)
17:00 ───●─────────────  teleport (25m)
18:00 ─────────────────
```

**数据模型：**
```dart
class FocusTimeRecord {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final Task? associatedTask;
  final SessionType type; // work / shortBreak / longBreak

  int get hour => startTime.hour;

  String get timeDisplay =>
    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
}

class TimelineData {
  final List<FocusTimeRecord> records;

  // 按小时分组
  Map<int, List<FocusTimeRecord>> get recordsByHour {
    final map = <int, List<FocusTimeRecord>>{};
    for (var record in records) {
      final hour = record.hour;
      map.putIfAbsent(hour, () => []).add(record);
    }
    return map;
  }

  // 今日总时长
  Duration get totalFocusTime {
    return records.fold(
      Duration.zero,
      (sum, record) => sum + record.duration,
    );
  }
}
```

**UI组件：**
```dart
class TimelineView extends StatelessWidget {
  final TimelineData data;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 24, // 0-23小时
      itemBuilder: (context, hour) {
        final records = data.recordsByHour[hour] ?? [];
        return TimelineHourRow(
          hour: hour,
          records: records,
        );
      },
    );
  }
}

class TimelineHourRow extends StatelessWidget {
  final int hour;
  final List<FocusTimeRecord> records;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${hour.toString().padLeft(2, '0')}:00'),
        Expanded(
          child: Stack(
            children: [
              // 基准线
              Container(
                height: 2,
                color: Colors.grey.shade300,
              ),
              // 番茄钟标记点
              ...records.map((record) => Positioned(
                left: record.startTime.minute / 60 * MediaQuery.of(context).size.width,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )),
            ],
          ),
        ),
        // 任务名称（如果有）
        if (records.isNotEmpty)
          Text(
            records.first.associatedTask?.title ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }
}
```

---

### 7. 任务列表优化

**参考设计的特点：**
- 简洁的单行显示
- 左侧：勾选框 + 播放按钮
- 中间：任务名称
- 右侧：截止日期（红色表示过期）
- 紧急任务有红色标记（🔴🔴）

**新设计：**
```
○ ▶ bazel                    🔴🔴  1 Oct
│ │  └─ 任务名称               警告   截止日期
│ │
│ └─ 播放按钮（启动番茄钟）
└─ 勾选框（完成任务）
```

**实现优化：**
```dart
class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onStartPomodoro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // 勾选框
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
            shape: CircleBorder(),
          ),

          // 播放按钮
          IconButton(
            icon: Icon(Icons.play_circle_outline, color: Colors.red),
            onPressed: onStartPomodoro,
            iconSize: 20,
          ),

          // 任务名称
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              ),
            ),
          ),

          // 紧急标记
          if (task.priority == TaskPriority.urgent)
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.red),
                SizedBox(width: 2),
                Icon(Icons.circle, size: 8, color: Colors.red),
              ],
            ),

          SizedBox(width: 8),

          // 截止日期
          Text(
            _formatDueDate(task.dueDate),
            style: TextStyle(
              fontSize: 14,
              color: task.isOverdue ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff < 0) return '${date.day} ${_monthName(date.month)}';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${date.day} ${_monthName(date.month)}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
```

---

## 🎨 主题与配色

### 深色模式（专注模式推荐）
```dart
final darkTheme = ThemeData.dark().copyWith(
  primaryColor: Color(0xFFE74C3C), // 番茄红
  scaffoldBackgroundColor: Color(0xFF1A1A1A),
  cardColor: Color(0xFF2D2D2D),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFFE74C3C),
    secondary: Color(0xFF3498DB),
    surface: Color(0xFF2D2D2D),
    background: Color(0xFF1A1A1A),
  ),
);
```

### 浅色模式（任务管理推荐）
```dart
final lightTheme = ThemeData.light().copyWith(
  primaryColor: Color(0xFFE74C3C),
  scaffoldBackgroundColor: Color(0xFFFAFAFA),
  cardColor: Colors.white,
  colorScheme: ColorScheme.light(
    primary: Color(0xFFE74C3C),
    secondary: Color(0xFF3498DB),
    surface: Colors.white,
    background: Color(0xFFFAFAFA),
  ),
);
```

---

## 📐 响应式布局

### 移动端 (< 600px)
- 隐藏侧边栏，使用汉堡菜单
- 统计卡片2x2网格
- 浮动操作栏全宽

### 平板端 (600-1024px)
- 可折叠侧边栏
- 统计卡片1x4横向排列
- 专注模式居中显示

### 桌面端 (> 1024px)
- 固定侧边栏（240px宽）
- 统计卡片1x4横向排列
- 专注模式支持侧边栏（可折叠）

---

## 🚀 实施优先级

### Phase 1: 核心交互优化（Week 1）
1. ✅ 添加侧边栏导航（时间维度分类）
2. ✅ 实现顶部统计卡片
3. ✅ 添加底部浮动操作栏
4. ✅ 优化任务列表项样式

### Phase 2: 专注模式增强（Week 2）
1. ✅ 实现全屏专注模式
2. ✅ 添加白噪音功能
3. ✅ 实现模式切换动画
4. ✅ 添加可折叠侧边栏

### Phase 3: 数据可视化（Week 3）
1. ✅ 实现时间轴视图
2. ✅ 优化统计报告界面
3. ✅ 添加趋势图表
4. ✅ 实现数据导出功能

### Phase 4: 细节优化（Week 4）
1. ✅ 完善响应式布局
2. ✅ 添加快捷键支持
3. ✅ 优化动画效果
4. ✅ 性能优化

---

## 📝 设计规范

### 间距
- 最小间距: 4px
- 标准间距: 8px, 12px, 16px, 24px
- 大间距: 32px, 48px

### 圆角
- 小圆角: 4px
- 标准圆角: 8px
- 大圆角: 12px, 16px
- 圆形: 50%

### 阴影
```dart
// 轻阴影
BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 8,
  offset: Offset(0, 2),
)

// 中阴影
BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 16,
  offset: Offset(0, 4),
)

// 重阴影
BoxShadow(
  color: Colors.black.withOpacity(0.25),
  blurRadius: 24,
  offset: Offset(0, 8),
)
```

### 字体
- 标题: 20px / 24px / 28px (Bold)
- 正文: 14px / 16px (Regular)
- 辅助文字: 12px (Regular)
- 数据: 36px / 48px (Bold)

---

## 🔄 迁移策略

### Flutter应用迁移
1. 保留现有功能不变
2. 新增`FocusMode`全屏界面
3. 重构`MainScreen`添加侧边栏
4. 逐步替换现有Tab导航

### Web应用迁移
1. 创建新的`index_v2.html`
2. 复用现有localStorage逻辑
3. 添加响应式CSS媒体查询
4. AB测试新旧版本

### 数据兼容性
- 保持现有数据模型不变
- 新增字段使用默认值
- 提供迁移脚本（如需要）

---

## ✅ 验收标准

### 功能完整性
- [ ] 侧边栏导航正常工作
- [ ] 统计卡片数据准确
- [ ] 浮动操作栏交互流畅
- [ ] 全屏专注模式无Bug
- [ ] 白噪音播放稳定
- [ ] 时间轴显示正确

### 性能指标
- [ ] 页面加载 < 2秒
- [ ] 动画帧率 > 55 FPS
- [ ] 内存占用 < 150MB (Flutter)
- [ ] 响应时间 < 100ms

### 用户体验
- [ ] 界面美观、一致
- [ ] 交互流畅、直观
- [ ] 响应式布局完善
- [ ] 无明显Bug

---

## 📚 参考资源

- [Material Design 3 Guidelines](https://m3.material.io/)
- [Flutter Layout Cheat Sheet](https://flutter.dev/docs/development/ui/layout/tutorial)
- [Web Audio API Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- [Pomodoro Technique Best Practices](https://francescocirillo.com/pages/pomodoro-technique)

---

**下一步行动**: 开始实施Phase 1 - 核心交互优化
