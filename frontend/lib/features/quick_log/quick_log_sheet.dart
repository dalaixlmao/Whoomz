import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/units.dart';
import '../food_logs/data/food_log_models.dart';
import '../progress/presentation/progress_providers.dart';
import '../today/presentation/today_providers.dart';
import 'keypad_value.dart';

enum QuickLogTab { meal, weight }

/// 1e — keypad sheet · under 5 seconds, one gesture to dismiss.
Future<void> showQuickLog(
  BuildContext context, {
  QuickLogTab initial = QuickLogTab.meal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: WhoomzPalette.light.ink.withValues(alpha: 0.45),
    builder: (_) => _QuickLogSheet(initial: initial),
  );
}

/// Two most recent foods, one tap to refill.
final recentFoodsProvider = FutureProvider<List<FoodLog>>((ref) async {
  final repo = ref.read(foodLogRepositoryProvider);
  final now = DateTime.now();
  final days = await Future.wait([
    repo.listByDate(now),
    repo.listByDate(now.subtract(const Duration(days: 1))),
  ]);
  final all = [...days[0], ...days[1]]
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  final seen = <String>{};
  return [
    for (final f in all)
      if (seen.add(f.name.toLowerCase())) f,
  ].take(2).toList();
});

class _QuickLogSheet extends ConsumerStatefulWidget {
  const _QuickLogSheet({required this.initial});

  final QuickLogTab initial;

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  late QuickLogTab _tab = widget.initial;
  late final KeypadValue _kcal = KeypadValue(maxIntDigits: 4);
  late final KeypadValue _lbs = KeypadValue(
    allowDecimal: true,
    maxIntDigits: 3,
  );
  late MealType _meal = MealType.forHour(DateTime.now().hour);

  String? _chipName;
  bool _busy = false;
  bool _failed = false;

  KeypadValue get _value => _tab == QuickLogTab.meal ? _kcal : _lbs;

  bool get _submittable => !_busy && !_value.isEmpty && (_value.value ?? 0) > 0;

  void _tap(void Function() mutate) => setState(() {
    _failed = false;
    mutate();
  });

  Future<void> _submit() async {
    if (!_submittable) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (_tab == QuickLogTab.meal) {
        await ref
            .read(foodLogRepositoryProvider)
            .create(
              FoodLogCreate(
                name: _chipName ?? 'Quick add',
                calories: _kcal.value!.toInt(),
                mealType: _meal,
              ),
            );
      } else {
        await ref
            .read(weightLogRepositoryProvider)
            .create(Units.lbsToKg(_lbs.value!));
      }
      ref.invalidate(todayProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(weightSeriesProvider);
      ref.invalidate(calorieSeriesProvider);
      ref.invalidate(recentFoodsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final recents = _tab == QuickLogTab.meal
        ? (ref.watch(recentFoodsProvider).valueOrNull ?? const <FoodLog>[])
        : const <FoodLog>[];

    return Container(
      decoration: BoxDecoration(
        color: wz.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: wz.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabLabel(
                label: 'MEAL',
                active: _tab == QuickLogTab.meal,
                onTap: () => _tap(() => _tab = QuickLogTab.meal),
              ),
              const SizedBox(width: 16),
              _TabLabel(
                label: 'WEIGHT',
                active: _tab == QuickLogTab.weight,
                onTap: () => _tap(() => _tab = QuickLogTab.weight),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _value.display,
              style: WhoomzType.display.copyWith(
                color: _value.isEmpty ? wz.faint : wz.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tab == QuickLogTab.meal
                ? () => _tap(() {
                    final next = (_meal.index + 1) % MealType.values.length;
                    _meal = MealType.values[next];
                  })
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _failed
                    ? "COULDN'T SAVE — TRY AGAIN"
                    : _tab == QuickLogTab.meal
                    ? 'KCAL · ${_meal.name.toUpperCase()}'
                    : 'LBS · TODAY',
                style: WhoomzType.caps.copyWith(color: wz.whisper),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: recents.isEmpty
                ? null
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final food in recents)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _Chip(
                            label:
                                '${food.name} · ${formatKcal(food.calories)}',
                            onTap: () => _tap(() {
                              _kcal.set(food.calories.toDouble());
                              _chipName = food.name;
                            }),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.', '0', '⌫'],
          ])
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: _Key(
                      label: key,
                      visible: key != '.' || _tab == QuickLogTab.weight,
                      onTap: () => _tap(() {
                        switch (key) {
                          case '⌫':
                            _value.backspace();
                          case '.':
                            _value.addDot();
                          default:
                            _value.addDigit(key);
                            _chipName = null;
                        }
                      }),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _submit,
            child: AnimatedOpacity(
              duration: Motion.quick,
              opacity: _submittable ? 1 : 0.35,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: wz.accent,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tab == QuickLogTab.meal
                      ? 'Log ${_value.display} kcal'
                      : 'Log ${_value.display} lbs',
                  style: WhoomzType.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedDefaultTextStyle(
          duration: Motion.quick,
          style: WhoomzType.caps.copyWith(color: active ? wz.ink : wz.faint),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wz.hairline),
        ),
        child: Text(
          label,
          style: WhoomzType.body.copyWith(fontSize: 15, color: wz.ink),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.visible = true});

  final String label;
  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    if (!visible) return const SizedBox(height: 64);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Center(
          child: Text(
            label,
            style: WhoomzType.keypad.copyWith(
              color: wz.ink,
              fontSize: label == '⌫' ? 22 : 28,
            ),
          ),
        ),
      ),
    );
  }
}
