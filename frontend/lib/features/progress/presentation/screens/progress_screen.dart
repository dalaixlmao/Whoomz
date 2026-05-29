import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/w_mark.dart';
import '../widgets/weight_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int? _expandedDay;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _weekData = [
    (date: 11, label: 'Mon May 11', logged: true, note: 'Walked 8k. Skipped sugar. Felt clear.',
      stats: [('kcal', '1,820'), ('P', '92g'), ('steps', '8.1k')]),
    (date: 12, label: 'Tue May 12', logged: true, note: 'Big lunch with family. No regrets.',
      stats: [('kcal', '2,310'), ('P', '88g'), ('steps', '4.4k')]),
    (date: 13, label: 'Wed May 13', logged: true, note: 'Office day, lots of chai but moved.',
      stats: [('kcal', '1,940'), ('P', '76g'), ('steps', '6.7k')]),
    (date: 14, label: 'Thu May 14', logged: false, note: '',
      stats: <(String, String)>[]),
    (date: 15, label: 'Fri May 15', logged: true, note: 'Light dinner, went to bed early.',
      stats: [('kcal', '1,610'), ('P', '94g'), ('steps', '5.9k')]),
    (date: 16, label: 'Sat May 16', logged: true, note: 'Long walk + paratha brunch. Worth it.',
      stats: [('kcal', '2,050'), ('P', '82g'), ('steps', '11.2k')]),
    (date: 17, label: 'Sun May 17', logged: true, note: 'Quiet Sunday. Read, walked, ate dal.',
      stats: [('kcal', '1,720'), ('P', '90g'), ('steps', '7.3k')]),
  ];

  static const _weightSeries = [70.2, 69.9, 69.5, 69.1, 69.2, 68.7, 68.4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildWeekGrid(),
            _buildWeightCard(),
            _buildReportCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR JOURNAL',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.8,
            )),
          const SizedBox(height: 2),
          Text('This week',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: AppColors.ink, letterSpacing: -0.8, height: 1.1,
            )),
        ],
      ),
    );
  }

  Widget _buildWeekGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bubbleAI,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.inkWithOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Row(
              children: List.generate(7, (i) {
                final d = _weekData[i];
                final active = d.logged;
                final expanded = _expandedDay == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _expandedDay = expanded ? null : i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 7 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: active ? null : Border.all(
                          color: AppColors.inkWithOpacity(0.25),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: active
                            ? [BoxShadow(color: AppColors.accentWithOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_days[i],
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: active ? Colors.white.withValues(alpha: 0.75) : AppColors.inkWithOpacity(0.55),
                                  letterSpacing: 0.4,
                                )),
                              const SizedBox(height: 1),
                              Text('${d.date}',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 16, fontWeight: FontWeight.w800,
                                  color: active ? Colors.white : AppColors.inkWithOpacity(0.55),
                                  letterSpacing: -0.2,
                                )),
                              if (active) ...[
                                const SizedBox(height: 4),
                                WMark(size: 11, color: Colors.white.withValues(alpha: 0.9)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_expandedDay != null) _buildDayDetail(_expandedDay!),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(int i) {
    final d = _weekData[i];
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inkWithOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.logged ? '${_days[i]} · ${d.label}' : '${_days[i]} · no entry',
            style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            d.logged ? '"${d.note}"' : 'Quiet day. That\'s allowed.',
            style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.4, letterSpacing: -0.1),
          ),
          if (d.logged && d.stats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: d.stats.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${s.$1} ', style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkWithOpacity(0.55))),
                    TextSpan(text: s.$2, style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                ),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text('WEIGHT TREND',
              style: GoogleFonts.bricolageGrotesque(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkWithOpacity(0.4), letterSpacing: 1.5)),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bubbleAI,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.inkWithOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: '68.4', style: GoogleFonts.bricolageGrotesque(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.7)),
                        TextSpan(text: ' kg', style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkWithOpacity(0.4))),
                      ]),
                    ),
                    Text('↓ 0.6kg this week',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: 0.2)),
                  ],
                ),
                const SizedBox(height: 12),
                WeightChart(data: _weightSeries, goal: 64.0),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('On track 🎯', style: GoogleFonts.bricolageGrotesque(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.1)),
                    Text('goal 64.0kg', style: GoogleFonts.bricolageGrotesque(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkWithOpacity(0.4))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/app/weekly-report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Open your weekly report card',
                style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
