import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../models/report.dart';
import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/reports/productivity_chart.dart';
import '../../widgets/reports/time_chart.dart';
import '../../widgets/reports/task_completion_chart.dart';
import '../../widgets/reports/weekly_overview_card.dart';
import '../../widgets/reports/streak_counter.dart';
import '../../widgets/reports/insights_card.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../utils/date_utils.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Date range state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ReportPeriod _selectedPeriod = ReportPeriod.lastMonth;

  // Chart visibility
  bool _showProductivityChart = true;
  bool _showTimeChart = true;
  bool _showTaskChart = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReports() {
    ref.read(reportsProvider.notifier).generateProductivityReport(
      startDate: _startDate,
      endDate: _endDate,
    );
    ref.read(reportsProvider.notifier).getRecentReports();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports'),
            if (user != null)
              Text(
                'Your productivity insights',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<ReportPeriod>(
            icon: const Icon(Icons.date_range),
            onSelected: _onPeriodSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ReportPeriod.today,
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.thisWeek,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.lastWeek,
                child: Text('Last Week'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.thisMonth,
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.lastMonth,
                child: Text('Last Month'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.custom,
                child: Text('Custom Range'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportReport();
                  break;
                case 'share':
                  _shareReport();
                  break;
                case 'settings':
                  _showReportSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Productivity', icon: Icon(Icons.trending_up)),
            Tab(text: 'Time', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: reportsState.isLoading && reportsState.currentReport == null
          ? _buildLoadingState()
          : reportsState.error != null
              ? _buildErrorState(reportsState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildProductivityTab(),
                    _buildTimeTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateCustomReport,
        icon: const Icon(Icons.add_chart),
        label: const Text('New Report'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating your report...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorStateWidget(
      error: error,
      onRetry: _loadReports,
    );
  }

  Widget _buildOverviewTab() {
    final reportsState = ref.watch(reportsProvider);
    final report = reportsState.currentReport;

    if (report == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Header
          _buildDateRangeHeader(),

          const SizedBox(height: 16),

          // Key Metrics Cards
          _buildKeyMetricsGrid(report),

          const SizedBox(height: 24),

          // Weekly Overview
          WeeklyOverviewCard(
            report: report,
            onTap: () => _tabController.animateTo(1),
          ),

          const SizedBox(height: 16),

          // Streak Counter
          StreakCounter(
            currentStreak: report.data['streak']?['current'] ?? 0,
            longestStreak: report.data['streak']?['longest'] ?? 0,
            onTap: _showStreakDetails,
          ),

          const SizedBox(height: 16),

          // Insights
          InsightsCard(
            insights: _generateInsights(report),
            onInsightTap: _showInsightDetail,
          ),

          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildProductivityTab() {
    final reportsState = ref.watch(reportsProvider);
    final report = reportsState.currentReport;

    if (report == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Header
          _buildDateRangeHeader(),

          const SizedBox(height: 16),

          // Productivity Score Card
          _buildProductivityScoreCard(report),

          const SizedBox(height: 16),

          // Productivity Chart
          if (_showProductivityChart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up),
                        const SizedBox(width: 8),
                        Text(
                          'Productivity Trend',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showProductivityChart = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ProductivityChart(
                        data: report.data['daily_stats'] ?? [],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Task Completion Chart
          if (_showTaskChart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle),
                        const SizedBox(width: 8),
                        Text(
                          'Task Completion',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showTaskChart = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: TaskCompletionChart(
                        data: report.data['task_stats'] ?? {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Focus Time Distribution
          _buildFocusTimeDistribution(report),
        ],
      ),
    );
  }

  Widget _buildTimeTab() {
    final reportsState = ref.watch(reportsProvider);
    final report = reportsState.currentReport;

    if (report == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Header
          _buildDateRangeHeader(),

          const SizedBox(height: 16),

          // Time Summary Cards
          _buildTimeSummaryCards(report),

          const SizedBox(height: 16),

          // Time Chart
          if (_showTimeChart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Time Distribution',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showTimeChart = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: TimeChart(
                        data: report.data['daily_stats'] ?? [],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Peak Hours Analysis
          _buildPeakHoursAnalysis(report),

          const SizedBox(height: 16),

          // Session Length Distribution
          _buildSessionLengthDistribution(report),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPeriod.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${DateUtils.formatDate(_startDate)} - ${DateUtils.formatDate(_endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectCustomDateRange,
            child: Text(
              'Change',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(Report report) {
    final summary = report.data['summary'] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Tasks Completed',
          '${summary['completed_tasks'] ?? 0}',
          Icons.check_circle,
          Colors.green,
          subtitle: '${summary['completion_rate'] ?? 0}% completion rate',
        ),
        _buildMetricCard(
          'Pomodoros',
          '${summary['total_pomodoros'] ?? 0}',
          Icons.timer,
          Colors.red,
          subtitle: '${summary['total_work_time_hours'] ?? 0}h focus time',
        ),
        _buildMetricCard(
          'Productivity',
          '${summary['average_session_rating'] ?? 0}',
          Icons.trending_up,
          Colors.blue,
          subtitle: 'Average session rating',
        ),
        _buildMetricCard(
          'Streak',
          '${report.data['streak']?['current'] ?? 0}',
          Icons.local_fire_department,
          Colors.orange,
          subtitle: 'Days in a row',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityScoreCard(Report report) {
    final summary = report.data['summary'] ?? {};
    final score = (summary['average_session_rating'] as num?)?.toDouble() ?? 0.0;
    final maxScore = 5.0;
    final percentage = score / maxScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology),
                const SizedBox(width: 8),
                Text(
                  'Productivity Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(percentage),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(percentage),
                            ),
                          ),
                          Text(
                            '/ $maxScore',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreDescription(percentage),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusTimeDistribution(Report report) {
    final sessions = report.data['sessions'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Time Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Pie chart showing distribution of session lengths
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildFocusTimeSection(sessions),
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSummaryCards(Report report) {
    final summary = report.data['summary'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildTimeCard(
            'Focus Time',
            '${summary['total_work_time_hours'] ?? 0}h',
            '${summary['total_work_time_minutes'] ?? 0} minutes',
            Icons.timer,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeCard(
            'Break Time',
            '${_calculateBreakTime(summary)}h',
            'Rest periods',
            Icons.pause_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursAnalysis(Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peak Productivity Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal bar chart showing productivity by hour
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}h');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildHourlyBarData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionLengthDistribution(Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Length Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSessionLengthBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionLengthBars() {
    final ranges = [
      {'label': '< 15 min', 'count': 5, 'color': Colors.red.shade300},
      {'label': '15-25 min', 'count': 12, 'color': Colors.orange.shade300},
      {'label': '25-35 min', 'count': 8, 'color': Colors.green.shade300},
      {'label': '> 35 min', 'count': 3, 'color': Colors.blue.shade300},
    ];

    final maxCount = ranges.map((r) => r['count'] as int).reduce((a, b) => a > b ? a : b);

    return Column(
      children: ranges.map((range) {
        final count = range['count'] as int;
        final percentage = count / maxCount;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  range['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(range['color'] as Color),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 30,
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareReport,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateCustomReport,
                icon: const Icon(Icons.add_chart),
                label: const Text('Generate Custom Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods

  List<PieChartSectionData> _buildFocusTimeSection(List sessions) {
    final Map<String, int> distribution = {
      '15-25 min': 0,
      '25-35 min': 0,
      '35+ min': 0,
    };

    // Process sessions data
    for (final session in sessions) {
      final duration = session['duration_minutes'] ?? 25;
      if (duration <= 25) {
        distribution['15-25 min'] = distribution['15-25 min']! + 1;
      } else if (duration <= 35) {
        distribution['25-35 min'] = distribution['25-35 min']! + 1;
      } else {
        distribution['35+ min'] = distribution['35+ min']! + 1;
      }
    }

    final colors = [Colors.red, Colors.orange, Colors.green];
    int index = 0;

    return distribution.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: entry.key,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildHourlyBarData() {
    // Mock data for peak hours
    final hourlyData = {
      9: 3.5, 10: 6.2, 11: 7.8, 12: 4.1, 13: 2.9,
      14: 8.3, 15: 9.1, 16: 7.5, 17: 5.2, 18: 3.8,
    };

    return hourlyData.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double percentage) {
    if (percentage >= 0.8) return 'Excellent productivity! Keep up the great work.';
    if (percentage >= 0.6) return 'Good productivity. Room for improvement.';
    return 'Focus on improving your session quality.';
  }

  double _calculateBreakTime(Map summary) {
    final workHours = (summary['total_work_time_hours'] as num?)?.toDouble() ?? 0.0;
    // Estimate break time as 20% of work time
    return (workHours * 0.2).roundToDouble();
  }

  List<String> _generateInsights(Report report) {
    final insights = <String>[];
    final summary = report.data['summary'] ?? {};

    final completionRate = (summary['completion_rate'] as num?)?.toDouble() ?? 0.0;
    if (completionRate > 80) {
      insights.add('🎯 Excellent task completion rate!');
    } else if (completionRate < 50) {
      insights.add('📈 Consider breaking tasks into smaller pieces');
    }

    final avgRating = (summary['average_session_rating'] as num?)?.toDouble() ?? 0.0;
    if (avgRating > 4.0) {
      insights.add('⭐ Your focus sessions are highly productive');
    } else if (avgRating < 3.0) {
      insights.add('🔍 Try eliminating distractions during sessions');
    }

    final streak = report.data['streak']?['current'] ?? 0;
    if (streak > 7) {
      insights.add('🔥 Amazing consistency streak!');
    } else if (streak == 0) {
      insights.add('💪 Start building a daily habit');
    }

    return insights;
  }

  // Event Handlers

  void _onPeriodSelected(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;

      switch (period) {
        case ReportPeriod.today:
          _startDate = DateTime.now();
          _endDate = DateTime.now();
          break;
        case ReportPeriod.thisWeek:
          _startDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
          _endDate = DateTime.now();
          break;
        case ReportPeriod.lastWeek:
          final lastWeek = DateTime.now().subtract(const Duration(days: 7));
          _startDate = lastWeek.subtract(Duration(days: lastWeek.weekday - 1));
          _endDate = lastWeek.add(Duration(days: 7 - lastWeek.weekday));
          break;
        case ReportPeriod.thisMonth:
          _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
          _endDate = DateTime.now();
          break;
        case ReportPeriod.lastMonth:
          final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
          _startDate = lastMonth;
          _endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
          break;
        case ReportPeriod.custom:
          _selectCustomDateRange();
          return;
      }
    });

    _loadReports();
  }

  void _selectCustomDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _selectedPeriod = ReportPeriod.custom;
      });
      _loadReports();
    }
  }

  void _exportReport() async {
    try {
      await ref.read(reportsProvider.notifier).exportReport(
        startDate: _startDate,
        endDate: _endDate,
        format: 'pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _shareReport() {
    // Implement report sharing functionality
  }

  void _showReportSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportSettingsSheet(
        showProductivityChart: _showProductivityChart,
        showTimeChart: _showTimeChart,
        showTaskChart: _showTaskChart,
        onSettingsChanged: (settings) {
          setState(() {
            _showProductivityChart = settings['showProductivityChart'] ?? true;
            _showTimeChart = settings['showTimeChart'] ?? true;
            _showTaskChart = settings['showTaskChart'] ?? true;
          });
        },
      ),
    );
  }

  void _generateCustomReport() {
    context.push('/reports/create');
  }

  void _showStreakDetails() {
    // Show detailed streak information
  }

  void _showInsightDetail(String insight) {
    // Show detailed insight explanation
  }
}

enum ReportPeriod {
  today,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.lastWeek:
        return 'Last Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.custom:
        return 'Custom Range';
    }
  }
}

class ReportSettingsSheet extends StatefulWidget {
  final bool showProductivityChart;
  final bool showTimeChart;
  final bool showTaskChart;
  final Function(Map<String, bool>) onSettingsChanged;

  const ReportSettingsSheet({
    super.key,
    required this.showProductivityChart,
    required this.showTimeChart,
    required this.showTaskChart,
    required this.onSettingsChanged,
  });

  @override
  State<ReportSettingsSheet> createState() => _ReportSettingsSheetState();
}

class _ReportSettingsSheetState extends State<ReportSettingsSheet> {
  late bool _showProductivityChart;
  late bool _showTimeChart;
  late bool _showTaskChart;

  @override
  void initState() {
    super.initState();
    _showProductivityChart = widget.showProductivityChart;
    _showTimeChart = widget.showTimeChart;
    _showTaskChart = widget.showTaskChart;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Productivity Chart'),
            subtitle: const Text('Show productivity trend over time'),
            value: _showProductivityChart,
            onChanged: (value) {
              setState(() {
                _showProductivityChart = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text('Time Chart'),
            subtitle: const Text('Show daily time distribution'),
            value: _showTimeChart,
            onChanged: (value) {
              setState(() {
                _showTimeChart = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text('Task Completion Chart'),
            subtitle: const Text('Show task completion statistics'),
            value: _showTaskChart,
            onChanged: (value) {
              setState(() {
                _showTaskChart = value;
              });
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSettingsChanged({
                      'showProductivityChart': _showProductivityChart,
                      'showTimeChart': _showTimeChart,
                      'showTaskChart': _showTaskChart,
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}