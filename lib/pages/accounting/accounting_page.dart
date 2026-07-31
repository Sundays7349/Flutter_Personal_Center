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
import '../../widgets/app_tabs.dart';
import '../../widgets/app_date_picker.dart';

class AccountingPage extends ConsumerStatefulWidget {
  const AccountingPage({super.key});

  @override
  ConsumerState<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends ConsumerState<AccountingPage> {
  final _expenseAmountController = TextEditingController();
  final _expenseDateController = TextEditingController();
  final _expenseNoteController = TextEditingController();
  String _expenseCategory = '餐饮';

  final _incomeAmountController = TextEditingController();
  final _incomeSourceController = TextEditingController();
  final _incomeDateController = TextEditingController();
  final _incomeNoteController = TextEditingController();

  String _filterType = 'all';
  final _budgetController = TextEditingController(text: '5000');
  bool _editingBudget = false;

  @override
  void initState() {
    super.initState();
    _expenseDateController.text = _today();
    _incomeDateController.text = _today();
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

  @override
  void dispose() {
    _expenseAmountController.dispose();
    _expenseDateController.dispose();
    _expenseNoteController.dispose();
    _incomeAmountController.dispose();
    _incomeSourceController.dispose();
    _incomeDateController.dispose();
    _incomeNoteController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  final List<Map<String, Object?>> _expenseCategories = const [
    {'value': '餐饮', 'emoji': '🍜', 'color': Color(0xFFF87171)},
    {'value': '购物', 'emoji': '🛍️', 'color': Color(0xFFFB923C)},
    {'value': '交通', 'emoji': '🚗', 'color': Color(0xFFFBBF24)},
    {'value': '娱乐', 'emoji': '🎮', 'color': Color(0xFFA78BFA)},
    {'value': '其他', 'emoji': '📦', 'color': Color(0xFF60A5FA)},
  ];

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(accountingBudgetProvider);
    final recordsAsync = ref.watch(accountingRecordsProvider);
    final monthRecordsAsync = ref.watch(accountingRecordsByMonthProvider(_currentMonth()));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryRow(budgetAsync, recordsAsync, monthRecordsAsync),
        const SizedBox(height: 16),
        _buildQuickRecord(),
        const SizedBox(height: 16),
        _buildMainRow(monthRecordsAsync),
        const SizedBox(height: 16),
        _buildRecordsList(recordsAsync),
      ],
    );
  }

