import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import '../models/index.dart';

// Task Service Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// Session Service Provider  
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});