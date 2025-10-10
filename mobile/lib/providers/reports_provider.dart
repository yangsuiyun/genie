// Reports provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/report_service.dart';

// Report service provider
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

// Reports provider
final reportsProvider = FutureProvider<List<Report>>((ref) async {
  final reportService = ref.read(reportServiceProvider);
  return reportService.reports;
});

// Selected report provider
final selectedReportProvider = StateProvider<Report?>((ref) => null);

// Report filter provider
final reportFilterProvider = StateProvider<ReportFilter>((ref) => ReportFilter());

// Filtered reports provider
final filteredReportsProvider = Provider<List<Report>>((ref) {
  final reports = ref.watch(reportsProvider).value ?? [];
  final filter = ref.watch(reportFilterProvider);
  
  return reports.where((report) {
    if (filter.type != null && report.type != filter.type) return false;
    if (filter.startDate != null && report.createdAt.isBefore(filter.startDate!)) return false;
    if (filter.endDate != null && report.createdAt.isAfter(filter.endDate!)) return false;
    return true;
  }).toList();
});

// Report service class
class ReportService {
  List<Report> _reports = [];

  List<Report> get reports => _reports;

  void addReport(Report report) {
    _reports.add(report);
  }

  void updateReport(Report report) {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
    }
  }

  void deleteReport(String reportId) {
    _reports.removeWhere((r) => r.id == reportId);
  }
}

// Report filter class
class ReportFilter {
  final ReportType? type;
  final DateTime? startDate;
  final DateTime? endDate;

  ReportFilter({
    this.type,
    this.startDate,
    this.endDate,
  });

  ReportFilter copyWith({
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportFilter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Report model
class Report {
  final String id;
  final ReportType type;
  final String title;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  Report({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.data,
  });

  Report copyWith({
    String? id,
    ReportType? type,
    String? title,
    String? content,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

// Report type enum
enum ReportType {
  daily,
  weekly,
  monthly,
  custom,
}