  Widget _buildSummaryRow(
    AsyncValue<AccountingBudget?> budgetAsync,
    AsyncValue<List<AccountingRecord>> recordsAsync,
    AsyncValue<List<AccountingRecord>> monthRecordsAsync,
  ) {
    double budget = 5000;
    double todayIncome = 0;
    double todayExpense = 0;
    double monthIncome = 0;
    double monthExpense = 0;

    budgetAsync.whenData((b) {
      if (b != null) {
        budget = b.monthly;
        _budgetController.text = budget.toStringAsFixed(0);
      }
    });

    final today = _today();
    recordsAsync.whenData((records) {
      for (final r in records) {
        if (r.date == today) {
          if (r.type == 'income') todayIncome += r.amount;
          if (r.type == 'expense') todayExpense += r.amount;
        }
      }
    });

    monthRecordsAsync.whenData((records) {
      for (final r in records) {
        if (r.type == 'income') monthIncome += r.amount;
        if (r.type == 'expense') monthExpense += r.amount;
      }
    });

    final monthNet = monthIncome - monthExpense;

    final cards = [
      _buildSummaryCard(
        '今日收支',
        '+${_formatAmount(todayIncome)}',
        '-${_formatAmount(todayExpense)}',
        subtitle: '结余：${_formatAmount(todayIncome - todayExpense)}',
      ),
      _buildBudgetCard(budget, monthExpense),
      _buildSummaryCard(
        '本月结余',
        _formatAmount(monthNet),
        '',
        subtitle: '收入 ${_formatAmount(monthIncome)} · 支出 ${_formatAmount(monthExpense)}',
        showValues: false,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // 窄屏（移动端竖屏）一行一个卡片
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String income, String expense,
      {String? subtitle, bool showValues = true}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mutedForeground)),
          const SizedBox(height: 6),
          if (showValues)
            Row(
              children: [
                Text(income,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                const SizedBox(width: 12),
                Text(expense,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.destructive)),
              ],
            )
          else
            Text(income,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(double budget, double monthExpense) {
    final progress = budget > 0 ? (monthExpense / budget).clamp(0.0, 1.0) : 0.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('本月支出',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
              GestureDetector(
                onTap: () async {
                  if (_editingBudget) {
                    await _saveBudget();
                  } else {
                    setState(() => _editingBudget = true);
                  }
                },
                child: Text(
                    _editingBudget ? '保存' : '设预算',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _editingBudget
              ? SizedBox(
                  height: 28,
                  child: AppInput(
                      controller: _budgetController,
                      keyboardType: TextInputType.number))
              : Text(_formatAmount(monthExpense),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('预算 ${_formatAmount(budget)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
              Text('${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRecord() {
    return AppCard(
      header: const AppCardHeader(
        title: AppCardTitle(child: Text('⚡ 快速记账')),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _expenseCategories
            .map((cat) => SizedBox(
                  width: 90,
                  child: AppButton(
                    variant: AppButtonVariant.outline,
                    height: 60,
                    onPressed: () => _insertQuickExpense(cat['value'] as String),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat['emoji']! as String,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(cat['value']! as String,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMainRow(AsyncValue<List<AccountingRecord>> monthRecordsAsync) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final formCard = _buildEntryForm();
        final chartCard = _buildPieChart(monthRecordsAsync);
        // 窄屏（移动端竖屏）上下堆叠
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              formCard,
              const SizedBox(height: 16),
              chartCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: formCard),
            const SizedBox(width: 16),
            Expanded(child: chartCard),
          ],
        );
      },
    );
  }

  Widget _buildEntryForm() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: AppTabs(
        tabs: const [
          TabItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_down,
                    size: 14, color: AppColors.destructive),
                SizedBox(width: 6),
                Text('支出'),
              ],
            ),
          ),
          TabItem(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up,
                    size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text('收入'),
              ],
            ),
          ),
        ],
        contentBuilder: (index) {
          if (index == 0) return _buildExpenseForm();
          return _buildIncomeForm();
        },
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 160,
              child: AppInput(
                  controller: _expenseAmountController,
                  label: '金额 (元)',
                  hintText: '支出金额',
                  keyboardType: TextInputType.number),
            ),
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('分类',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _expenseCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _expenseCategories
                        .map((c) => DropdownMenuItem(
                            value: c['value'] as String,
                            child: Text('${c['emoji']} ${c['value']}')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _expenseCategory = v!),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: AppDatePickerFormField(
                  controller: _expenseDateController,
                  label: '日期',
                  hintText: '日期'),
            ),
            SizedBox(
              width: 160,
              child: AppInput(
                  controller: _expenseNoteController,
                  label: '备注',
                  hintText: '可选'),
            ),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _insertExpense,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text('记录支出'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 160,
              child: AppInput(
                  controller: _incomeAmountController,
                  label: '金额 (元)',
                  hintText: '收入金额',
                  keyboardType: TextInputType.number),
            ),
            SizedBox(
              width: 160,
              child: AppInput(
                  controller: _incomeSourceController,
                  label: '来源',
                  hintText: '工资/兼职/其他'),
            ),
            SizedBox(
              width: 160,
              child: AppDatePickerFormField(
                  controller: _incomeDateController,
                  label: '日期',
                  hintText: '日期'),
            ),
            SizedBox(
              width: 160,
              child: AppInput(
                  controller: _incomeNoteController,
                  label: '备注',
                  hintText: '可选'),
            ),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _insertIncome,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text('记录收入'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChart(AsyncValue<List<AccountingRecord>> monthRecordsAsync) {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(child: Text('📊 本月支出')),
        trailing: Row(
          children: [
            _filterButton('全部', 'all'),
            const SizedBox(width: 4),
            _filterButton('收入', 'income'),
            const SizedBox(width: 4),
            _filterButton('支出', 'expense'),
          ],
        ),
      ),
      child: SizedBox(
        height: 280,
        child: monthRecordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('加载失败: $e',
                style: const TextStyle(color: AppColors.destructive)),
          ),
          data: (records) => _buildPieChartWidget(records),
        ),
      ),
    );
  }

  Widget _filterButton(String label, String type) {
    final isActive = _filterType == type;
    return AppButton(
      variant: isActive ? AppButtonVariant.primary : AppButtonVariant.outline,
      size: AppButtonSize.sm,
      onPressed: () => setState(() => _filterType = type),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildPieChartWidget(List<AccountingRecord> records) {
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};

    final filteredRecords = _filterType == 'all'
        ? records.where((r) => r.type == 'expense').toList()
        : _filterType == 'expense'
            ? records.where((r) => r.type == 'expense').toList()
            : records.where((r) => r.type == 'income').toList();

    for (final r in filteredRecords) {
      categoryTotals[r.category] = (categoryTotals[r.category] ?? 0) + r.amount;
    }

    final colorMap = {
      '餐饮': const Color(0xFFF87171),
      '购物': const Color(0xFFFB923C),
      '交通': const Color(0xFFFBBF24),
      '娱乐': const Color(0xFFA78BFA),
      '其他': const Color(0xFF60A5FA),
    };

    double total = 0;
    for (final v in categoryTotals.values) {
      total += v;
    }

    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('暂无数据',
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    categoryTotals.forEach((category, amount) {
      final color = colorMap[category] ?? const Color(0xFF60A5FA);
      categoryColors[category] = color;
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: category,
        ),
      );
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildRecordsList(AsyncValue<List<AccountingRecord>> recordsAsync) {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('收支明细'),
            ],
          ),
        ),
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
        data: (records) => records.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('暂无记录',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.mutedForeground)),
              )
            : Column(
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
                              Container(
                                width: 8,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: r.type == 'income'
                                      ? AppColors.success
                                      : AppColors.destructive,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                            _formatAmount(
                                                r.type == 'income'
                                                    ? r.amount
                                                    : r.amount),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: r.type == 'income'
                                                    ? AppColors.success
                                                    : AppColors
                                                        .destructive),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(r.category,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .mutedForeground)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${r.date}${r.note != null && r.note!.isNotEmpty ? ' · ${r.note}' : ''}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors
                                                .mutedForeground)),
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
              ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_budgetController.text);
    if (amount == null || amount < 0) return;
    final repo = ref.read(accountingRepoProvider);
    await repo.saveBudget(AccountingBudget(
      id: 1,
      monthly: amount,
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      ref.invalidate(accountingBudgetProvider);
      setState(() => _editingBudget = false);
    }
  }

  Future<void> _insertExpense() async {
    final amount = double.tryParse(_expenseAmountController.text);
    if (amount == null || amount <= 0) return;
    final repo = ref.read(accountingRepoProvider);
    await repo.insertRecord(AccountingRecord(
      id: const Uuid().v4(),
      type: 'expense',
      amount: amount,
      category: _expenseCategory,
      note: _expenseNoteController.text.isEmpty ? null : _expenseNoteController.text,
      date: _expenseDateController.text.isEmpty ? _today() : _expenseDateController.text,
      createdAt: DeviceInfo.nowTimestamp(),
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      _expenseAmountController.clear();
      _expenseNoteController.clear();
      ref.invalidate(accountingRecordsProvider);
      ref.invalidate(accountingRecordsByMonthProvider(_currentMonth()));
    }
  }

  Future<void> _insertIncome() async {
    final amount = double.tryParse(_incomeAmountController.text);
    if (amount == null || amount <= 0) return;
    final repo = ref.read(accountingRepoProvider);
    await repo.insertRecord(AccountingRecord(
      id: const Uuid().v4(),
      type: 'income',
      amount: amount,
      category: _incomeSourceController.text.isEmpty ? '其他' : _incomeSourceController.text,
      note: _incomeNoteController.text.isEmpty ? null : _incomeNoteController.text,
      date: _incomeDateController.text.isEmpty ? _today() : _incomeDateController.text,
      createdAt: DeviceInfo.nowTimestamp(),
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      _incomeAmountController.clear();
      _incomeSourceController.clear();
      _incomeNoteController.clear();
      ref.invalidate(accountingRecordsProvider);
      ref.invalidate(accountingRecordsByMonthProvider(_currentMonth()));
    }
  }

  Future<void> _insertQuickExpense(String category) async {
    final repo = ref.read(accountingRepoProvider);
    await repo.insertRecord(AccountingRecord(
      id: const Uuid().v4(),
      type: 'expense',
      amount: 0,
      category: category,
      date: _today(),
      createdAt: DeviceInfo.nowTimestamp(),
      updatedAt: DeviceInfo.nowTimestamp(),
      deviceId: '',
      synced: false,
    ));
    if (mounted) {
      ref.invalidate(accountingRecordsProvider);
      ref.invalidate(accountingRecordsByMonthProvider(_currentMonth()));
    }
  }

  Future<void> _deleteRecord(String id) async {
    final repo = ref.read(accountingRepoProvider);
    await repo.deleteRecord(id);
    if (mounted) {
      ref.invalidate(accountingRecordsProvider);
      ref.invalidate(accountingRecordsByMonthProvider(_currentMonth()));
    }
  }
}