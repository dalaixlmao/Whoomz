import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/units.dart';
import '../../../shared/widgets/trend_line.dart';
import '../../quick_log/quick_log_sheet.dart';
import 'progress_providers.dart';

enum _Metric { weight, calories }

/// 1f — no grid, no axes: the line, the dots, one value.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _Metric _metric = _Metric.weight;

  @override
  Widget build(BuildContext context) {
    final wz = context.wz;
    final points =
        (_metric == _Metric.weight
                ? ref.watch(weightSeriesProvider)
                : ref.watch(calorieSeriesProvider))
            .valueOrNull ??
        const <SeriesPoint>[];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    child: Text(
                      '‹ TODAY',
                      style: WhoomzType.caps.copyWith(color: wz.whisper),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetricTab(
                    label: 'Weight',
                    active: _metric == _Metric.weight,
                    onTap: () => setState(() => _metric = _Metric.weight),
                  ),
                  const SizedBox(width: 24),
                  _MetricTab(
                    label: 'Calories',
                    active: _metric == _Metric.calories,
                    onTap: () => setState(() => _metric = _Metric.calories),
                  ),
                ],
              ),
              const Spacer(),
              if (points.isEmpty)
                Text(
                  _metric == _Metric.weight
                      ? 'Nothing here yet — say your weight and I\'ll log it.'
                      : 'Nothing here yet — say what you ate.',
                  style: WhoomzType.body.copyWith(color: wz.whisper),
                )
              else ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => showQuickLog(
                    context,
                    initial: _metric == _Metric.weight
                        ? QuickLogTab.weight
                        : QuickLogTab.meal,
                  ),
                  child: Text(
                    _currentLabel(points),
                    style: WhoomzType.display.copyWith(color: wz.ink),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _deltaLabel(points),
                  style: WhoomzType.body.copyWith(color: wz.whisper),
                ),
                const Spacer(),
                TrendLine(
                  values: [for (final p in points) p.value],
                  height: 200,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prettyDate(points.first.date).toUpperCase(),
                      style: WhoomzType.caps.copyWith(color: wz.faint),
                    ),
                    Text(
                      prettyDate(points.last.date).toUpperCase(),
                      style: WhoomzType.caps.copyWith(color: wz.faint),
                    ),
                  ],
                ),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  String _currentLabel(List<SeriesPoint> points) {
    final current = points.last.value;
    return _metric == _Metric.weight
        ? formatLbs(Units.kgToLbs(current))
        : formatKcal(current);
  }

  String _deltaLabel(List<SeriesPoint> points) {
    if (_metric == _Metric.calories) {
      final avg =
          points.fold<double>(0, (sum, p) => sum + p.value) / points.length;
      return 'Avg ${formatKcal(avg)} kcal over ${points.length} days';
    }
    if (points.length < 2) return 'First log — keep going.';
    final deltaLbs =
        Units.kgToLbs(points.last.value) - Units.kgToLbs(points.first.value);
    final since = prettyDate(points.first.date);
    if (deltaLbs.abs() < 0.05) return 'Holding steady since $since';
    final arrow = deltaLbs < 0 ? '↓' : '↑';
    return '$arrow ${formatLbs(deltaLbs.abs())} lbs since $since';
  }
}

class _MetricTab extends StatelessWidget {
  const _MetricTab({
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
      child: AnimatedDefaultTextStyle(
        duration: Motion.settle,
        curve: Motion.spring,
        style: WhoomzType.metric.copyWith(
          fontSize: 34,
          color: active ? wz.ink : wz.faint,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label),
        ),
      ),
    );
  }
}
