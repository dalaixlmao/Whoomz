import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../data/progress_models.dart';
import '../../data/weight_log_models.dart';
import '../providers/progress_providers.dart';
import '../widgets/weight_chart.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int? _expandedDay;
  static const _dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _goal = 64.0;

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(weekProgressProvider);
    final weightsAsync = ref.watch(weekWeightLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            progressAsync.when(
              loading: _buildWeekLoading,
              error: (_, _) => _buildWeekError(),
              data: (week) => _buildWeekGrid(week),
            ),
            _buildWeightCard(weightsAsync),
            _buildReportCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR JOURNAL',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.inkWithOpacity(0.4),
                letterSpacing: 1.8,
              )),
          const SizedBox(height: 2),
          Text('This week',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.8,
                height: 1.1,
              )),
        ],
      ),
    );
  }

  Widget _buildWeekLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bubbleAI,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.inkWithOpacity(0.08)),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bubbleAI,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.inkWithOpacity(0.08)),
        ),
        child: Text(
          'Could not load this week\'s data.',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.inkWithOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekGrid(List<DayProgress> week) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bubbleAI,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.inkWithOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            Row(
              children: List.generate(7, (i) {
                final day = week[i];
                final active = day.logged;
                final expanded = _expandedDay == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _expandedDay = expanded ? null : i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 7 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: active
                            ? null
                            : Border.all(
                                color: AppColors.inkWithOpacity(0.25),
                                width: 1.5,
                              ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.accentWithOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_dayInitials[i],
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : AppColors.inkWithOpacity(0.55),
                                letterSpacing: 0.4,
                              )),
                          const SizedBox(height: 1),
                          Text('${day.date.day}',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? Colors.white
                                    : AppColors.inkWithOpacity(0.55),
                                letterSpacing: -0.2,
                              )),
                          if (active) ...[
                            const SizedBox(height: 4),
                            WMark(
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.9)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_expandedDay != null) _buildDayDetail(week[_expandedDay!], _expandedDay!),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(DayProgress day, int i) {
    final label = '${_shortDayName(day.date.weekday)} ${_shortMonthName(day.date.month)} ${day.date.day}';
    final hasData = day.logged;

    final chips = hasData
        ? [
            ('kcal', day.totalKcal.toString()),
            ('protein', '${day.totalProteinG.toStringAsFixed(0)}g'),
            ('workouts', '${day.workoutCount}'),
            ('steps', '—'),
          ]
        : <(String, String)>[];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inkWithOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasData ? '${_dayInitials[i]} · $label' : '${_dayInitials[i]} · no entry',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasData
                ? (day.note != null ? '"${day.note}"' : 'No note yet.')
                : 'Quiet day. That\'s allowed.',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: hasData && day.note == null
                  ? AppColors.inkWithOpacity(0.4)
                  : AppColors.ink,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentWithOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${s.$1} ',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkWithOpacity(0.55),
                              ),
                            ),
                            TextSpan(
                              text: s.$2,
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightCard(AsyncValue<Map<String, double>> weightsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text('WEIGHT TREND',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkWithOpacity(0.4),
                  letterSpacing: 1.5,
                )),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bubbleAI,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.inkWithOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12)
              ],
            ),
            child: weightsAsync.when(
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => Text(
                'Could not load weight data.',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 13,
                  color: AppColors.inkWithOpacity(0.4),
                ),
              ),
              data: (weightsMap) => _buildWeightContent(weightsMap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightContent(Map<String, double> weightsMap) {
    final monday = mondayOfCurrentWeek();
    final series = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return weightsMap[fmtDate(day)];
    });

    final nonNull = series.whereType<double>().toList();
    final currentWeight = nonNull.isNotEmpty ? nonNull.last : null;
    final firstWeight = nonNull.isNotEmpty ? nonNull.first : null;
    final delta = (currentWeight != null && firstWeight != null && nonNull.length > 1)
        ? currentWeight - firstWeight
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: currentWeight != null
                      ? currentWeight.toStringAsFixed(1)
                      : '—',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.7,
                  ),
                ),
                TextSpan(
                  text: ' kg',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkWithOpacity(0.4),
                  ),
                ),
              ]),
            ),
            if (delta != null)
              Text(
                '${delta < 0 ? '↓' : '↑'} ${delta.abs().toStringAsFixed(1)}kg this week',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        WeightChart(data: series, goal: _goal),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showLogWeightSheet,
              child: Text('+ Log weight',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: -0.1,
                  )),
            ),
            Text('goal ${_goal.toStringAsFixed(1)}kg',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkWithOpacity(0.4),
                )),
          ],
        ),
      ],
    );
  }

  void _showLogWeightSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log weight',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink),
              decoration: InputDecoration(
                labelText: 'Weight in kg',
                labelStyle: GoogleFonts.bricolageGrotesque(
                    color: AppColors.inkWithOpacity(0.5)),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.inkWithOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final val = double.tryParse(controller.text.trim());
                  if (val == null || val <= 0) return;
                  final repo = ref.read(weightLogRepositoryProvider);
                  final nav = Navigator.of(ctx);
                  await repo.create(WeightLogCreate(weightKg: val));
                  if (!mounted) return;
                  nav.pop();
                  ref.invalidate(weekWeightLogsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Save',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/app/weekly-report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Open your weekly report card',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  )),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  String _shortMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
