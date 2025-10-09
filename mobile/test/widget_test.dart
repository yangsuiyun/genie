import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_genie/main.dart';
import 'package:pomodoro_genie/screens/main_layout.dart';
import 'package:pomodoro_genie/widgets/sidebar_navigation.dart';
import 'package:pomodoro_genie/widgets/statistics_cards.dart';
import 'package:pomodoro_genie/widgets/task_list_view.dart';

void main() {
  group('MainLayout Tests', () {
    testWidgets('should display sidebar and main content', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainLayout(),
          ),
        ),
      );

      // 验证侧边栏存在
      expect(find.byType(SidebarNavigation), findsOneWidget);
      
      // 验证主内容区存在
      expect(find.byType(TaskListView), findsOneWidget);
      
      // 验证统计卡片存在
      expect(find.byType(StatisticsCards), findsOneWidget);
    });

    testWidgets('should switch filter when sidebar item tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainLayout(),
          ),
        ),
      );

      // 点击"明天"导航项
      await tester.tap(find.text('明天'));
      await tester.pump();

      // 验证任务列表更新
      expect(find.byType(TaskListView), findsOneWidget);
    });
  });

  group('ResponsiveMainLayout Tests', () {
    testWidgets('should use desktop layout for large screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResponsiveMainLayout(),
          ),
        ),
      );

      // 验证桌面布局组件存在
      expect(find.byType(MainLayout), findsOneWidget);
    });

    testWidgets('should use mobile layout for small screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResponsiveMainLayout(),
          ),
        ),
      );

      // 验证移动端布局组件存在
      expect(find.byType(MobileMainLayout), findsOneWidget);
    });
  });

  group('SidebarNavigation Tests', () {
    testWidgets('should display all filter options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SidebarNavigation(
                selectedFilter: TaskTimeFilter.today,
                onFilterChanged: null,
              ),
            ),
          ),
        ),
      );

      // 验证所有过滤选项存在
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('明天'), findsOneWidget);
      expect(find.text('本周'), findsOneWidget);
      expect(find.text('计划中'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
    });
  });

  group('StatisticsCards Tests', () {
    testWidgets('should display all stat cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatisticsCards(filter: TaskTimeFilter.today),
            ),
          ),
        ),
      );

      // 验证所有统计卡片存在
      expect(find.text('预计'), findsOneWidget);
      expect(find.text('待办'), findsOneWidget);
      expect(find.text('已用'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);
    });
  });
}

