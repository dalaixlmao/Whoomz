import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/units.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../quick_log/quick_log_sheet.dart';
import '../../today/presentation/today_providers.dart';
import '../data/food_log_models.dart';

/// 2a — Meals · Today. The day, correctable: swipe to erase a mistake.
class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  /// Rows leave the tree the instant they're dismissed; the provider
  /// refetch confirms afterwards.
  final Set<String> _removed = {};

  Future<void> _delete(FoodLog log) async {
    setState(() => _removed.add(log.id));
    try {
      await ref.read(foodLogRepositoryProvider).delete(log.id);
    } finally {
      ref.invalidate(todayProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(calorieSeriesProvider);
      ref.invalidate(recentFoodsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final snapshot = ref.watch(todayProvider).valueOrNull;
    final foods = (snapshot?.foods ?? const <FoodLog>[])
        .where((f) => !_removed.contains(f.id))
        .toList();
    final total = foods.fold(0, (sum, f) => sum + f.calories);

    final byMeal = <MealType, List<FoodLog>>{};
    for (final food in foods) {
      byMeal.putIfAbsent(food.mealType, () => []).add(food);
    }

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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatKcal(total),
                    style: WhoomzType.metric.copyWith(color: wz.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KCAL · ${capsDate(DateTime.now())}',
                    style: WhoomzType.caps.copyWith(color: wz.whisper),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: foods.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Nothing logged yet — say what you ate.',
                        style: WhoomzType.body.copyWith(color: wz.whisper),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        for (final meal in MealType.values)
                          if (byMeal.containsKey(meal)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                              child: Text(
                                meal.name.toUpperCase(),
                                style: WhoomzType.caps.copyWith(
                                  color: wz.whisper,
                                ),
                              ),
                            ),
                            for (final log in byMeal[meal]!)
                              _MealRow(log: log, onDelete: () => _delete(log)),
                          ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showQuickLog(context, initial: QuickLogTab.meal),
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+ QUICK LOG',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
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

class _MealRow extends StatelessWidget {
  const _MealRow({required this.log, required this.onDelete});

  final FoodLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: wz.ink,
        child: Text('DELETE', style: WhoomzType.caps.copyWith(color: wz.onInk)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                log.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WhoomzType.body.copyWith(color: wz.ink),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              formatKcal(log.calories),
              style: WhoomzType.body.copyWith(
                color: wz.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
