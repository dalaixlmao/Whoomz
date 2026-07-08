import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/app/theme.dart';
import 'package:whoomz/features/food_logs/data/food_log_models.dart';
import 'package:whoomz/features/today/presentation/today_providers.dart';
import 'package:whoomz/features/today/presentation/today_screen.dart';

TodaySnapshot _snapshot() => TodaySnapshot(
  kcalToday: 1284,
  foods: [
    FoodLog(
      id: '1',
      name: 'Chicken bowl',
      calories: 610,
      proteinG: 42,
      carbsG: 55,
      fatG: 18,
      mealType: MealType.lunch,
      loggedAt: DateTime(2026, 7, 7, 12),
    ),
  ],
  weightSeriesKg: const [78.8, 78.6, 78.9, 78.4, 78.2],
  latestWeightKg: 78.2,
  weekDeltaKg: -0.27,
  whisper: 'Down 0.6 this week — keep the easy pace.',
  workoutLine: 'Tonight — easy 5K, keep it conversational.',
);

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWith((ref) async => _snapshot()),
          streakProvider.overrideWith((ref) async => 12),
        ],
        child: MaterialApp(
          theme: whoomzTheme(Brightness.light),
          home: const TodayScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the number, the whisper, and the line', (tester) async {
    await pump(tester);

    expect(find.text('1,284'), findsOneWidget);
    expect(
      find.text('Down 0.6 this week — keep the easy pace.'),
      findsOneWidget,
    );
    expect(find.text('WORKOUT'), findsOneWidget);
    expect(
      find.text('Tonight — easy 5K, keep it conversational.'),
      findsOneWidget,
    );
    expect(find.textContaining('172.4'), findsOneWidget);
  });

  testWidgets('folds macros into the kcal caps line', (tester) async {
    await pump(tester);

    expect(find.text('KCAL TODAY · P 42 · C 55 · F 18'), findsOneWidget);
  });

  testWidgets('folds the streak into the date line', (tester) async {
    await pump(tester);

    expect(find.textContaining('· 12 DAYS LOGGED'), findsOneWidget);
  });

  testWidgets('composer invites the conversation', (tester) async {
    await pump(tester);

    expect(find.text('Ask Whoomz anything'), findsOneWidget);
  });
}
