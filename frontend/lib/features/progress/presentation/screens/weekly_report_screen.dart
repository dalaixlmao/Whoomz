import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/whoomz_wordmark.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/progress_models.dart';
import '../providers/progress_providers.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(weekProgressProvider);
    final userName = ref.watch(
      authNotifierProvider.select((s) => s.user?.name ?? 'You'),
    );

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cream),
          ),
          error: (_, _) => Center(
            child: Text(
              'Could not load weekly report.',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14, color: AppColors.cream.withValues(alpha: 0.6)),
            ),
          ),
          data: (week) => _buildContent(context, week, userName),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<DayProgress> week, String userName) {
    final daysLogged = week.where((d) => d.logged).length;
    final loggedDays = week.where((d) => d.logged).toList();
    final avgKcal = loggedDays.isEmpty
        ? 0
        : (loggedDays.fold(0, (s, d) => s + d.totalKcal) / loggedDays.length)
            .round();
    final mostActive = _mostActiveDay(week);
    final streak = _streak(week);

    final monday = mondayOfCurrentWeek();
    final sunday = monday.add(const Duration(days: 6));
    final weekLabel =
        '${_shortMonthName(monday.month)} ${monday.day} – ${_shortMonthName(sunday.month)} ${sunday.day}';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.cream),
                  label: Text('Back',
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream)),
                ),
                Text('POSTCARD',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: AppColors.cream.withValues(alpha: 0.6))),
              ],
            ),
          ),

          // Postcard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Transform.rotate(
              angle: -0.021,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 50,
                        offset: const Offset(0, 20)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Opacity(
                        opacity: 0.06,
                        child: WMark(size: 220, color: AppColors.ink),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: FractionallySizedBox(
                        widthFactor: 0.38,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CustomPaint(
                            size: const Size(1, double.infinity),
                            painter: _DashedLinePainter(),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Week of $weekLabel',
                            style: GoogleFonts.bricolageGrotesque(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkWithOpacity(0.55),
                                letterSpacing: 1.6)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'Your week,\nWhoomz-style ',
                              style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.6,
                                  height: 1.05),
                            ),
                            const TextSpan(
                                text: '🎨',
                                style: TextStyle(fontSize: 22)),
                          ]),
                        ),
                        const SizedBox(height: 22),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.8,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          children: [
                            _statCell('Days logged', '$daysLogged/7'),
                            _statCell('Avg calories',
                                avgKcal > 0 ? _fmtNum(avgKcal) : '—'),
                            _statCell('Most active', mostActive),
                            _statCell(
                                'Streak', streak > 0 ? '$streak 🔥' : '—'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentWithOpacity(0.1),
                            border: Border.all(
                                color: AppColors.accentWithOpacity(0.25),
                                width: 1.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const WMark(size: 20, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _aiMessage(daysLogged, streak),
                                  style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                      height: 1.4,
                                      letterSpacing: -0.05,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FOR',
                                    style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkWithOpacity(0.4),
                                        letterSpacing: 1.4)),
                                const SizedBox(height: 2),
                                Text(userName,
                                    style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                        letterSpacing: -0.3)),
                              ],
                            ),
                            _buildStamp(streak),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cream,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: Text('Share story 🎨',
                    style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: AppColors.ink)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('exports as 9:16 instagram story',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppColors.cream.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.inkWithOpacity(0.4),
                letterSpacing: 1.4)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
                height: 1.1)),
      ],
    );
  }

  Widget _buildStamp(int streak) {
    return Container(
      width: 64,
      height: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WhoomzWordmark(size: 11, color: Colors.white, accentColor: Colors.white),
          const WMark(size: 28, color: Colors.white),
          Text(streak > 0 ? '$streak-DAY STREAK' : 'THIS WEEK',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  String _mostActiveDay(List<DayProgress> week) {
    final withWorkouts = week.where((d) => d.workoutCount > 0).toList();
    if (withWorkouts.isEmpty) return '—';
    final best =
        withWorkouts.reduce((a, b) => a.workoutCount >= b.workoutCount ? a : b);
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[(best.date.weekday - 1).clamp(0, 6)];
  }

  int _streak(List<DayProgress> week) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int count = 0;
    for (int i = 6; i >= 0; i--) {
      final day = week[i];
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (dayDate.isAfter(todayDate)) continue;
      if (day.logged) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  String _aiMessage(int daysLogged, int streak) {
    if (daysLogged == 7) {
      return 'A perfect week. Every single day, you showed up. That\'s not discipline — that\'s identity. 🎨';
    } else if (daysLogged >= 5) {
      return 'You showed up $daysLogged out of seven days. That\'s not a streak — that\'s a habit. Quiet, steady, real. See you next week. 🎨';
    } else if (daysLogged >= 3) {
      return '$daysLogged days logged. Life gets in the way — the fact that you kept coming back is what matters. 🎨';
    } else {
      return 'Every journey has slower weeks. Start fresh tomorrow. 🎨';
    }
  }

  String _fmtNum(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  String _shortMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkWithOpacity(0.25)
      ..strokeWidth = 1.5;
    const dashH = 4.0;
    const gapH = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashH), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
