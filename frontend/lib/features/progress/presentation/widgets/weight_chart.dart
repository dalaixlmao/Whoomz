import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.data,
    required this.goal,
    this.accent = AppColors.accent,
  });

  final List<double?> data;
  final double goal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final nonNull = data.whereType<double>().toList();

    if (nonNull.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No weight logged yet',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.inkWithOpacity(0.35),
            ),
          ),
        ),
      );
    }

    final spots = data.asMap().entries
        .where((e) => e.value != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value!))
        .toList();

    final minY = ([...nonNull, goal].reduce((a, b) => a < b ? a : b) - 0.5).floorToDouble();
    final maxY = ([...nonNull, goal].reduce((a, b) => a > b ? a : b) + 0.5).ceilToDouble();

    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.inkWithOpacity(0.07),
              strokeWidth: 1,
              dashArray: [2, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 0,
                getTitlesWidget: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goal,
                color: AppColors.inkWithOpacity(0.15),
                strokeWidth: 1,
                dashArray: [2, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'GOAL',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, barData, index) => FlDotCirclePainter(
                  radius: index == spots.length - 1 ? 4 : 2.5,
                  color: accent,
                  strokeWidth: index == spots.length - 1 ? 2 : 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
