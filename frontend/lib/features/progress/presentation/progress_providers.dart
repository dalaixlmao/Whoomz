import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class SeriesPoint {
  const SeriesPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Weight logs over the last 30 days, oldest→newest, in kg.
final weightSeriesProvider = FutureProvider<List<SeriesPoint>>((ref) async {
  final now = DateTime.now();
  final logs = await ref
      .read(weightLogRepositoryProvider)
      .listRange(now.subtract(const Duration(days: 30)), now);
  final sorted = [...logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  return [for (final log in sorted) SeriesPoint(log.loggedAt, log.weightKg)];
});

/// Daily kcal totals for the last 7 days, oldest→newest.
final calorieSeriesProvider = FutureProvider<List<SeriesPoint>>((ref) async {
  final repo = ref.read(foodLogRepositoryProvider);
  final today = DateTime.now();
  final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
  final logsByDay = await Future.wait(days.map(repo.listByDate));
  return [
    for (var i = 0; i < days.length; i++)
      SeriesPoint(
        days[i],
        logsByDay[i].fold<double>(0, (sum, f) => sum + f.calories),
      ),
  ];
});
