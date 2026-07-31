import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/device_info.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_checkbox.dart';
import '../../widgets/app_date_picker.dart';

class SavingsPage extends ConsumerStatefulWidget {
  const SavingsPage({super.key});

  @override
  ConsumerState<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends ConsumerState<SavingsPage> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  final _subGoalNameController = TextEditingController();
  final _subGoalTargetController = TextEditingController();

  bool _editingGoal = false;
  final _totalGoalController = TextEditingController(text: '100000');
  final _monthlyGoalController = TextEditingController(text: '3000');

  /// 添加存款时选择的存入方式：'general' 表示计入总体，否则为小目标 id
  String _selectedSubgoal = 'general';

  @override
  void initState() {
    super.initState();
    _dateController.text = _today();
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs().toStringAsFixed(0);
    final formatted = abs.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m.group(1)},',
    );
    return '$sign¥$formatted';
  }

  List<double> _computeMonthlyTotals(List<SavingsRecord> records) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      months.add('${month.year}-${month.month.toString().padLeft(2, '0')}');
    }
    final totals = <double>[];
    for (final m in months) {
      // 计入小目标的款项不计入总体趋势
      final sum = records
          .where((r) => r.date.startsWith(m) && r.subgoalId == null)
          .fold(0.0, (sum, r) => sum + r.amount);
      totals.add(sum);
    }
    return totals;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _subGoalNameController.dispose();
    _subGoalTargetController.dispose();
    _totalGoalController.dispose();
    _monthlyGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(savingsGoalProvider);
    final recordsAsync = ref.watch(savingsRecordsProvider);
    final subgoalsAsync = ref.watch(savingsSubgoalsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGoalCard(goalAsync, recordsAsync),
        const SizedBox(height: 16),
        _buildMiddleRow(recordsAsync, subgoalsAsync),
        const SizedBox(height: 16),
        _buildSubGoals(subgoalsAsync),
        const SizedBox(height: 16),
        _buildRecords(recordsAsync, subgoalsAsync),
      ],
    );
  }

  Widget _buildGoalCard(
    AsyncValue<SavingsGoal?> goalAsync,
    AsyncValue<List<SavingsRecord>> recordsAsync,
  ) {
    double totalGoal = 100000;
    double monthlyGoal = 3000;
    double saved = 0;

    goalAsync.whenData((goal) {
      if (goal != null) {
        totalGoal = goal.totalGoal;
        monthlyGoal = goal.monthlyGoal;
        _totalGoalController.text = totalGoal.toStringAsFixed(0);
        _monthlyGoalController.text = monthlyGoal.toStringAsFixed(0);
      }
    });

    recordsAsync.whenData((records) {
      // 计入小目标的款项不计入总体已存金额
      saved = records
          .where((r) => r.subgoalId == null)
          .fold(0.0, (sum, r) => sum + r.amount);
    });

    final remaining = (totalGoal - saved).clamp(0.0, double.infinity);
    final progress = totalGoal > 0 ? (saved / totalGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF06B6D4)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.savings, size: 16, color: Colors.white70),
                          SizedBox(width: 6),
                          Text('存钱总目标',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_formatAmount(totalGoal),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                AppButton(
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  onPressed: () => setState(() => _editingGoal = !_editingGoal),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(_editingGoal ? '收起' : '编辑目标',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            if (_editingGoal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('总目标 (元)',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 4),
                              AppInput(
                                  controller: _totalGoalController,
                                  hintText: '总目标',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('月度目标 (元)',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 4),
                              AppInput(
                                  controller: _monthlyGoalController,
                                  hintText: '月度目标',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          variant: AppButtonVariant.ghost,
                          onPressed: () =>
                              setState(() => _editingGoal = false),
                          child: const Text('取消',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          onPressed: () async {
                            await _saveGoal(totalGoal, monthlyGoal);
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('已存金额',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(_formatAmount(saved),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('还差',
                        style:
                            TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(_formatAmount(remaining),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFDE68A)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('完成 ${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70)),
                Text('月度目标 ${_formatAmount(monthlyGoal)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleRow(
    AsyncValue<List<SavingsRecord>> recordsAsync,
    AsyncValue<List<SavingsSubgoal>> subgoalsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final addCard = _buildAddRecord(subgoalsAsync);
        final chartCard = _buildTrendChart(recordsAsync);
        // 窄屏（移动端竖屏）上下堆叠
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addCard,
              const SizedBox(height: 16),
              chartCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: addCard),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: chartCard),
          ],
        );
      },
    );
  }

  Widget _buildAddRecord(AsyncValue<List<SavingsSubgoal>> subgoalsAsync) {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('添加存款'),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInput(
              controller: _amountController,
              label: '金额 (元)',
              hintText: '存入金额',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppDatePickerFormField(
              controller: _dateController,
              label: '日期',
              hintText: '日期'),
          const SizedBox(height: 12),
          // 存入方式选择：计入总体 / 计入某个进行中的小目标
          subgoalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (subgoals) {
              final active = subgoals.where((s) => !s.completed).toList();
              return DropdownButtonFormField<String>(
                initialValue: _selectedSubgoal,
                decoration: InputDecoration(
                  labelText: '存入方式',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'general',
                    child: Text('计入总体'),
                  ),
                  for (final sg in active)
                    DropdownMenuItem(
                      value: sg.id,
                      child: Text('🎯 ${sg.name}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedSubgoal = v ?? 'general'),
              );
            },
          ),
          const SizedBox(height: 12),
          AppInput(
              controller: _noteController, label: '备注', hintText: '可选'),
          const SizedBox(height: 16),
          AppButton(
            onPressed: _insertRecord,
            width: double.infinity,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings, size: 16),
                SizedBox(width: 6),
                Text('存入'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AsyncValue<List<SavingsRecord>> recordsAsync) {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('储蓄趋势'),
            ],
          ),
        ),
      ),
      child: SizedBox(
        height: 300,
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('加载失败: $e',
                style: const TextStyle(color: AppColors.destructive)),
          ),
          data: (records) => _buildLineChart(records),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<SavingsRecord> records) {
    final totals = _computeMonthlyTotals(records);
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 0; i < 6; i++) {
      spots.add(FlSpot(i.toDouble(), totals[i]));
    }

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, _) {
                final month = DateTime(now.year, now.month - (5 - i.toInt()));
                return Text('${month.month}月',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.mutedForeground));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('¥${(v).toInt()}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
          ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildSubGoals(AsyncValue<List<SavingsSubgoal>> subgoalsAsync) {
    return AppCard(
      header: AppCardHeader(
        title: AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.flag, size: 16, color: Color(0xFF9333EA)),
              SizedBox(width: 8),
              Text('攒钱小目标'),
            ],
          ),
        ),
        trailing: AppButton(
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          onPressed: _showSubGoalDialog,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14),
              SizedBox(width: 4),
              Text('添加小目标'),
            ],
          ),
        ),
      ),
      child: subgoalsAsync.when(
        loading: () => const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('加载失败: $e',
              style: const TextStyle(color: AppColors.destructive)),
        ),
        data: (subgoals) {
          final active = subgoals.where((s) => !s.completed).toList();
          final done = subgoals.where((s) => s.completed).toList();
          if (subgoals.isEmpty) {
            return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('还没有小目标，添加一个吧 🎯',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.mutedForeground)));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进行中的小目标
              if (active.isNotEmpty) ...[
                const Text('进行中',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: active.map(_buildSubgoalCard).toList(),
                  ),
                ),
              ],
              // 已完成的小目标
              if (done.isNotEmpty) ...[
                if (active.isNotEmpty) const SizedBox(height: 20),
                const Text('已完成的小目标 🎉',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: done.map(_buildSubgoalCard).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 单个小目标卡片；已完成的显示完成标记，达标未完成时显示“完成”按钮
  Widget _buildSubgoalCard(SavingsSubgoal sg) {
    final isDone = sg.completed;
    final progress =
        sg.target > 0 ? (sg.current / sg.target).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.6)),
        color: isDone
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sg.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 2),
                    Text('已完成',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.success)),
                  ],
                )
              else if (sg.current >= sg.target)
                AppButton(
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  onPressed: () => _completeSubgoal(sg),
                  child: const Text('完成'),
                )
              else
                AppButton(
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  onPressed: () => _deleteSubgoal(sg.id),
                  child: const Text('删除'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_formatAmount(sg.current),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('/ ${_formatAmount(sg.target)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          AppProgress(value: progress),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
              isDone
                  ? const Text('已完成',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.success))
                  : Text(
                      '还差 ${_formatAmount((sg.target - sg.current).abs())}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecords(
    AsyncValue<List<SavingsRecord>> recordsAsync,
    AsyncValue<List<SavingsSubgoal>> subgoalsAsync,
  ) {
    return AppCard(
      header: const AppCardHeader(
        title: AppCardTitle(child: Text('存款记录')),
      ),
      child: recordsAsync.when(
        loading: () => const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        )),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('加载失败: $e',
              style: const TextStyle(color: AppColors.destructive)),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('暂无存款记录 💰',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.mutedForeground)));
          }
          // 小目标名称映射（用于标注计入小目标的记录）
          final subgoalNames = <String, String>{};
          subgoalsAsync.whenData((subgoals) {
            for (final s in subgoals) {
              subgoalNames[s.id] = s.name;
            }
          });
          return Column(
            children: records
                .map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.border.withValues(alpha: 0.6)),
                        color: AppColors.card,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(_formatAmount(r.amount),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                    '${r.date}${r.note != null && r.note!.isNotEmpty ? ' · ${r.note}' : ''}${r.subgoalId != null && subgoalNames[r.subgoalId] != null ? ' · 🎯 计入 ${subgoalNames[r.subgoalId]}' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppColors.mutedForeground)),
                              ],
                            ),
                          ),
                          AppButton(
                            variant: AppButtonVariant.destructive,
                            size: AppButtonSize.sm,
                            onPressed: () => _deleteRecord(r.id),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _saveGoal(double totalGoal, double monthlyGoal) async {
    final total = double.tryParse(_totalGoalController.text) ?? totalGoal;
    final monthly = double.tryParse(_monthlyGoalController.text) ?? monthlyGoal;
    final repo = ref.read(savingsRepoProvider);
    await repo.saveGoal(SavingsGoal(
      id: 1,
      totalGoal: total,
      monthlyGoal: monthly,
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      ref.invalidate(savingsGoalProvider);
      setState(() => _editingGoal = false);
    }
  }

  Future<void> _insertRecord() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    final repo = ref.read(savingsRepoProvider);

    // 解析存入方式：'general' 计入总体，否则计入指定小目标
    var targetSubgoalId = _selectedSubgoal == 'general' ? null : _selectedSubgoal;
    SavingsSubgoal? goal;
    if (targetSubgoalId != null) {
      final subgoals = await repo.getAllSubgoals();
      for (final s in subgoals) {
        if (s.id == targetSubgoalId) {
          goal = s;
          break;
        }
      }
      // 小目标不存在或已完成后，回退为计入总体
      if (goal == null || goal.completed) {
        targetSubgoalId = null;
        goal = null;
      }
    }

    await repo.insertRecord(SavingsRecord(
      id: const Uuid().v4(),
      amount: amount,
      date: _dateController.text.isEmpty ? _today() : _dateController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      subgoalId: targetSubgoalId,
      createdAt: DeviceInfo.nowTimestamp(),
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    // 计入小目标：同步增加该小目标的已存金额
    if (goal != null) {
      await repo.updateSubgoal(goal.copyWith(current: goal.current + amount));
    }
    if (mounted) {
      _amountController.clear();
      _noteController.clear();
      _selectedSubgoal = 'general';
      ref.invalidate(savingsRecordsProvider);
      ref.invalidate(savingsRecordsByMonthProvider(_currentMonth()));
      ref.invalidate(savingsSubgoalsProvider);
    }
  }

  Future<void> _deleteRecord(String id) async {
    final repo = ref.read(savingsRepoProvider);
    await repo.deleteRecord(id);
    if (mounted) {
      ref.invalidate(savingsRecordsProvider);
      ref.invalidate(savingsRecordsByMonthProvider(_currentMonth()));
    }
  }

  Future<void> _insertSubgoal() async {
    final name = _subGoalNameController.text.trim();
    final target = double.tryParse(_subGoalTargetController.text);
    if (name.isEmpty || target == null || target <= 0) return;
    final repo = ref.read(savingsRepoProvider);
    await repo.insertSubgoal(SavingsSubgoal(
      id: const Uuid().v4(),
      name: name,
      target: target,
      current: 0,
      createdAt: DeviceInfo.nowTimestamp(),
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      _subGoalNameController.clear();
      _subGoalTargetController.clear();
      ref.invalidate(savingsSubgoalsProvider);
    }
  }

  Future<void> _deleteSubgoal(String id) async {
    final repo = ref.read(savingsRepoProvider);
    await repo.deleteSubgoal(id);
    if (mounted) {
      ref.invalidate(savingsSubgoalsProvider);
    }
  }

  /// 标记小目标为已完成
  Future<void> _completeSubgoal(SavingsSubgoal sg) async {
    final repo = ref.read(savingsRepoProvider);
    await repo.updateSubgoal(sg.copyWith(completed: true));
    if (mounted) {
      ref.invalidate(savingsSubgoalsProvider);
    }
  }

  void _showSubGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加攒钱小目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
                controller: _subGoalNameController,
                label: '目标名称',
                hintText: '例如：买相机、旅行基金'),
            const SizedBox(height: 12),
            AppInput(
                controller: _subGoalTargetController,
                label: '目标金额 (元)',
                hintText: '目标金额',
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _insertSubgoal();
              },
              child: const Text('添加')),
        ],
      ),
    );
  }
}