class WeightLog {
  final String id;
  final double weightKg;
  final DateTime loggedAt;

  const WeightLog({
    required this.id,
    required this.weightKg,
    required this.loggedAt,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
    id: json['id'] as String,
    weightKg: (json['weight_kg'] as num).toDouble(),
    loggedAt: DateTime.parse(json['logged_at'] as String),
  );
}
