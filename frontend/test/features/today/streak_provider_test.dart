import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whoomz/core/providers.dart';
import 'package:whoomz/core/units.dart';
import 'package:whoomz/features/food_logs/data/food_log_models.dart';
import 'package:whoomz/features/food_logs/data/food_log_repository.dart';
import 'package:whoomz/features/today/presentation/today_providers.dart';

class _MockFoodLogRepository extends Mock implements FoodLogRepository {}

FoodLog _log(DateTime day) => FoodLog(
  id: day.toIso8601String(),
  name: 'Meal',
  calories: 500,
  mealType: MealType.lunch,
  loggedAt: day,
);

void main() {
  late _MockFoodLogRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockFoodLogRepository();
    container = ProviderContainer(
      overrides: [foodLogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  void stubDays(Set<int> loggedDaysAgo) {
    final today = DateTime.now();
    when(() => repository.listByDate(any())).thenAnswer((invocation) async {
      final day = invocation.positionalArguments.first as DateTime;
      final daysAgo = DateTime(
        today.year,
        today.month,
        today.day,
      ).difference(DateTime(day.year, day.month, day.day)).inDays;
      return loggedDaysAgo.contains(daysAgo) ? [_log(day)] : [];
    });
  }

  test('counts consecutive logged days back from today', () async {
    stubDays({0, 1, 2});
    expect(await container.read(streakProvider.future), 3);
  });

  test('an unlogged today does not break the streak', () async {
    stubDays({1, 2, 3, 4});
    expect(await container.read(streakProvider.future), 4);
  });

  test('a gap ends the streak', () async {
    stubDays({0, 1, 3, 4});
    expect(await container.read(streakProvider.future), 2);
  });

  test('no logs means no streak', () async {
    stubDays({});
    expect(await container.read(streakProvider.future), 0);
    // Walk-back stops after today + yesterday when both are empty.
    verify(() => repository.listByDate(any())).called(2);
  });

  test('stops querying at the gap', () async {
    stubDays({0, 1});
    await container.read(streakProvider.future);
    verify(() => repository.listByDate(any())).called(3);
  });

  test('apiDate is used for day queries', () {
    expect(apiDate(DateTime(2026, 7, 6)), '2026-07-06');
  });
}
