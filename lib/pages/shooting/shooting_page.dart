import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_date_picker.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/device_info.dart';

class ShootingPage extends ConsumerStatefulWidget {
  const ShootingPage({super.key});

  @override
  ConsumerState<ShootingPage> createState() => _ShootingPageState();
}

class _ShootingPageState extends ConsumerState<ShootingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _participantsController = TextEditingController();
  final _ideaController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _participantsController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(shootingRepoProvider);
      final now = DeviceInfo.nowTimestamp();
      await repo.insertProject(ShootingProject(
        id: const Uuid().v4(),
        name: _nameController.text,
        shootDate: _dateController.text.isEmpty ? null : _dateController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        cost: double.tryParse(_costController.text) ?? 0.0,
        participants: _participantsController.text.isEmpty ? null : _participantsController.text,
        done: false,
        createdAt: now,
        updatedAt: now,
        deviceId: '',
        synced: false,
      ));
      _nameController.clear();
      _dateController.clear();
      _priceController.clear();
      _costController.clear();
      _participantsController.clear();
      ref.invalidate(shootingProjectsByDoneProvider(false));
      ref.invalidate(shootingProjectsByDoneProvider(true));
      ref.invalidate(shootingProjectsProvider);
    }
  }

  Future<void> _toggleDone(ShootingProject project) async {
    final repo = ref.read(shootingRepoProvider);
    await repo.updateProject(project.copyWith(
      done: !project.done,
      updatedAt: DeviceInfo.nowTimestamp(),
      synced: false,
    ));
    ref.invalidate(shootingProjectsByDoneProvider(false));
    ref.invalidate(shootingProjectsByDoneProvider(true));
    ref.invalidate(shootingProjectsProvider);
  }

  Future<void> _deleteProject(String id) async {
    final repo = ref.read(shootingRepoProvider);
    await repo.deleteProject(id);
    ref.invalidate(shootingProjectsByDoneProvider(false));
    ref.invalidate(shootingProjectsByDoneProvider(true));
    ref.invalidate(shootingProjectsProvider);
  }

  Future<void> _addIdea() async {
    if (_ideaController.text.trim().isEmpty) return;
    final repo = ref.read(shootingRepoProvider);
    final now = DeviceInfo.nowTimestamp();
    await repo.insertIdea(ShootingIdea(
      id: const Uuid().v4(),
      content: _ideaController.text.trim(),
      createdAt: now,
      updatedAt: now,
      deviceId: '',
      synced: false,
    ));
    _ideaController.clear();
    ref.invalidate(shootingIdeasProvider);
  }

  Future<void> _deleteIdea(String id) async {
    final repo = ref.read(shootingRepoProvider);
    await repo.deleteIdea(id);
    ref.invalidate(shootingIdeasProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pendingProjectsAsync = ref.watch(shootingProjectsByDoneProvider(false));
    final doneProjectsAsync = ref.watch(shootingProjectsByDoneProvider(true));
    final ideasAsync = ref.watch(shootingIdeasProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatsRow(pendingProjectsAsync, doneProjectsAsync),
        const SizedBox(height: 16),
        _buildAddProjectForm(),
        const SizedBox(height: 16),
        _buildMainContent(pendingProjectsAsync, ideasAsync),
        doneProjectsAsync.when(
          data: (doneProjects) {
            if (doneProjects.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 16),
                _buildDoneProjects(doneProjects),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<ShootingProject>> pendingAsync,
    AsyncValue<List<ShootingProject>> doneAsync,
  ) {
    return pendingAsync.when(
      data: (pending) {
        return doneAsync.when(
          data: (done) {
            final allProjects = [...pending, ...done];
            final totalCount = allProjects.length;
            final totalIncome = allProjects.fold(0.0, (sum, p) => sum + p.price);
            final totalProfit = allProjects.fold(0.0, (sum, p) => sum + (p.price - p.cost));
            return LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _buildStatCard('总项目数', '$totalCount', const Color(0xFFF0F9FF), const Color(0xFF0284C7), Icons.camera_alt),
                  _buildStatCard('总收入', '¥${totalIncome.toStringAsFixed(0)}', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.attach_money),
                  _buildStatCard('总利润', '¥${totalProfit.toStringAsFixed(0)}', const Color(0xFFFAF5FF), const Color(0xFF9333EA), Icons.trending_up),
                ];
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
          },
          loading: () => _buildStatsLoading(),
          error: (_, _) => _buildStatsLoading(),
        );
      },
      loading: () => _buildStatsLoading(),
      error: (_, _) => _buildStatsLoading(),
    );
  }

  Widget _buildStatsLoading() {
    final cards = [
      _buildStatCard('总项目数', '...', const Color(0xFFF0F9FF), const Color(0xFF0284C7), Icons.camera_alt),
      _buildStatCard('总收入', '...', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.attach_money),
      _buildStatCard('总利润', '...', const Color(0xFFFAF5FF), const Color(0xFF9333EA), Icons.trending_up),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
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

  Widget _buildStatCard(String label, String value, Color bgColor, Color iconColor, IconData icon) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.foreground)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddProjectForm() {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('添加新项目'),
            ],
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 240,
              child: AppInput(controller: _nameController, hintText: '项目名称'),
            ),
            SizedBox(
              width: 180,
              child: AppDatePickerFormField(
                controller: _dateController,
                hintText: '拍摄日期',
              ),
            ),
            SizedBox(
              width: 160,
              child: AppInput(
                controller: _priceController,
                hintText: '价格 (元)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 160,
              child: AppInput(
                controller: _costController,
                hintText: '成本 (元)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 300,
              child: AppInput(
                controller: _participantsController,
                hintText: '参与人员（逗号分隔）',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: _addProject,
                width: double.infinity,
                child: const Text('添加项目'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    AsyncValue<List<ShootingProject>> pendingAsync,
    AsyncValue<List<ShootingIdea>> ideasAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pendingCard = _buildPendingProjects(pendingAsync);
        final ideasCard = _buildIdeas(ideasAsync);
        // 窄屏（移动端竖屏）分开显示：待完成项目与灵感储备各占一行
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              pendingCard,
              const SizedBox(height: 16),
              ideasCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: pendingCard),
            const SizedBox(width: 16),
            Expanded(child: ideasCard),
          ],
        );
      },
    );
  }

  Widget _buildPendingProjects(AsyncValue<List<ShootingProject>> async) {
    return async.when(
      data: (pendingProjects) {
        return AppCard(
          header: AppCardHeader(
            title: AppCardTitle(
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('待完成项目 (${pendingProjects.length})'),
                ],
              ),
            ),
          ),
          child: pendingProjects.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '暂无待完成项目 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                  ),
                )
              : Column(
                  children: pendingProjects.map((p) => _buildProjectCard(p)).toList(),
                ),
        );
      },
      loading: () => const AppCard(
        child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => AppCard(
        child: SizedBox(
          height: 100,
          child: Center(child: Text('加载失败: $error')),
        ),
      ),
    );
  }

  Widget _buildProjectCard(ShootingProject p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('📅 ${p.shootDate ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () => _toggleDone(p),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check, size: 14),
                      SizedBox(width: 4),
                      Text('完成', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(width: 4),
                  AppButton(
                    variant: AppButtonVariant.destructive,
                    size: AppButtonSize.sm,
                    onPressed: () => _deleteProject(p.id),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              AppBadge(
                variant: AppBadgeVariant.outline,
                backgroundColor: const Color(0xFFECFDF5),
                foregroundColor: const Color(0xFF059669),
                child: Text('收入 ¥${p.price.toStringAsFixed(0)}'),
              ),
              AppBadge(
                variant: AppBadgeVariant.outline,
                backgroundColor: const Color(0xFFFFF7ED),
                foregroundColor: const Color(0xFFEA580C),
                child: Text('成本 ¥${p.cost.toStringAsFixed(0)}'),
              ),
              AppBadge(
                variant: AppBadgeVariant.outline,
                backgroundColor: const Color(0xFFFAF5FF),
                foregroundColor: const Color(0xFF9333EA),
                child: Text('利润 ¥${(p.price - p.cost).toStringAsFixed(0)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeas(AsyncValue<List<ShootingIdea>> async) {
    return async.when(
      data: (ideas) {
        return AppCard(
          header: AppCardHeader(
            title: const AppCardTitle(
              child: Row(
                children: [
                  Icon(Icons.lightbulb, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('灵感储备'),
                ],
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      controller: _ideaController,
                      hintText: '随手记灵感...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    size: AppButtonSize.icon,
                    onPressed: _addIdea,
                    child: const Icon(Icons.add, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ideas.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '暂无灵感记录',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                      ),
                    )
                  : Column(
                      children: ideas.map((idea) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    idea.content,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                                  ),
                                ),
                                AppButton(
                                  variant: AppButtonVariant.destructive,
                                  size: AppButtonSize.sm,
                                  onPressed: () => _deleteIdea(idea.id),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          )).toList(),
                    ),
            ],
          ),
        );
      },
      loading: () => const AppCard(
        child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => AppCard(
        child: SizedBox(
          height: 100,
          child: Center(child: Text('加载失败: $error')),
        ),
      ),
    );
  }

  Widget _buildDoneProjects(List<ShootingProject> doneProjects) {
    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: AppColors.success),
              SizedBox(width: 8),
              Text('已完成项目'),
            ],
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: doneProjects.map((p) => Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  color: AppColors.muted.withValues(alpha: 0.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground, decoration: TextDecoration.lineThrough),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('📅 ${p.shootDate ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              )).toList(),
        ),
      ),
    );
  }
}
