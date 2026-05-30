import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../features/food_logs/data/food_log_models.dart';
import '../../../../features/workouts/data/workout_models.dart';
import '../../data/daily_note_repository.dart';
import '../../data/progress_models.dart';

DateTime mondayOfCurrentWeek() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1));
}

String fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Food logs + workouts + AI notes for each day of the current week (Mon–Sun).
final weekProgressProvider = FutureProvider.autoDispose<List<DayProgress>>((ref) async {
  final foodRepo = ref.read(foodLogRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);
  final noteRepo = ref.read(dailyNoteRepositoryProvider);

  final monday = mondayOfCurrentWeek();
  final days = List.generate(7, (i) => monday.add(Duration(days: i)));

  return Future.wait(days.map((day) => _fetchDay(
        day: day,
        foodRepo: foodRepo,
        workoutRepo: workoutRepo,
        noteRepo: noteRepo,
      )));
});

Future<DayProgress> _fetchDay({
  required DateTime day,
  required dynamic foodRepo,
  required dynamic workoutRepo,
  required DailyNoteRepository noteRepo,
}) async {
  final results = await Future.wait([
    (foodRepo as dynamic).listByDate(day) as Future<List<FoodLogResponse>>,
    (workoutRepo as dynamic).list(date: day) as Future<List<WorkoutResponse>>,
    noteRepo.getByDate(day),
  ]);

  final foodLogs = results[0] as List<FoodLogResponse>;
  final workouts = results[1] as List<WorkoutResponse>;
  final note = results[2] as dynamic;

  return DayProgress(
    date: day,
    logged: foodLogs.isNotEmpty || workouts.isNotEmpty,
    totalKcal: foodLogs.fold(0, (sum, f) => sum + f.calories),
    totalProteinG: foodLogs.fold(0.0, (sum, f) => sum + (f.proteinG ?? 0.0)),
    workoutCount: workouts.length,
    note: note?.note as String?,
  );
}

/// Food logs + workouts + AI note for yesterday.
final yesterdayProgressProvider = FutureProvider.autoDispose<DayProgress>((ref) async {
  final foodRepo = ref.read(foodLogRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);
  final noteRepo = ref.read(dailyNoteRepositoryProvider);

  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

  return _fetchDay(day: yesterday, foodRepo: foodRepo, workoutRepo: workoutRepo, noteRepo: noteRepo);
});

/// Weight logs for the current week → Map<'YYYY-MM-DD', weightKg>.
/// Latest entry wins when multiple are logged on the same day.
final weekWeightLogsProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final repo = ref.read(weightLogRepositoryProvider);
  final monday = mondayOfCurrentWeek();
  final sunday = monday.add(const Duration(days: 6));
  final logs = await repo.listByRange(monday, sunday);
  final map = <String, double>{};
  for (final log in logs) {
    map[fmtDate(log.loggedAt)] = log.weightKg;
  }
  return map;
});
