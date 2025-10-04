import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(SyncStatus.idle) {
    _initialize();
  }

  final SyncService _syncService = SyncService.instance;

  Future<void> _initialize() async {
    await _syncService.initialize();

    // Listen to sync status changes
    _syncService.statusStream.listen((status) {
      state = status;
    });
  }

  Future<SyncResult> sync({bool forceFullSync = false}) async {
    return await _syncService.sync(forceFullSync: forceFullSync);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _syncService.setAutoSyncEnabled(enabled);
  }

  Future<void> setSyncInterval(Duration interval) async {
    await _syncService.setSyncInterval(interval);
  }

  Future<void> setDefaultConflictResolution(ConflictResolution resolution) async {
    await _syncService.setDefaultConflictResolution(resolution);
  }

  void startPeriodicSync() {
    _syncService.startPeriodicSync();
  }

  void stopPeriodicSync() {
    _syncService.stopPeriodicSync();
  }

  Future<void> resolveConflictManually(
    String entityId,
    ConflictResolution resolution, {
    Map<String, dynamic>? customData,
  }) async {
    await _syncService.resolveConflictManually(entityId, resolution, customData: customData);
  }

  Future<List<SyncConflict>> getPendingConflicts() async {
    return await _syncService.getPendingConflicts();
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    return await _syncService.getSyncStats();
  }

  Future<void> clearSyncData() async {
    await _syncService.clearSyncData();
  }
}

class SyncResultNotifier extends StateNotifier<SyncResult?> {
  SyncResultNotifier() : super(null) {
    _initialize();
  }

  final SyncService _syncService = SyncService.instance;

  Future<void> _initialize() async {
    await _syncService.initialize();

    // Listen to sync result changes
    _syncService.resultStream.listen((result) {
      state = result;
    });
  }
}

class ConflictNotifier extends StateNotifier<AsyncValue<List<SyncConflict>>> {
  ConflictNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  final SyncService _syncService = SyncService.instance;

  Future<void> _initialize() async {
    await _syncService.initialize();
    await loadConflicts();
  }

  Future<void> loadConflicts() async {
    try {
      state = const AsyncValue.loading();
      final conflicts = await _syncService.getPendingConflicts();
      state = AsyncValue.data(conflicts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resolveConflict(
    String entityId,
    ConflictResolution resolution, {
    Map<String, dynamic>? customData,
  }) async {
    try {
      await _syncService.resolveConflictManually(entityId, resolution, customData: customData);
      await loadConflicts(); // Reload conflicts after resolution
    } catch (e) {
      // Handle error
    }
  }
}

// Provider definitions
final syncProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier();
});

final syncResultProvider = StateNotifierProvider<SyncResultNotifier, SyncResult?>((ref) {
  return SyncResultNotifier();
});

final conflictsProvider = StateNotifierProvider<ConflictNotifier, AsyncValue<List<SyncConflict>>>((ref) {
  return ConflictNotifier();
});

final lastSyncResultProvider = Provider<SyncResult?>((ref) {
  return ref.watch(syncResultProvider);
});

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider) == SyncStatus.syncing;
});

final syncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncProvider);
});

final pendingConflictsProvider = Provider<List<SyncConflict>>((ref) {
  return ref.watch(conflictsProvider).value ?? [];
});

final hasConflictsProvider = Provider<bool>((ref) {
  final conflicts = ref.watch(pendingConflictsProvider);
  return conflicts.isNotEmpty;
});

final syncStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final syncService = SyncService.instance;
  return await syncService.getSyncStats();
});