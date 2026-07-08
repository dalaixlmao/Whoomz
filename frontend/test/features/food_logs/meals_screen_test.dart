import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whoomz/app/theme.dart';
import 'package:whoomz/core/providers.dart';
import 'package:whoomz/features/food_logs/data/food_log_models.dart';
import 'package:whoomz/features/food_logs/data/food_log_repository.dart';
import 'package:whoomz/features/food_logs/presentation/meals_screen.dart';
import 'package:whoomz/features/today/presentation/today_providers.dart';

class _MockFoodLogRepository extends Mock implements FoodLogRepository {}

FoodLog _log(String id, String name, int kcal, MealType meal) => FoodLog(
  id: id,
  name: name,
  calories: kcal,
  mealType: meal,
  loggedAt: DateTime(2026, 7, 7, 12),
);

void main() {
  late _MockFoodLogRepository repository;

  setUp(() {
    repository = _MockFoodLogRepository();
  });

  Future<void> pump(WidgetTester tester, List<FoodLog> foods) async {
    final snapshot = TodaySnapshot(
      kcalToday: foods.fold(0, (sum, f) => sum + f.calories),
      foods: foods,
      weightSeriesKg: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWith((ref) async => snapshot),
          foodLogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: whoomzTheme(Brightness.light),
          home: const MealsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('groups the day by meal with kcal per row', (tester) async {
    await pump(tester, [
      _log('1', 'Yogurt bowl', 190, MealType.breakfast),
      _log('2', 'Chicken bowl', 610, MealType.lunch),
      _log('3', 'Samosa', 180, MealType.lunch),
    ]);

    expect(find.text('980'), findsOneWidget);
    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(find.text('LUNCH'), findsOneWidget);
    expect(find.text('DINNER'), findsNothing);
    expect(find.text('Chicken bowl'), findsOneWidget);
    expect(find.text('610'), findsOneWidget);
  });

  testWidgets('swipe left deletes the log', (tester) async {
    when(() => repository.delete(any())).thenAnswer((_) async {});
    await pump(tester, [_log('3', 'Samosa', 180, MealType.lunch)]);

    await tester.drag(find.text('Samosa'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => repository.delete('3')).called(1);
  });

  testWidgets('empty day points back to the conversation', (tester) async {
    await pump(tester, const []);

    expect(find.text('Nothing logged yet — say what you ate.'), findsOneWidget);
  });
}
