import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../food_logs/data/food_log_models.dart';
import '../../weight/data/weight_log_models.dart';
import '../../workouts/data/workout_models.dart';

class TodaySnapshot {
  const TodaySnapshot({
    required this.kcalToday,
    required this.foods,
    required this.weightSeriesKg,
    this.latestWeightKg,
    this.weekDeltaKg,
    this.whisper,
    this.workoutLine,
  });

  final int kcalToday;
  final List<FoodLog> foods;

  /// Oldest→newest, last 14 days — the home sparkline.
  final List<double> weightSeriesKg;
  final double? latestWeightKg;
  final double? weekDeltaKg;

  /// The daily note — one quiet line under the number.
  final String? whisper;
  final String? workoutLine;

  /// "P 84 · C 210 · F 56" — second whisper under the number; null when the
  /// day's logs carry no macro estimates.
  String? get macrosLine {
    double protein = 0, carbs = 0, fat = 0;
    for (final f in foods) {
      protein += f.proteinG ?? 0;
      carbs += f.carbsG ?? 0;
      fat += f.fatG ?? 0;
    }
    if (protein + carbs + fat == 0) return null;
    return 'P ${protein.round()} · C ${carbs.round()} · F ${fat.round()}';
  }
}

/// Consecutive days with at least one food log, walking back from today
/// (an unlogged today doesn't break the streak). One request per day of
/// streak, capped at 14.
final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(foodLogRepositoryProvider);
  final today = DateTime.now();
  var streak = 0;
  for (var i = 0; i < 14; i++) {
    final logs = await repo.listByDate(today.subtract(Duration(days: i)));
    if (logs.isEmpty) {
      if (i == 0) continue;
      break;
    }
    streak++;
  }
  return streak;
});

final todayProvider = FutureProvider<TodaySnapshot>((ref) async {
  final now = DateTime.now();

  final results = await Future.wait<Object?>([
    _guard(() => ref.read(foodLogRepositoryProvider).listByDate(now)),
    _guard(
      () => ref
          .read(weightLogRepositoryProvider)
          .listRange(now.subtract(const Duration(days: 14)), now),
    ),
    _guard(() => ref.read(dailyNoteRepositoryProvider).latestNote()),
    _guard(() => ref.read(workoutRepositoryProvider).list()),
  ]);

  final foods = (results[0] as List<FoodLog>?) ?? const <FoodLog>[];
  final weights = (results[1] as List<WeightLog>?) ?? const <WeightLog>[];
  final whisper = results[2] as String?;
  final workouts = (results[3] as List<Workout>?) ?? const <Workout>[];

  final sorted = [...weights]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  final latest = sorted.isEmpty ? null : sorted.last.weightKg;

  double? weekDelta;
  if (sorted.length >= 2) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final baseline = sorted.firstWhere(
      (w) => !w.loggedAt.isBefore(weekAgo),
      orElse: () => sorted.first,
    );
    weekDelta = latest! - baseline.weightKg;
  }

  return TodaySnapshot(
    kcalToday: foods.fold(0, (sum, f) => sum + f.calories),
    foods: foods,
    weightSeriesKg: [for (final w in sorted) w.weightKg],
    latestWeightKg: latest,
    weekDeltaKg: weekDelta,
    whisper: whisper,
    workoutLine: _workoutLine(workouts),
  );
});

String? _workoutLine(List<Workout> workouts) {
  if (workouts.isEmpty) return null;
  final active = workouts.where((w) => w.isInProgress).firstOrNull;
  if (active != null) return '${active.name} — in progress.';
  final latest = [...workouts]
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final last = latest.first;
  final days = DateTime.now().difference(last.startedAt).inDays;
  final when = days == 0
      ? 'Today'
      : (days == 1 ? 'Yesterday' : '$days days ago');
  return '$when — ${last.name}.';
}

Future<T?> _guard<T>(Future<T?> Function() fetch) async {
  try {
    return await fetch();
  } catch (_) {
    return null;
  }
}
