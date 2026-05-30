class DayProgress {
  final DateTime date;
  final bool logged;
  final int totalKcal;
  final double totalProteinG;
  final int workoutCount;
  final String? note;
  final double? weightKg;

  const DayProgress({
    required this.date,
    required this.logged,
    required this.totalKcal,
    required this.totalProteinG,
    required this.workoutCount,
    this.note,
    this.weightKg,
  });
}
