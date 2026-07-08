import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/units.dart';
import '../../../shared/widgets/composer.dart';
import '../../../shared/widgets/trend_line.dart';
import '../../conversation/presentation/conversation_screen.dart';
import '../../food_logs/presentation/meals_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../quick_log/quick_log_sheet.dart';
import '../../tweaks/tweaks_screen.dart';
import '../../voice/presentation/voice_screen.dart';
import '../../workouts/presentation/workout_screens.dart';
import 'today_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  void _openProgress(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
  }

  String _dateLine(int streak) {
    final date = capsDate(DateTime.now());
    if (streak < 2) return date;
    return '$date · ${streak >= 14 ? '14+' : streak} DAYS LOGGED';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wz = context.wz;
    final snapshot = ref.watch(todayProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull ?? 0;

    final kcal = snapshot?.kcalToday ?? 0;
    final whisper =
        snapshot?.whisper ?? "Say what you ate — I'll do the numbers.";
    final weightLbs = snapshot?.latestWeightKg == null
        ? null
        : Units.kgToLbs(snapshot!.latestWeightKg!);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -300) _openProgress(context);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TweaksScreen()),
                  ),
                  child: Text(
                    _dateLine(streak),
                    style: WhoomzType.caps.copyWith(color: wz.whisper),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MealsScreen()),
                  ),
                  onLongPress: () =>
                      showQuickLog(context, initial: QuickLogTab.meal),
                  child: AnimatedSwitcher(
                    duration: Motion.settle,
                    switchInCurve: Motion.spring,
                    child: Text(
                      formatKcal(kcal),
                      key: ValueKey(kcal),
                      style: WhoomzType.display.copyWith(color: wz.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot?.macrosLine == null
                      ? 'KCAL TODAY'
                      : 'KCAL TODAY · ${snapshot!.macrosLine}',
                  style: WhoomzType.caps.copyWith(color: wz.whisper),
                ),
                const SizedBox(height: 16),
                Text(
                  whisper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WhoomzType.body.copyWith(color: wz.whisper),
                ),
                const Spacer(),
                if (snapshot != null && snapshot.weightSeriesKg.length >= 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TrendLine(
                      values: snapshot.weightSeriesKg,
                      height: 56,
                      showDots: false,
                    ),
                  ),
                if (weightLbs != null)
                  _WeightMetric(
                    lbs: weightLbs,
                    deltaKg: snapshot?.weekDeltaKg,
                    onTap: () => _openProgress(context),
                    onLongPress: () =>
                        showQuickLog(context, initial: QuickLogTab.weight),
                  ),
                if (snapshot?.workoutLine != null) ...[
                  const SizedBox(height: 32),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkoutsScreen()),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORKOUT',
                          style: WhoomzType.caps.copyWith(color: wz.whisper),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot!.workoutLine!,
                          style: WhoomzType.body.copyWith(color: wz.ink),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Composer(
                    hint: 'Ask Whoomz anything',
                    readOnly: true,
                    onTap: () => Navigator.of(context).push(
                      fadeUpRoute(const ConversationScreen(autofocus: true)),
                    ),
                    onVoice: () => Navigator.of(
                      context,
                    ).push(fadeUpRoute(const VoiceScreen())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightMetric extends StatelessWidget {
  const _WeightMetric({
    required this.lbs,
    this.deltaKg,
    this.onTap,
    this.onLongPress,
  });

  final double lbs;
  final double? deltaKg;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  String? get _deltaLine {
    if (deltaKg == null) return null;
    final deltaLbs = Units.kgToLbs(deltaKg!);
    if (deltaLbs.abs() < 0.05) return 'Holding steady this week';
    final direction = deltaLbs < 0 ? 'Down' : 'Up';
    return '$direction ${formatLbs(deltaLbs.abs())} this week';
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: formatLbs(lbs),
              style: WhoomzType.metric.copyWith(color: wz.ink),
              children: [
                TextSpan(
                  text: '  lbs',
                  style: WhoomzType.body.copyWith(color: wz.whisper),
                ),
              ],
            ),
          ),
          if (_deltaLine != null) ...[
            const SizedBox(height: 4),
            Text(
              _deltaLine!,
              style: WhoomzType.body.copyWith(color: wz.whisper),
            ),
          ],
        ],
      ),
    );
  }
}
