import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../pages/daily_plan/daily_plan_page.dart';
import '../pages/shooting/shooting_page.dart';
import '../pages/memo/memo_page.dart';
import '../pages/study/study_page.dart';
import '../pages/fitness/fitness_page.dart';
import '../pages/savings/savings_page.dart';
import '../pages/accounting/accounting_page.dart';
import '../pages/not_found/not_found_page.dart';
import '../pages/login/login_page.dart';
import '../core/services/auth_service.dart';
import '../core/services/credential_storage.dart';
import '../core/services/sync_service.dart';
import '../core/providers/providers.dart';

class AppLayout extends ConsumerStatefulWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  bool _sidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _pageSyncDebounce;
  String _lastLocation = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageSyncDebounce?.cancel();
    super.dispose();
  }

  /// 进入主界面 / 切换页面时触发一次全量同步（1 秒防抖合并连续切页）
  void _schedulePageSync() {
    _pageSyncDebounce?.cancel();
    _pageSyncDebounce = Timer(const Duration(seconds: 1), _autoSync);
  }

  /// 自动同步（进入主界面、切换页面时触发）
  /// 注意：不应用 30 秒节流——30 秒间隔只对手动同步按钮生效
  Future<void> _autoSync() async {
    try {
      final storage = await ref.read(credentialStorageProvider.future);
      if (!storage.isLoggedIn) return;

      final state = ref.read(syncStatusProvider);
      if (state.isSyncing) return;

      await _runSync();
    } catch (e) {
      debugPrint('页面切换自动同步异常: $e');
    }
  }

  /// 执行一次全量同步并更新同步状态
  Future<void> _runSync() async {
    final notifier = ref.read(syncStatusProvider.notifier);
    notifier.setSyncing();

    try {
      final syncService = await ref.read(syncServiceProvider.future);
      final result = await syncService.fullSync();

      switch (result.status) {
        case SyncStatus.success:
          notifier.setSuccess('同步完成');
          break;
        case SyncStatus.conflict:
          notifier.setConflict(result.message ?? '数据冲突');
          break;
        case SyncStatus.failed:
          notifier.setFailed(result.message ?? '同步失败');
          break;
        default:
          notifier.setIdle();
      }

      if (result.status == SyncStatus.success) {
        // 数据可能已更新，刷新所有页面数据
        ref.read(dataVersionProvider.notifier).state++;
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) notifier.setIdle();
        });
      }
    } catch (e) {
      notifier.setFailed('同步异常: $e');
    }
  }

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  Future<void> _logout() async {
    final authService = await ref.read(authServiceProvider.future);
    await authService.logout();
    ref.invalidate(credentialStorageProvider);
    ref.invalidate(isLoggedInProvider);
    if (mounted) {
      context.go('/login');
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${now.year}年${now.month}月${now.day}日 ${weekdays[now.weekday]}';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    // 路由变化（含进入主界面、切换页面）时触发一次自动同步
    if (location != _lastLocation) {
      _lastLocation = location;
      _schedulePageSync();
    }

    final effectivePath = location.startsWith('/shooting') ? '/shooting' :
        location.startsWith('/memo') ? '/memo' :
        location.startsWith('/study') ? '/study' :
        location.startsWith('/fitness') ? '/fitness' :
        location.startsWith('/savings') ? '/savings' :
        location.startsWith('/accounting') ? '/accounting' :
        location.startsWith('/daily-plan') ? '/daily-plan' : location;

    // 自适应界面：竖屏（宽 < 高）显示移动界面；
    // 横屏或正方形折叠屏（宽 >= 高）显示桌面界面
    final size = MediaQuery.sizeOf(context);
    final isPortrait = size.width < size.height;

    return isPortrait
        ? _buildMobileLayout(effectivePath)
        : _buildDesktopLayout(effectivePath);
  }

  /// 桌面布局：侧边栏 + 顶栏 + 内容区
  Widget _buildDesktopLayout(String effectivePath) {
    final username = ref.watch(usernameProvider).valueOrNull ?? '用户';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(username, effectivePath),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(username),
                  Expanded(child: _buildContent(effectivePath, isMobile: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 移动布局：顶部栏 + 内容区 + Drawer 抽屉导航
  Widget _buildMobileLayout(String effectivePath) {
    final username = ref.watch(usernameProvider).valueOrNull ?? '用户';

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildMobileDrawer(username, effectivePath),
      body: SafeArea(
        child: Column(
          children: [
            _buildMobileHeader(username),
            Expanded(child: _buildContent(effectivePath, isMobile: true)),
          ],
        ),
      ),
    );
  }

  /// 页面内容区（带页面切换进场动画）
  ///
  /// 注意：不能用 AnimatedSwitcher 包裹 navigationShell——
  /// StatefulShellRoute 内部带 GlobalKey，切换动画期间新旧 child 并存
  /// 会导致 "Duplicate GlobalKey (StatefulNavigationShellState)"。
  /// 这里用 TweenAnimationBuilder（仅进场动画），树中始终只有一份 navigationShell。
  Widget _buildContent(String effectivePath, {required bool isMobile}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(effectivePath),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 0.02 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 24,
          isMobile ? 12 : 24,
          isMobile ? 12 : 24,
          24,
        ),
        child: widget.child,
      ),
    );
  }

  List<_NavItem> get _navItems => [
    _NavItem(path: '/daily-plan', label: '每日计划', icon: const Text('📋', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/shooting', label: '拍摄相关', icon: const Text('💡', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/memo', label: '备忘录', icon: const Text('📝', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/study', label: '科研学习', icon: const Text('🌍', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/fitness', label: '健身打卡', icon: const Text('💪', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/savings', label: '存钱计划', icon: const Text('💰', style: TextStyle(fontSize: 16))),
    _NavItem(path: '/accounting', label: '每日记账', icon: const Text('🧾', style: TextStyle(fontSize: 16))),
  ];

  String _usernameInitial(String username) {
    if (username.isEmpty) return '用';
    return username.substring(0, 1).toUpperCase();
  }

  Widget _buildSidebar(String username, String effectivePath) {
    final items = _navItems;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _sidebarCollapsed ? 60 : 220,
      constraints: BoxConstraints(minWidth: _sidebarCollapsed ? 60 : 220, maxWidth: _sidebarCollapsed ? 60 : 220),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(username),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = item.path == effectivePath;
                return _buildNavItem(item, isActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String username) {
    final initial = _usernameInitial(username);
    return Container(
      padding: EdgeInsets.fromLTRB(_sidebarCollapsed ? 8 : 12, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: _sidebarCollapsed
          ? Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '生活工作台',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.sidebarForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$username 的专属空间',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isActive) {
    return _HoverNavItem(
      collapsed: _sidebarCollapsed,
      item: item,
      isActive: isActive,
      onTap: () {
        context.go(item.path);
      },
    );
  }

  Widget _buildHeader(String username) {
    final syncState = ref.watch(syncStatusProvider);
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _HoverIconButton(
            onTap: _toggleSidebar,
            child: const Icon(Icons.menu, size: 18, color: AppColors.foreground),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '$username · 生活工作台',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: syncState.status == SyncStatus.success
                  ? AppColors.emerald50
                  : AppColors.muted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  syncState.isSyncing ? Icons.sync : Icons.cloud_done,
                  size: 12,
                  color: syncState.isSyncing
                      ? AppColors.primary
                      : (syncState.status == SyncStatus.success
                          ? AppColors.success
                          : AppColors.mutedForeground),
                ),
                const SizedBox(width: 4),
                Text(
                  syncState.isSyncing
                      ? '正在同步...'
                      : (syncState.status == SyncStatus.success ? '同步完成' : '云端同步'),
                  style: TextStyle(
                    fontSize: 11,
                    color: syncState.isSyncing
                        ? AppColors.primary
                        : (syncState.status == SyncStatus.success
                            ? AppColors.success
                            : AppColors.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 同步状态提示
          if (syncState.status == SyncStatus.failed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: AppColors.destructive),
                    const SizedBox(width: 4),
                    Text(
                      syncState.message ?? '同步失败',
                      style: const TextStyle(fontSize: 11, color: AppColors.destructive),
                    ),
                  ],
                ),
              ),
            ),
          if (syncState.status == SyncStatus.conflict)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      syncState.message ?? '数据冲突',
                      style: TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),
          // 手动同步按钮
          if (!syncState.isSyncing)
            IconButton(
              onPressed: _startSync,
              icon: Icon(
                Icons.sync,
                size: 18,
                color: syncState.pendingRecords > 0 ? AppColors.primary : AppColors.mutedForeground,
              ),
              tooltip: '立即同步',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (syncState.isSyncing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            _getTodayDate(),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: AppColors.mutedForeground),
            tooltip: '退出登录',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// 移动端顶部栏：头像 + 用户名 + 同步状态/按钮 + 退出
  Widget _buildMobileHeader(String username) {
    final syncState = ref.watch(syncStatusProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _mobileScaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, size: 20, color: AppColors.foreground),
            tooltip: '打开菜单',
            visualDensity: VisualDensity.compact,
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
              ),
            ),
            child: Center(
              child: Text(
                _usernameInitial(username),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$username · 生活工作台',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getTodayDate(),
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: syncState.status == SyncStatus.success
                  ? AppColors.emerald50
                  : AppColors.muted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  syncState.isSyncing ? Icons.sync : Icons.cloud_done,
                  size: 11,
                  color: syncState.isSyncing
                      ? AppColors.primary
                      : (syncState.status == SyncStatus.success
                          ? AppColors.success
                          : AppColors.mutedForeground),
                ),
                const SizedBox(width: 3),
                Text(
                  syncState.isSyncing
                      ? '正在同步...'
                      : (syncState.status == SyncStatus.success ? '同步完成' : '云端同步'),
                  style: TextStyle(
                    fontSize: 10,
                    color: syncState.isSyncing
                        ? AppColors.primary
                        : (syncState.status == SyncStatus.success
                            ? AppColors.success
                            : AppColors.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          if (!syncState.isSyncing)
            IconButton(
              onPressed: _startSync,
              icon: Icon(
                Icons.sync,
                size: 18,
                color: syncState.pendingRecords > 0 ? AppColors.primary : AppColors.mutedForeground,
              ),
              tooltip: '立即同步',
              visualDensity: VisualDensity.compact,
            ),
          if (syncState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: AppColors.mutedForeground),
            tooltip: '退出登录',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// 移动端 Drawer 抽屉导航：头部（头像 + 用户名）+ 7 个主菜单
  Widget _buildMobileDrawer(String username, String effectivePath) {
    final items = _navItems;

    return Drawer(
      width: 264,
      backgroundColor: AppColors.sidebar,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _usernameInitial(username),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$username · 生活工作台',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.sidebarForeground),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$username 的专属空间',
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in items) _buildMobileDrawerItem(item, effectivePath),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Drawer 中的单个菜单项
  Widget _buildMobileDrawerItem(_NavItem item, String effectivePath) {
    final selected = effectivePath == item.path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            _mobileScaffoldKey.currentState?.closeDrawer();
            context.go(item.path);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(width: 24, child: Center(child: item.icon)),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? AppColors.primary : AppColors.sidebarForeground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startSync() async {
    final syncState = ref.read(syncStatusProvider);
    if (syncState.isSyncing) return;

    // 30 秒间隔保护：仅对手动同步按钮生效，间隔内点击给出剩余秒数提醒
    final lastSync = syncState.lastSyncTime;
    if (lastSync != null) {
      final elapsed = DateTime.now().difference(lastSync).inSeconds;
      if (elapsed < 30) {
        _showSyncCooldownHint(30 - elapsed);
        return;
      }
    }

    await _runSync();
  }

  /// 显示 30 秒同步间隔保护提醒
  void _showSyncCooldownHint(int remainingSeconds) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('30秒间隔防止过多刷新，还剩 $remainingSeconds 秒后可再次同步'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HoverNavItem extends StatefulWidget {
  final bool collapsed;
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverNavItem({
    required this.collapsed,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isActive = widget.isActive;
    final collapsed = widget.collapsed;

    return Tooltip(
      message: collapsed ? item.label : '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _isHovered ? 3.0 : 0.0,
              _isPressed ? 1.0 : 0.0,
              0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        AppColors.sidebarAccent.withValues(alpha: 1.0),
                        AppColors.sky100.withValues(alpha: _isHovered ? 0.8 : 0.5),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : (_isHovered
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFF1F5F9).withValues(alpha: 0.0),
                            const Color(0xFFE0F2FE).withValues(alpha: 0.6),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null),
              color: !isActive && !_isHovered
                  ? Colors.transparent
                  : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isHovered && !isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 16,
                        color: isActive
                            ? AppColors.sidebarAccentForeground
                            : (_isHovered
                                ? AppColors.primary
                                : AppColors.sidebarForeground),
                      ),
                      child: item.icon,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.sidebarAccentForeground
                            : (_isHovered
                                ? AppColors.primary
                                : AppColors.sidebarForeground),
                      ),
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverIconButton({required this.onTap, required this.child});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.92 : 1.0,
            _isPressed ? 0.92 : 1.0,
            1.0,
          ),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.accent
                : AppColors.secondary,
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final Widget icon;
  const _NavItem({required this.path, required this.label, required this.icon});
}

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('s3_logged_in') ?? false;
    final isLoginRoute = state.uri.path == '/login';
    if (!loggedIn && !isLoginRoute) return '/login';
    if (loggedIn && isLoginRoute) return '/daily-plan';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (_, _) => const NoTransitionPage(child: LoginPage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppLayout(child: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/daily-plan',
              pageBuilder: (_, _) => const NoTransitionPage(child: DailyPlanPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shooting',
              pageBuilder: (_, _) => const NoTransitionPage(child: ShootingPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/memo',
              pageBuilder: (_, _) => const NoTransitionPage(child: MemoPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/study',
              pageBuilder: (_, _) => const NoTransitionPage(child: StudyPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fitness',
              pageBuilder: (_, _) => const NoTransitionPage(child: FitnessPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/savings',
              pageBuilder: (_, _) => const NoTransitionPage(child: SavingsPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounting',
              pageBuilder: (_, _) => const NoTransitionPage(child: AccountingPage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/404',
      pageBuilder: (_, _) => const NoTransitionPage(child: NotFoundPage()),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
);
