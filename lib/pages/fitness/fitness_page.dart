import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/device_info.dart';

class FitnessPage extends ConsumerStatefulWidget {
  const FitnessPage({super.key});

  @override
  ConsumerState<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends ConsumerState<FitnessPage> {
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _foodController = TextEditingController();
  final _caloriesController = TextEditingController();

  String _selectedType = 'cardio';
  String _selectedMealType = '早餐';
  int _calMonth = DateTime.now().month;
  int _calYear = DateTime.now().year;

  @override
  void dispose() {
    _durationController.dispose();
    _weightController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _foodController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Set<String> _computeWorkoutDates(List<FitnessWorkout> workouts) {
    return workouts.map((w) => w.date).toSet();
  }

  int _computeWeeklyMinutes(List<FitnessWorkout> workouts) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (final w in workouts) {
      final dateParts = w.date.split('-');
      if (dateParts.length < 3) continue;
      final recordDate = DateTime.parse(w.date);
      if (!recordDate.isBefore(weekStartDate) && !recordDate.isAfter(todayDate)) {
        total += w.duration;
      }
    }
    return total;
  }

  int _computeWeeklyCheckins(List<FitnessWorkout> workouts) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final dates = <String>{};
    for (final w in workouts) {
      final recordDate = DateTime.parse(w.date);
      if (!recordDate.isBefore(weekStartDate) && !recordDate.isAfter(todayDate)) {
        dates.add(w.date);
      }
    }
    return dates.length;
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(fitnessWorkoutsProvider);
    final latestBodyAsync = ref.watch(fitnessLatestBodyProvider);
    final bodiesAsync = ref.watch(fitnessBodiesProvider);
    final dietsAsync = ref.watch(fitnessDietsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatsRow(workoutsAsync, latestBodyAsync),
        const SizedBox(height: 16),
        _buildMainRow(workoutsAsync),
        const SizedBox(height: 16),
        _buildBodyDietSection(latestBodyAsync, bodiesAsync, dietsAsync),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<FitnessWorkout>> workoutsAsync,
    AsyncValue<FitnessBody?> latestBodyAsync,
  ) {
    int todayMinutes = 0;
    int weekCheckins = 0;
    int weekMinutes = 0;
    String weightText = '--';
    final today = _today();

    workoutsAsync.whenData((list) {
      for (final w in list) {
        if (w.date == today) todayMinutes += w.duration;
      }
      weekCheckins = _computeWeeklyCheckins(list);
      weekMinutes = _computeWeeklyMinutes(list);
    });

    latestBodyAsync.whenData((body) {
      if (body != null && body.weight != null) {
        weightText = '${body.weight!.toStringAsFixed(1)} kg';
      }
    });

    final cards = [
      _buildStatCard2('今日运动', '$todayMinutes 分钟', const Color(0xFFFFFAF0), const Color(0xFFEA580C), Icons.fitness_center),
      _buildStatCard2('本周打卡', '$weekCheckins 天', const Color(0xFFFAF5FF), const Color(0xFF9333EA), Icons.calendar_month),
      _buildStatCard2('本周时长', _formatTime(weekMinutes), const Color(0xFFF0F9FF), const Color(0xFF0284C7), Icons.timer),
      _buildStatCard2('当前体重', weightText, const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.scale),
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

  Widget _buildStatCard2(String label, String value, Color bgColor, Color iconColor, IconData icon) {
    return AppCard(
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
          ]),
        ],
      ),
    );
  }

  Widget _buildMainRow(AsyncValue<List<FitnessWorkout>> workoutsAsync) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final workoutCard = _buildWorkoutCard(workoutsAsync);
        final calendarCard = _buildCalendarCard(workoutsAsync);
        // 窄屏（移动端竖屏）分开显示：训练打卡与健身日期各占一行
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              workoutCard,
              const SizedBox(height: 16),
              calendarCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: workoutCard),
            const SizedBox(width: 16),
            Expanded(child: calendarCard),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutCard(AsyncValue<List<FitnessWorkout>> workoutsAsync) {
    final List<Map<String, Object?>> types = [
      {'key': 'cardio', 'label': '有氧', 'emoji': '🏃', 'color': const Color(0xFFFEE2E2), 'textColor': const Color(0xFFB91C1C)},
      {'key': 'strength', 'label': '力量', 'emoji': '💪', 'color': const Color(0xFFDBEAFE), 'textColor': const Color(0xFF1D4ED8)},
      {'key': 'stretch', 'label': '拉伸', 'emoji': '🧘', 'color': const Color(0xFFDCFCE7), 'textColor': const Color(0xFF15803D)},
    ];

    final today = _today();

    return AppCard(
      header: AppCardHeader(
        title: const AppCardTitle(child: Row(children: [Icon(Icons.fitness_center, size: 16, color: Color(0xFFEA580C)), SizedBox(width: 8), Text('训练打卡')])),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: types.map((t) {
              final isSelected = _selectedType == t['key'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: t == types.last ? 0 : 8),
                  child: AppButton(
                    variant: isSelected ? AppButtonVariant.primary : AppButtonVariant.outline,
                    onPressed: () => setState(() => _selectedType = t['key'] as String? ?? ''),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(t['emoji'] as String? ?? '', style: const TextStyle(fontSize: 14)), const SizedBox(width: 4), Text(t['label'] as String? ?? '')]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(controller: _durationController, hintText: '运动时长（分钟）', keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              AppButton(onPressed: _addWorkout, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('打卡')])),
            ],
          ),
          const SizedBox(height: 16),
          const Text('今日打卡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
          const SizedBox(height: 8),
          workoutsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('加载失败: $e', style: const TextStyle(color: AppColors.destructive)))),
            data: (workouts) {
              final todayWorkouts = workouts.where((w) => w.date == today).toList();
              if (todayWorkouts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                  child: const Text('今日还没运动，动起来吧 🏃‍♀️', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
                );
              }
              return Column(
                children: todayWorkouts.map((w) => _buildWorkoutItem(w, types)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(FitnessWorkout workout, List<Map<String, Object?>> types) {
    final typeInfo = types.firstWhere(
      (t) => t['key'] == workout.type,
      orElse: () => <String, Object?>{'key': workout.type, 'label': workout.type, 'emoji': '🏋️', 'color': AppColors.muted, 'textColor': AppColors.mutedForeground},
    );
    final bgColor = typeInfo['color'] as Color? ?? AppColors.muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(typeInfo['emoji'] as String? ?? '', style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${typeInfo['label']} · ${workout.duration} 分钟', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deleteWorkout(workout.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(AsyncValue<List<FitnessWorkout>> workoutsAsync) {
    Set<String> workoutDates = {};
    workoutsAsync.whenData((list) => workoutDates = _computeWorkoutDates(list));

    return AppCard(
      header: AppCardHeader(
        title: AppCardTitle(child: Row(children: [Icon(Icons.calendar_month, size: 16, color: Color(0xFF9333EA)), SizedBox(width: 8), const Text('健身日历')])),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton(variant: AppButtonVariant.ghost, size: AppButtonSize.icon, onPressed: () => setState(() { _calMonth = _calMonth == 1 ? 12 : _calMonth - 1; if (_calMonth == 12) _calYear--; }), child: const Icon(Icons.chevron_left, size: 18)),
              Text('$_calYear年$_calMonth月', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              AppButton(variant: AppButtonVariant.ghost, size: AppButtonSize.icon, onPressed: () => setState(() { _calMonth = _calMonth == 12 ? 1 : _calMonth + 1; if (_calMonth == 1) _calYear++; }), child: const Icon(Icons.chevron_right, size: 18)),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendar(workoutDates),
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('已打卡', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
            const SizedBox(width: 16),
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('今天', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCalendar(Set<String> workoutDates) {
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    final firstDay = DateTime(_calYear, _calMonth, 1);
    final lastDay = DateTime(_calYear, _calMonth + 1, 0);
    final firstWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Row(
          children: weekDays.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500))))).toList(),
        ),
        const SizedBox(height: 4),
        ..._buildCalendarDays(firstWeekday, lastDay.day, workoutDates),
      ],
    );
  }

  List<Widget> _buildCalendarDays(int firstWeekday, int lastDay, Set<String> workoutDates) {
    final rows = <Widget>[];
    var week = <Widget>[];

    for (int i = 0; i < firstWeekday; i++) {
      week.add(const Expanded(child: SizedBox.shrink()));
    }

    for (int day = 1; day <= lastDay; day++) {
      final isToday = day == DateTime.now().day && _calMonth == DateTime.now().month && _calYear == DateTime.now().year;
      final dateStr = '$_calYear-${_calMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasWorkout = workoutDates.contains(dateStr);

      week.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isToday ? AppColors.primaryForeground : AppColors.mutedForeground,
                  ),
                ),
                if (hasWorkout && !isToday)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      if (week.length == 7) {
        rows.add(Row(children: week));
        week = [];
      }
    }

    if (week.isNotEmpty) {
      rows.add(Row(children: week));
    }

    return rows;
  }

  Widget _buildBodyDietSection(
    AsyncValue<FitnessBody?> latestBodyAsync,
    AsyncValue<List<FitnessBody>> bodiesAsync,
    AsyncValue<List<FitnessDiet>> dietsAsync,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('体重围度 & 饮食', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bodyTab = _buildBodyTab(latestBodyAsync, bodiesAsync);
              final dietTab = _buildDietTab(dietsAsync);
              // 窄屏（移动端竖屏）分开显示：体重围度与饮食各占一行
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bodyTab,
                    const SizedBox(height: 12),
                    dietTab,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: bodyTab),
                  const SizedBox(width: 16),
                  Expanded(child: dietTab),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTab(AsyncValue<FitnessBody?> latestBodyAsync, AsyncValue<List<FitnessBody>> bodiesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('体重围度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          latestBodyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (body) {
              if (body != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _weightController.text = body.weight?.toStringAsFixed(1) ?? '';
                    _chestController.text = body.chest?.toStringAsFixed(1) ?? '';
                    _waistController.text = body.waist?.toStringAsFixed(1) ?? '';
                    _hipController.text = body.hip?.toStringAsFixed(1) ?? '';
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 140, child: AppInput(controller: _weightController, hintText: '体重 (kg)', keyboardType: TextInputType.number)),
              SizedBox(width: 140, child: AppInput(controller: _chestController, hintText: '胸围 (cm)', keyboardType: TextInputType.number)),
              SizedBox(width: 140, child: AppInput(controller: _waistController, hintText: '腰围 (cm)', keyboardType: TextInputType.number)),
              SizedBox(width: 140, child: AppInput(controller: _hipController, hintText: '臀围 (cm)', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            AppButton(onPressed: _saveBody, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('保存记录')])),
          ]),
          const SizedBox(height: 16),
          const Text('历史记录', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
          const SizedBox(height: 8),
          bodiesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (bodies) {
              if (bodies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('暂无历史记录', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                );
              }
              final sorted = [...bodies]..sort((a, b) => b.date.compareTo(a.date));
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: const [
                          Expanded(child: Text('日期', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('体重', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('胸围', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('腰围', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('臀围', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...sorted.map((body) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(body.date, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(body.weight?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(body.chest?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(body.waist?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(body.hip?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDietTab(AsyncValue<List<FitnessDiet>> dietsAsync) {
    final now = DateTime.now();
    final autoMealType = detectMealType(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('饮食记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('餐别：', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMealType,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: '早餐', child: Text('🌅 早餐')),
                    DropdownMenuItem(value: '中餐', child: Text('☀️ 中餐')),
                    DropdownMenuItem(value: '晚餐', child: Text('🌙 晚餐')),
                    DropdownMenuItem(value: '夜宵', child: Text('🌃 夜宵')),
                  ],
                  onChanged: (v) => setState(() => _selectedMealType = v!),
                ),
              ),
              const Spacer(),
              Text('当前时间：${formatTime(now)}（自动识别：$autoMealType）',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          AppInput(controller: _foodController, hintText: '吃了什么...'),
          const SizedBox(height: 8),
          AppInput(controller: _caloriesController, hintText: '多少大卡 (kcal)', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            AppButton(onPressed: _saveDiet, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('添加记录')])),
          ]),
          const SizedBox(height: 16),
          const Text('历史记录', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
          const SizedBox(height: 8),
          dietsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (diets) {
              if (diets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('暂无饮食记录', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                );
              }
              final sorted = [...diets]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: const [
                          Expanded(child: Text('日期', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('时间', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('餐别', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('食物', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                          Expanded(child: Text('大卡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...sorted.map((diet) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(diet.date, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(diet.time, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(diet.mealType, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(diet.food, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text('${diet.calories} kcal', style: const TextStyle(fontSize: 13))),
                          AppButton(
                            variant: AppButtonVariant.destructive,
                            size: AppButtonSize.sm,
                            onPressed: () => _deleteDietRecord(diet.id),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addWorkout() async {
    final duration = int.tryParse(_durationController.text) ?? 0;
    if (duration <= 0) return;
    final now = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    await ref.read(fitnessRepoProvider).insertWorkout(FitnessWorkout(
      id: const Uuid().v4(),
      type: _selectedType,
      duration: duration,
      date: today,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _durationController.clear();
    if (mounted) {
      ref.invalidate(fitnessWorkoutsProvider);
      ref.invalidate(fitnessWorkoutsByDateProvider(today));
    }
  }

  Future<void> _deleteWorkout(String id) async {
    await ref.read(fitnessRepoProvider).deleteWorkout(id);
    if (mounted) ref.invalidate(fitnessWorkoutsProvider);
  }

  Future<void> _saveBody() async {
    final weight = double.tryParse(_weightController.text);
    final chest = double.tryParse(_chestController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    if (weight == null && chest == null && waist == null && hip == null) return;
    final now = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    await ref.read(fitnessRepoProvider).insertBody(FitnessBody(
      id: const Uuid().v4(),
      date: today,
      weight: weight,
      chest: chest,
      waist: waist,
      hip: hip,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      synced: false,
    ));
    _weightController.clear();
    _chestController.clear();
    _waistController.clear();
    _hipController.clear();
    if (mounted) {
      ref.invalidate(fitnessBodiesProvider);
      ref.invalidate(fitnessLatestBodyProvider);
    }
  }

  Future<void> _saveDiet() async {
    final food = _foodController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;
    if (food.isEmpty) return;
    final now = DateTime.now();
    final ts = DeviceInfo.nowTimestamp();
    final deviceId = await DeviceInfo.getDeviceId();
    final today = _today();
    final time = formatTime(now);
    final mealType = detectMealType(now);
    await ref.read(fitnessRepoProvider).insertDiet(FitnessDiet(
      id: const Uuid().v4(),
      date: today,
      time: time,
      mealType: mealType,
      food: food,
      calories: calories,
      createdAt: ts,
      updatedAt: ts,
      deviceId: deviceId,
      synced: false,
    ));
    _foodController.clear();
    _caloriesController.clear();
    if (mounted) {
      ref.invalidate(fitnessDietsProvider);
      ref.invalidate(fitnessDietsByDateProvider(today));
    }
  }

  Future<void> _deleteDietRecord(String id) async {
    await ref.read(fitnessRepoProvider).deleteDiet(id);
    if (mounted) {
      ref.invalidate(fitnessDietsProvider);
    }
  }
}