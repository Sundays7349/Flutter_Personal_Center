import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 网络状态服务
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final Function(bool isOnline) onConnectivityChanged;

  bool _isOnline = true;

  ConnectivityService(this._connectivity, this.onConnectivityChanged);

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // 检查当前状态
    final result = await _connectivity.checkConnectivity();
    _updateState(result);

    // 监听状态变化
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateState(results);
    });
  }

  void _updateState(List<ConnectivityResult> results) {
    final isOnline = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (isOnline != _isOnline) {
      _isOnline = isOnline;
      onConnectivityChanged(isOnline);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// 网络状态 Provider
final connectivityServiceProvider = FutureProvider<ConnectivityService>((ref) async {
  final service = ConnectivityService(
    Connectivity(),
    (isOnline) {
      debugPrint('网络状态变化: ${isOnline ? '在线' : '离线'}');
    },
  );
  await service.initialize();
  return service;
});

/// 当前是否在线的 Provider
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(connectivityServiceProvider.future);
  return service.isOnline;
});
