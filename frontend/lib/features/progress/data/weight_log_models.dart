class WeightLogResponse {
  final String id;
  final String userId;
  final double weightKg;
  final DateTime loggedAt;

  const WeightLogResponse({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
  });

  factory WeightLogResponse.fromJson(Map<String, dynamic> json) => WeightLogResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );
}

class WeightLogCreate {
  final double weightKg;
  final DateTime? loggedAt;

  const WeightLogCreate({required this.weightKg, this.loggedAt});

  Map<String, dynamic> toJson() => {
        'weight_kg': weightKg,
        if (loggedAt != null) 'logged_at': loggedAt!.toIso8601String(),
      };
}
