import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/device_info.dart';
import '../repositories/todos_repository.dart';
import '../repositories/shooting_repository.dart';
import '../repositories/memo_repository.dart';
import '../repositories/study_repository.dart';
import '../repositories/fitness_repository.dart';
import '../repositories/savings_repository.dart';
import '../repositories/accounting_repository.dart';
import '../services/sync_service.dart';
import '../services/credential_storage.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final deviceIdProvider = FutureProvider<String>((ref) async {
  return await DeviceInfo.getDeviceId();
});

final todosRepoProvider = Provider<TodosRepository>((ref) {
  return TodosRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final shootingRepoProvider = Provider<ShootingRepository>((ref) {
  return ShootingRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final memoRepoProvider = Provider<MemoRepository>((ref) {
  return MemoRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final studyRepoProvider = Provider<StudyRepository>((ref) {
  return StudyRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final fitnessRepoProvider = Provider<FitnessRepository>((ref) {
  return FitnessRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final savingsRepoProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final accountingRepoProvider = Provider<AccountingRepository>((ref) {
  return AccountingRepository(
    ref.watch(appDatabaseProvider),
    DeviceInfo.getDeviceId,
  );
});

final todosByDateProvider = FutureProvider.family<List<Todo>, String>((ref, date) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(todosRepoProvider);
  return await repo.getByDate(date);
});

final todosWeekRangeProvider = FutureProvider.family<List<Todo>, (String, String)>((ref, range) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(todosRepoProvider);
  return await repo.getWeekRange(range.$1, range.$2);
});

final shootingProjectsProvider = FutureProvider<List<ShootingProject>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(shootingRepoProvider);
  return await repo.getAllProjects();
});

final shootingProjectsByDoneProvider = FutureProvider.family<List<ShootingProject>, bool>((ref, done) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(shootingRepoProvider);
  return await repo.getAllProjects(done: done);
});

final shootingIdeasProvider = FutureProvider<List<ShootingIdea>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(shootingRepoProvider);
  return await repo.getAllIdeas();
});

final memoNotesProvider = FutureProvider<List<MemoNote>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(memoRepoProvider);
  return await repo.getAllNotes();
});

final memoContactsProvider = FutureProvider<List<MemoContact>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(memoRepoProvider);
  return await repo.getAllContacts();
});

final memoShoppingsProvider = FutureProvider<List<MemoShopping>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(memoRepoProvider);
  return await repo.getAllShopping();
});

final studyPapersProvider = FutureProvider<List<StudyPaper>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(studyRepoProvider);
  return await repo.getAllPapers();
});

final studyExperimentsProvider = FutureProvider<List<StudyExperiment>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(studyRepoProvider);
  return await repo.getAllExperiments();
});

final studyEnglishProvider = FutureProvider<List<StudyEnglish>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(studyRepoProvider);
  return await repo.getAllEnglish();
});

final studyEnglishByDateProvider = FutureProvider.family<List<StudyEnglish>, String>((ref, date) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(studyRepoProvider);
  return await repo.getEnglishByDate(date);
});

final fitnessWorkoutsProvider = FutureProvider<List<FitnessWorkout>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getAllWorkouts();
});

final fitnessWorkoutsByDateProvider = FutureProvider.family<List<FitnessWorkout>, String>((ref, date) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getWorkoutsByDate(date);
});

final fitnessBodiesProvider = FutureProvider<List<FitnessBody>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getAllBodies();
});

final fitnessLatestBodyProvider = FutureProvider<FitnessBody?>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getLatestBody();
});

final fitnessDietsProvider = FutureProvider<List<FitnessDiet>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getAllDiets();
});

final fitnessDietsByDateProvider = FutureProvider.family<List<FitnessDiet>, String>((ref, date) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(fitnessRepoProvider);
  return await repo.getDietsByDate(date);
});

final savingsGoalProvider = FutureProvider<SavingsGoal?>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(savingsRepoProvider);
  return await repo.getGoal();
});

final savingsRecordsProvider = FutureProvider<List<SavingsRecord>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(savingsRepoProvider);
  return await repo.getAllRecords();
});

final savingsRecordsByMonthProvider = FutureProvider.family<List<SavingsRecord>, String>((ref, yyyyMm) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(savingsRepoProvider);
  return await repo.getRecordsByMonth(yyyyMm);
});

final savingsSubgoalsProvider = FutureProvider<List<SavingsSubgoal>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(savingsRepoProvider);
  return await repo.getAllSubgoals();
});

final accountingBudgetProvider = FutureProvider<AccountingBudget?>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(accountingRepoProvider);
  return await repo.getBudget();
});

final accountingRecordsProvider = FutureProvider<List<AccountingRecord>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(accountingRepoProvider);
  return await repo.getAllRecords();
});

final accountingRecordsByMonthProvider = FutureProvider.family<List<AccountingRecord>, String>((ref, yyyyMm) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(accountingRepoProvider);
  return await repo.getRecordsByMonth(yyyyMm);
});

final accountingRecordsByDateProvider = FutureProvider.family<List<AccountingRecord>, String>((ref, date) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(accountingRepoProvider);
  return await repo.getRecordsByDate(date);
});

final accountingRecordsByTypeProvider = FutureProvider.family<List<AccountingRecord>, String>((ref, type) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(accountingRepoProvider);
  return await repo.getRecordsByType(type);
});

// ============ 同步相关 Provider ============

/// 数据版本号：每次同步完成后自增，所有数据 Provider 监听它，
/// 以便云端数据覆盖本地后页面能立即刷新显示
final dataVersionProvider = StateProvider<int>((ref) => 0);

/// 同步服务 Provider
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final storage = await ref.watch(credentialStorageProvider.future);
  return SyncService(db, storage, DeviceInfo.getDeviceId);
});

/// 同步状态 Provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier();
});

class SyncStatusState {
  final SyncStatus status;
  final String? message;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingRecords;

  SyncStatusState({
    this.status = SyncStatus.idle,
    this.message,
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingRecords = 0,
  });

  SyncStatusState copyWith({
    SyncStatus? status,
    String? message,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingRecords,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      message: message ?? this.message,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingRecords: pendingRecords ?? this.pendingRecords,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(SyncStatusState());

  void setSyncing() {
    state = state.copyWith(status: SyncStatus.syncing, isSyncing: true, message: '同步中...');
  }

  void setSuccess(String message) {
    state = state.copyWith(
      status: SyncStatus.success,
      isSyncing: false,
      message: message,
      lastSyncTime: DateTime.now(),
    );
  }

  void setFailed(String message) {
    state = state.copyWith(status: SyncStatus.failed, isSyncing: false, message: message);
  }

  void setConflict(String message) {
    state = state.copyWith(status: SyncStatus.conflict, isSyncing: false, message: message);
  }

  void setOffline() {
    state = state.copyWith(status: SyncStatus.offline, isSyncing: false, message: '离线状态');
  }

  void setIdle() {
    state = state.copyWith(status: SyncStatus.idle, isSyncing: false, message: null);
  }

  void setPendingRecords(int count) {
    state = state.copyWith(pendingRecords: count);
  }
}
