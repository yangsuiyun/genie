import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/task_list_view.dart';
import '../widgets/floating_task_bar.dart';
import '../widgets/top_toolbar.dart';
import 'timer/pomodoro_screen.dart';
import 'task_screen.dart';
import 'reports_screen.dart';
import 'settings/settings_screen.dart';
import '../screens/focus_mode_screen.dart';
import '../animations/page_transitions.dart';
import '../animations/micro_animations.dart';

// 主布局组件 - 替换原有的BottomNavigationBar结构
class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  TaskTimeFilter _selectedFilter = TaskTimeFilter.today;
  Task? _currentTask;
  bool _showSidebar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧边栏 (240px宽度)
          if (_showSidebar)
            SidebarNavigation(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
          
          // 主内容区
          Expanded(
            child: Column(
              children: [
                // 顶部工具栏
                TopToolbar(
                  onToggleSidebar: () {
                    setState(() => _showSidebar = !_showSidebar);
                  },
                  showSidebar: _showSidebar,
                ),
                
                // 统计卡片
                StatisticsCards(
                  filter: _selectedFilter,
                ),
                
                // 任务列表
                Expanded(
                  child: TaskListView(
                    filter: _selectedFilter,
                    onTaskSelected: (task) {
                      setState(() => _currentTask = task);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // 浮动操作栏
      floatingActionButton: FloatingTaskBar(
        currentTask: _currentTask,
        onStartFocus: () => _startFocusMode(),
        onTaskTap: () {
          setState(() => _currentTask = null);
        },
      ),
    );
  }

  void _startFocusMode() {
    if (_currentTask != null) {
      Navigator.of(context).push(
        FocusModeRoute(
          child: FocusModeScreen(task: _currentTask),
        ),
      );
    }
  }
}

// 响应式布局 - 根据屏幕尺寸调整布局
class ResponsiveMainLayout extends ConsumerStatefulWidget {
  const ResponsiveMainLayout({super.key});

  @override
  ConsumerState<ResponsiveMainLayout> createState() => _ResponsiveMainLayoutState();
}

class _ResponsiveMainLayoutState extends ConsumerState<ResponsiveMainLayout> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          // 桌面端布局
          return const MainLayout();
        } else if (constraints.maxWidth >= 768) {
          // 平板端布局 - 可折叠侧边栏
          return const MainLayout();
        } else {
          // 移动端布局 - 使用底部导航
          return const MobileMainLayout();
        }
      },
    );
  }
}

// 移动端布局 - 保留底部导航
class MobileMainLayout extends ConsumerStatefulWidget {
  const MobileMainLayout({super.key});

  @override
  ConsumerState<MobileMainLayout> createState() => _MobileMainLayoutState();
}

class _MobileMainLayoutState extends ConsumerState<MobileMainLayout> {
  int _selectedIndex = 0;
  TaskTimeFilter _selectedFilter = TaskTimeFilter.today;
  Task? _currentTask;

  final List<Widget> _screens = [
    const PomodoroScreen(),
    const TaskScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          
          // 移动端浮动操作栏
          if (_currentTask != null)
            Positioned(
              bottom: 80, // 在底部导航上方
              left: 16,
              right: 16,
              child: FloatingTaskBar(
                currentTask: _currentTask,
                onStartFocus: () => _startFocusMode(),
                onTaskTap: () {
                  setState(() => _currentTask = null);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: '番茄钟',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '报告',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  void _startFocusMode() {
    if (_currentTask != null) {
      Navigator.of(context).push(
        FocusModeRoute(
          child: FocusModeScreen(task: _currentTask),
        ),
      );
    }
  }
}

// 导入需要的屏幕组件
class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('番茄钟页面'));
  }
}

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('任务页面'));
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('报告页面'));
  }
}


