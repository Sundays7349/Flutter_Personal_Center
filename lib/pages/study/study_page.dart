import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_tabs.dart';
import '../../widgets/app_date_picker.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/device_info.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  final _paperTitleController = TextEditingController();
  final _paperDateController = TextEditingController();
  final _paperNoteController = TextEditingController();
  final _expNameController = TextEditingController();
  final _expDateController = TextEditingController();
  String _expStatus = 'planned';
  final _engWordsController = TextEditingController();
  final _engMinutesController = TextEditingController();

  @override
  void dispose() {
    _paperTitleController.dispose();
    _paperDateController.dispose();
    _paperNoteController.dispose();
    _expNameController.dispose();
    _expDateController.dispose();
    _engWordsController.dispose();
    _engMinutesController.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<int> _computeWeekMinutes(List<StudyEnglish> records) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final minutes = List.filled(7, 0);
    for (final r in records) {
      final recordDate = DateTime.parse(r.date);
      if (recordDate.isBefore(weekStartDate) || recordDate.isAfter(todayDate)) continue;
      minutes[recordDate.weekday - 1] += r.minutes;
    }
    return minutes;
  }

  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(studyPapersProvider);
    final experimentsAsync = ref.watch(studyExperimentsProvider);
    final englishAsync = ref.watch(studyEnglishProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatsRow(papersAsync, experimentsAsync, englishAsync),
        const SizedBox(height: 16),
        _buildChart(englishAsync),
        const SizedBox(height: 16),
        _buildTabs(papersAsync, experimentsAsync, englishAsync),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<StudyPaper>> papersAsync,
    AsyncValue<List<StudyExperiment>> experimentsAsync,
    AsyncValue<List<StudyEnglish>> englishAsync,
  ) {
    int paperCount = 0;
    int expCount = 0;
    int todayWords = 0;
    int weekMinutes = 0;
    final today = _today();

    papersAsync.whenData((list) => paperCount = list.length);
    experimentsAsync.whenData((list) => expCount = list.length);
    englishAsync.whenData((list) {
      for (final e in list) {
        if (e.date == today) todayWords += e.words;
      }
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      for (final e in list) {
        final recordDate = DateTime.parse(e.date);
        if (!recordDate.isBefore(weekStartDate) && !recordDate.isAfter(todayDate)) {
          weekMinutes += e.minutes;
        }
      }
    });

    final hours = weekMinutes ~/ 60;
    final mins = weekMinutes % 60;

    final cards = [
      _buildStatItem('文献阅读', '$paperCount 篇', const Color(0xFFF0F9FF), const Color(0xFF0284C7), Icons.menu_book),
      _buildStatItem('实验安排', '$expCount 项', const Color(0xFFFAF5FF), const Color(0xFF9333EA), Icons.science),
      _buildStatItem('今日英语', '$todayWords 词', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.translate),
      _buildStatItem('本周学习', '${hours}h ${mins}m', const Color(0xFFFFFAF0), const Color(0xFFEA580C), Icons.timer),
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

  Widget _buildStatItem(String label, String value, Color bgColor, Color iconColor, IconData icon) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: iconColor), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground))]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart(AsyncValue<List<StudyEnglish>> englishAsync) {
    return AppCard(
      header: const AppCardHeader(title: AppCardTitle(child: Text('📊 本周学习时长统计'))),
      child: SizedBox(
        height: 300,
        child: englishAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e', style: const TextStyle(color: AppColors.destructive))),
          data: (records) {
            final minutes = _computeWeekMinutes(records);
            return _buildBarChart(minutes);
          },
        ),
      ),
    );
  }

  Widget _buildBarChart(List<int> minutes) {
    final weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final maxY = minutes.isEmpty ? 100.0 : (minutes.reduce((a, b) => a > b ? a : b) * 1.2).clamp(0, 100).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: List.generate(7, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: minutes[i].toDouble(), color: AppColors.chart1, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
          ],
        )),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (i, _) => Text(weekLabels[i.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)))),
        ),
        borderData: FlBorderData(show: false),
        groupsSpace: 12,
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildTabs(
    AsyncValue<List<StudyPaper>> papersAsync,
    AsyncValue<List<StudyExperiment>> experimentsAsync,
    AsyncValue<List<StudyEnglish>> englishAsync,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: AppTabs(
        tabs: const [
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, size: 14), SizedBox(width: 6), Text('文献阅读')])),
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.science, size: 14), SizedBox(width: 6), Text('实验安排')])),
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.translate, size: 14), SizedBox(width: 6), Text('英语学习')])),
        ],
        contentBuilder: (index) {
          switch (index) {
            case 0:
              return _buildPapersTab(papersAsync);
            case 1:
              return _buildExperimentsTab(experimentsAsync);
            case 2:
              return _buildEnglishTab(englishAsync);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildPapersTab(AsyncValue<List<StudyPaper>> papersAsync) {
    return papersAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: EdgeInsets.all(24), child: Text('加载失败: $e', style: const TextStyle(color: AppColors.destructive)))),
      data: (papers) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(width: 240, child: AppInput(controller: _paperTitleController, hintText: '文献名称')),
              SizedBox(width: 160, child: AppDatePickerFormField(controller: _paperDateController, hintText: '日期')),
              SizedBox(width: double.infinity, child: AppInput(controller: _paperNoteController, hintText: '笔记摘要', maxLines: 2)),
              SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                AppButton(onPressed: _addPaper, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('添加文献')])),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          papers.isEmpty
              ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)), child: const Text('暂无文献记录 📚', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.mutedForeground)))
              : Column(
                  children: papers.map((p) => _buildPaperItem(p)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildPaperItem(StudyPaper paper) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paper.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (paper.date != null && paper.date!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📅 ${paper.date!}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
                if (paper.note != null && paper.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(paper.note!, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deletePaper(paper.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentsTab(AsyncValue<List<StudyExperiment>> experimentsAsync) {
    return experimentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: EdgeInsets.all(24), child: Text('加载失败: $e', style: const TextStyle(color: AppColors.destructive)))),
      data: (experiments) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(width: 200, child: AppInput(controller: _expNameController, hintText: '实验名称')),
              SizedBox(width: 160, child: AppDatePickerFormField(controller: _expDateController, hintText: '日期')),
              SizedBox(width: 160, child: DropdownButtonFormField<String>(
                initialValue: _expStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('计划中')),
                  DropdownMenuItem(value: 'ongoing', child: Text('进行中')),
                  DropdownMenuItem(value: 'done', child: Text('已完成')),
                ],
                onChanged: (v) => setState(() => _expStatus = v ?? 'planned'),
              )),
              SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                AppButton(onPressed: _addExperiment, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('添加实验')])),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          experiments.isEmpty
              ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)), child: const Text('暂无实验安排 🔬', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.mutedForeground)))
              : Column(
                  children: experiments.map((e) => _buildExperimentItem(e)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildExperimentItem(StudyExperiment experiment) {
    final statusColors = {
      'planned': const Color(0xFFF0F9FF),
      'ongoing': const Color(0xFFFAF5FF),
      'done': const Color(0xFFF0FDF4),
    };
    final statusTextColors = {
      'planned': const Color(0xFF0284C7),
      'ongoing': const Color(0xFF9333EA),
      'done': const Color(0xFF16A34A),
    };
    final statusLabels = {
      'planned': '计划中',
      'ongoing': '进行中',
      'done': '已完成',
    };
    final bgColor = statusColors[experiment.status] ?? AppColors.muted;
    final textColor = statusTextColors[experiment.status] ?? AppColors.mutedForeground;
    final label = statusLabels[experiment.status] ?? experiment.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(experiment.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                if (experiment.date != null && experiment.date!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📅 ${experiment.date!}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deleteExperiment(experiment.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishTab(AsyncValue<List<StudyEnglish>> englishAsync) {
    final today = _today();
    int todayWords = 0;
    int todayMinutes = 0;

    englishAsync.whenData((list) {
      for (final e in list) {
        if (e.date == today) {
          todayWords += e.words;
          todayMinutes += e.minutes;
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBBF7D0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('今日单词', style: TextStyle(fontSize: 12, color: Color(0xFF059669))), const SizedBox(height: 4), Text('$todayWords', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF059669)))],))),
          const SizedBox(width: 16),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBAE6FD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('今日学习时长', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))), const SizedBox(height: 4), Text('$todayMinutes 分钟', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))],))),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: 160, child: AppInput(controller: _engWordsController, hintText: '单词数', keyboardType: TextInputType.number)),
            SizedBox(width: 160, child: AppInput(controller: _engMinutesController, hintText: '学习时长（分钟）', keyboardType: TextInputType.number)),
            SizedBox(width: double.infinity, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              AppButton(onPressed: _addEnglish, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('今日打卡')])),
            ])),
          ]),
        ),
      ],
    );
  }

  Future<void> _addPaper() async {
    final title = _paperTitleController.text.trim();
    if (title.isEmpty) return;
    final now = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    await ref.read(studyRepoProvider).insertPaper(StudyPaper(
      id: const Uuid().v4(),
      title: title,
      date: _paperDateController.text.isNotEmpty ? _paperDateController.text : today,
      note: _paperNoteController.text.isNotEmpty ? _paperNoteController.text : null,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _paperTitleController.clear();
    _paperDateController.clear();
    _paperNoteController.clear();
    if (mounted) ref.invalidate(studyPapersProvider);
  }

  Future<void> _deletePaper(String id) async {
    await ref.read(studyRepoProvider).deletePaper(id);
    if (mounted) ref.invalidate(studyPapersProvider);
  }

  Future<void> _addExperiment() async {
    final name = _expNameController.text.trim();
    if (name.isEmpty) return;
    final now = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    await ref.read(studyRepoProvider).insertExperiment(StudyExperiment(
      id: const Uuid().v4(),
      name: name,
      date: _expDateController.text.isNotEmpty ? _expDateController.text : today,
      status: _expStatus,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _expNameController.clear();
    _expDateController.clear();
    setState(() => _expStatus = 'planned');
    if (mounted) ref.invalidate(studyExperimentsProvider);
  }

  Future<void> _deleteExperiment(String id) async {
    await ref.read(studyRepoProvider).deleteExperiment(id);
    if (mounted) ref.invalidate(studyExperimentsProvider);
  }

  Future<void> _addEnglish() async {
    final words = int.tryParse(_engWordsController.text) ?? 0;
    final minutes = int.tryParse(_engMinutesController.text) ?? 0;
    if (words == 0 && minutes == 0) return;
    final now = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    await ref.read(studyRepoProvider).insertEnglish(StudyEnglish(
      id: const Uuid().v4(),
      date: today,
      words: words,
      minutes: minutes,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _engWordsController.clear();
    _engMinutesController.clear();
    if (mounted) {
      ref.invalidate(studyEnglishProvider);
      ref.invalidate(studyEnglishByDateProvider(today));
    }
  }
}