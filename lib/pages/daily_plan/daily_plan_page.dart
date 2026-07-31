import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_checkbox.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/device_info.dart';

class DailyPlanPage extends ConsumerStatefulWidget {
  const DailyPlanPage({super.key});

  @override
  ConsumerState<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends ConsumerState<DailyPlanPage> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  (String, String) _weekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return (fmt(startOfWeek), fmt(endOfWeek));
  }

  @override
  Widget build(BuildContext context) {
    final today = _today();
    final weekRange = _weekRange();
    final todosAsync = ref.watch(todosByDateProvider(today));
    final weekTodosAsync = ref.watch(todosWeekRangeProvider(weekRange));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatsRow(weekTodosAsync, todosAsync),
        const SizedBox(height: 16),
        _buildAddTodo(today),
        const SizedBox(height: 16),
        _buildTodoList(todosAsync, today),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<Todo>> weekTodosAsync,
    AsyncValue<List<Todo>> todayTodosAsync,
  ) {
    int weekTotal = 0, weekDone = 0;
    int todayPending = 0, todayDone = 0;

    weekTodosAsync.whenData((list) {
      weekTotal = list.length;
      weekDone = list.where((t) => t.done).length;
    });
    todayTodosAsync.whenData((list) {
      todayPending = list.where((t) => !t.done).length;
      todayDone = list.where((t) => t.done).length;
    });

    final pct = weekTotal == 0 ? 0.0 : weekDone / weekTotal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final weekCard = AppCard(
          header: const AppCardHeader(
            title: AppCardTitle(child: Text('📋 本周进度')),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$weekDone / $weekTotal',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.foreground),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '本周完成 / 总数',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '完成率',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final overviewCard = AppCard(
          header: const AppCardHeader(
            title: AppCardTitle(child: Text('今日概览')),
          ),
          child: Column(
            children: [
              _buildOverviewRow('待完成', '$todayPending 项', AppColors.foreground),
              const SizedBox(height: 8),
              _buildOverviewRow('已完成', '$todayDone 项', AppColors.success),
              const SizedBox(height: 8),
              _buildOverviewRow('日期', _today(), AppColors.foreground),
            ],
          ),
        );

        // 窄屏（移动端竖屏）一行一个卡片
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              weekCard,
              const SizedBox(height: 12),
              overviewCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: weekCard),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: overviewCard),
          ],
        );
      },
    );
  }

  Widget _buildOverviewRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }

  Widget _buildAddTodo(String today) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: AppInput(
              controller: _inputController,
              hintText: '添加新的待办事项，回车确认...',
              onSubmitted: () => _addTodo(today),
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            onPressed: () => _addTodo(today),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 6),
                Text('添加'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(AsyncValue<List<Todo>> todosAsync, String today) {
    return todosAsync.when(
      loading: () => const AppCard(
        child: Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (e, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('加载失败: $e', style: const TextStyle(color: AppColors.destructive)),
        ),
      ),
      data: (list) {
        final pending = list.where((t) => !t.done).toList();
        final done = list.where((t) => t.done).toList();
        return AppCard(
          header: const AppCardHeader(
            title: AppCardTitle(child: Text('今日待办')),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done.isNotEmpty) ...[
                _buildDoneSection(done, today),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
              ],
              // 今天还没做完的事情显示在最下面
              _buildPendingSection(pending, today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingSection(List<Todo> pending, String today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '还未做完的事情 (${pending.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '暂无待办，添加一个吧 ✨',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          )
        else
          ...pending.map((todo) => _buildTodoItem(todo, today)),
      ],
    );
  }

  Widget _buildDoneSection(List<Todo> done, String today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              '已完成 (${done.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...done.map((todo) => _buildTodoItem(todo, today)),
      ],
    );
  }

  Widget _buildTodoItem(Todo todo, String today) {
    final isDone = todo.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.muted.withValues(alpha: 0.2) : AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? AppColors.border.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          AppCheckbox(
            value: isDone,
            onChanged: (bool? value) => _toggleTodo(todo, today, value ?? false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDone ? AppColors.mutedForeground : AppColors.foreground,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                // 未完成事项：显示创建日期和已逾期天数
                if (!isDone) ...[
                  const SizedBox(height: 4),
                  Text(
                    _buildOverdueText(todo),
                    style: TextStyle(
                      fontSize: 12,
                      color: _overdueDays(todo) > 0 ? AppColors.warning : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deleteTodo(todo.id, today),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 待办创建日期到今天已逾期多少天（今天创建的为 0 天）
  int _overdueDays(Todo todo) {
    final created = DateTime.fromMillisecondsSinceEpoch(todo.createdAt);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(created.year, created.month, created.day))
        .inDays;
  }

  /// 未完成事项的创建日期 + 逾期天数文案
  String _buildOverdueText(Todo todo) {
    final created = DateTime.fromMillisecondsSinceEpoch(todo.createdAt);
    final dateStr =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    return '创建于 $dateStr · 逾期 ${_overdueDays(todo)} 天';
  }

  Future<void> _addTodo(String today) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final now = DeviceInfo.nowTimestamp();
    final repo = ref.read(todosRepoProvider);
    final deviceId = await DeviceInfo.getDeviceId();
    await repo.insert(Todo(
      id: const Uuid().v4(),
      text: text,
      done: false,
      date: today,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _inputController.clear();
    if (mounted) {
      ref.invalidate(todosByDateProvider(today));
      ref.invalidate(todosWeekRangeProvider(_weekRange()));
    }
  }

  Future<void> _toggleTodo(Todo todo, String today, bool done) async {
    final repo = ref.read(todosRepoProvider);
    await repo.update(todo.copyWith(
      done: done,
      updatedAt: DeviceInfo.nowTimestamp(),
      synced: false,
    ));
    if (mounted) {
      ref.invalidate(todosByDateProvider(today));
      ref.invalidate(todosWeekRangeProvider(_weekRange()));
    }
  }

  Future<void> _deleteTodo(String id, String today) async {
    final repo = ref.read(todosRepoProvider);
    await repo.delete(id);
    if (mounted) {
      ref.invalidate(todosByDateProvider(today));
      ref.invalidate(todosWeekRangeProvider(_weekRange()));
    }
  }
}
