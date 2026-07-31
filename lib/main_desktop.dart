import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'layout/app_layout.dart';
import 'core/services/sync_service.dart';
import 'core/services/credential_storage.dart';
import 'core/services/connectivity_service.dart';
import 'core/utils/sync_trigger.dart';
import 'core/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Color(0xFFF8FAFC),
    title: '生活工作台',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: ShiningPersonalApp()));
}

class ShiningPersonalApp extends StatefulWidget {
  const ShiningPersonalApp({super.key});

  @override
  State<ShiningPersonalApp> createState() => _ShiningPersonalAppState();
}

class _ShiningPersonalAppState extends State<ShiningPersonalApp> with WindowListener {
  Timer? _changeSyncDebounce;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initConnectivity();
    _initSync();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _changeSyncDebounce?.cancel();
    SyncTrigger.onDataChanged = null;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initConnectivity() {
    // 监听网络状态变化
    Future.microtask(() async {
      if (!mounted) return;
      try {
        final container = ProviderScope.containerOf(context);
        final service = await container.read(connectivityServiceProvider.future);
        if (!mounted) return;
        
        _connectivitySubscription = Stream<bool>.periodic(
          const Duration(seconds: 5),
          (_) => service.isOnline,
        ).listen((isOnline) {
          _handleConnectivityChange(isOnline);
        });
      } catch (e) {
        debugPrint('网络服务初始化失败: $e');
      }
    });
  }

  void _handleConnectivityChange(bool isOnline) {
    if (isOnline && _wasOffline) {
      debugPrint('网络已恢复，触发自动同步');
      _networkRecoveredSync();
    }
    _wasOffline = !isOnline;
  }

  void _initSync() {
    // 数据变更（增删改）后自动触发一次防抖同步
    SyncTrigger.onDataChanged = _handleDataChanged;
  }

  /// 数据变更回调：3 秒防抖，合并连续操作后只同步一次
  void _handleDataChanged() {
    _changeSyncDebounce?.cancel();
    _changeSyncDebounce = Timer(const Duration(seconds: 3), _syncAfterDataChange);
  }

  /// 数据变更后的自动同步（仅防抖合并，不受 30 秒节流限制，
  /// 保证"添加数据后立即同步"）
  Future<void> _syncAfterDataChange() async {
    try {
      final container = ProviderScope.containerOf(context);
      final storage = await container.read(credentialStorageProvider.future);
      if (!storage.isLoggedIn) return;

      final state = container.read(syncStatusProvider);
      if (state.isSyncing) {
        // 正在同步中：稍后重试，避免遗漏最新变更
        _changeSyncDebounce?.cancel();
        _changeSyncDebounce = Timer(const Duration(seconds: 3), _syncAfterDataChange);
        return;
      }

      debugPrint('=== 数据变更后自动同步 ===');
      final notifier = container.read(syncStatusProvider.notifier);
      notifier.setSyncing();

      final syncService = await container.read(syncServiceProvider.future);
      final result = await syncService.fullSync();

      if (result.status == SyncStatus.success) {
        notifier.setSuccess('同步完成');
        // 数据可能已更新，刷新所有页面数据
        container.read(dataVersionProvider.notifier).state++;
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) notifier.setIdle();
        });
      } else if (result.status == SyncStatus.failed) {
        notifier.setFailed(result.message ?? '同步失败');
      }
    } catch (e) {
      debugPrint('数据变更同步异常: $e');
    }
  }

  Future<void> _networkRecoveredSync() async {
    try {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(syncStatusProvider.notifier);
      notifier.setSyncing();

      final syncService = await container.read(syncServiceProvider.future);
      final result = await syncService.fullSync();

      if (result.status == SyncStatus.success) {
        notifier.setSuccess('同步完成');
        // 数据可能已更新，刷新所有页面数据
        container.read(dataVersionProvider.notifier).state++;
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) notifier.setIdle();
        });
      } else if (result.status == SyncStatus.failed) {
        notifier.setFailed(result.message ?? '同步失败');
      } else if (result.status == SyncStatus.conflict) {
        notifier.setConflict(result.message ?? '数据冲突');
      }
    } catch (e) {
      debugPrint('网络恢复同步异常: $e');
    }
  }

  Future<void> _exitSync() async {
    try {
      final container = ProviderScope.containerOf(context);
      final storage = await container.read(credentialStorageProvider.future);
      if (!storage.isLoggedIn) return;

      debugPrint('=== 退出前全量同步（尽力而为） ===');
      final syncService = await container.read(syncServiceProvider.future);
      
      final result = await syncService.fullSync().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('退出同步超时，强制退出');
          return SyncResult(status: SyncStatus.failed, message: '超时');
        },
      );

      debugPrint('退出同步结果: ${result.status}');
    } catch (e) {
      debugPrint('退出同步异常（忽略）: $e');
    }
  }

  @override
  void onWindowClose() async {
    // 拦截窗口关闭事件，执行退出同步
    await _exitSync();
    // 允许窗口关闭
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '生活工作台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
