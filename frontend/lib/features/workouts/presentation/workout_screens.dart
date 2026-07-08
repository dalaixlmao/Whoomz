import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/units.dart';
import '../../today/presentation/today_providers.dart';
import '../data/workout_models.dart';

final workoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final workouts = await ref.read(workoutRepositoryProvider).list();
  return [...workouts]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
});

final workoutDetailProvider = FutureProvider.family<WorkoutDetail, String>(
  (ref, id) => ref.read(workoutRepositoryProvider).detail(id),
);

String _when(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days == 0) return 'TODAY';
  if (days == 1) return 'YESTERDAY';
  return prettyDate(date).toUpperCase();
}

String _durationLabel(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return '$minutes MIN';
  return '${duration.inHours}H ${minutes % 60}M';
}

/// 2c — Workout history: rhythm from spacing, no cards, no dividers.
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  Future<void> _finish(WidgetRef ref, Workout workout) async {
    await ref.read(workoutRepositoryProvider).finish(workout.id);
    ref.invalidate(workoutsProvider);
    ref.invalidate(todayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wz = context.wz;
    final workouts =
        ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[];
    final active = workouts.where((w) => w.isInProgress).toList();
    final done = workouts.where((w) => !w.isInProgress).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '‹ TODAY',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Text(
                'Workouts',
                style: WhoomzType.metric.copyWith(color: wz.ink),
              ),
            ),
            Expanded(
              child: workouts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No workouts yet — tell me when you start one.',
                        style: WhoomzType.body.copyWith(color: wz.whisper),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        for (final workout in [...active, ...done])
                          _WorkoutRow(
                            workout: workout,
                            onFinish: workout.isInProgress
                                ? () => _finish(ref, workout)
                                : null,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutRow extends ConsumerWidget {
  const _WorkoutRow({required this.workout, this.onFinish});

  final Workout workout;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wz = context.wz;
    final caps = workout.isInProgress
        ? 'IN PROGRESS'
        : [
            _when(workout.startedAt),
            if (workout.duration != null) _durationLabel(workout.duration!),
          ].join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WhoomzType.body.copyWith(color: wz.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caps,
                    style: WhoomzType.caps.copyWith(
                      color: workout.isInProgress ? wz.accent : wz.whisper,
                    ),
                  ),
                ],
              ),
            ),
            if (onFinish != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onFinish,
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'FINISH',
                      style: WhoomzType.caps.copyWith(color: wz.ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 2d — one workout, exercises in order; type does all the work.
class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wz = context.wz;
    final detail = ref.watch(workoutDetailProvider(workoutId)).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '‹ WORKOUTS',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                  ),
                ),
              ),
            ),
            if (detail == null)
              const Spacer()
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text(
                      detail.name,
                      style: WhoomzType.metric.copyWith(color: wz.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _when(detail.startedAt),
                        if (detail.duration != null)
                          _durationLabel(detail.duration!)
                        else
                          'IN PROGRESS',
                      ].join(' · '),
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                    if (detail.notes != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        detail.notes!,
                        style: WhoomzType.body.copyWith(color: wz.whisper),
                      ),
                    ],
                    for (final exercise in detail.exercises) ...[
                      const SizedBox(height: 32),
                      _ExerciseView(exercise: exercise),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseView extends StatelessWidget {
  const _ExerciseView({required this.exercise});

  final WorkoutExercise exercise;

  static String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  List<String> get _lines {
    final m = exercise.metrics;
    switch (exercise.trackingType) {
      case TrackingType.setsRepsWeight:
        final sets = (m['sets'] as List?) ?? const [];
        return [
          for (final set in sets.cast<Map<String, dynamic>>())
            '${set['reps']} × ${NumberFormat('#,##0.#').format(set['weight_kg'] ?? 0)} kg',
        ];
      case TrackingType.distanceDuration:
        final parts = <String>[];
        if (m['distance_km'] != null) parts.add('${m['distance_km']} km');
        if (m['duration_seconds'] != null) {
          parts.add(_clock(m['duration_seconds'] as int));
        }
        if (m['avg_heart_rate'] != null) {
          parts.add('${m['avg_heart_rate']} bpm');
        }
        return [parts.join(' · ')];
      case TrackingType.laps:
        final laps = (m['laps'] as List?) ?? const [];
        return [
          for (final lap in laps.cast<Map<String, dynamic>>())
            'LAP ${lap['lap_number']} · ${lap['lap_time_seconds']}s'
                '${lap['distance_m'] != null ? ' · ${lap['distance_m']} m' : ''}',
        ];
      case TrackingType.durationOnly:
        final seconds = m['duration_seconds'] as int?;
        return [if (seconds != null) _clock(seconds)];
      case TrackingType.freeform:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.exerciseName.toUpperCase(),
          style: WhoomzType.caps.copyWith(color: wz.whisper),
        ),
        const SizedBox(height: 8),
        for (final line in _lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: WhoomzType.body.copyWith(
                color: wz.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (exercise.notes != null)
          Text(
            exercise.notes!,
            style: WhoomzType.body.copyWith(color: wz.whisper),
          ),
      ],
    );
  }
}
