class Workout {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const Workout({
    required this.id,
    required this.name,
    required this.startedAt,
    this.finishedAt,
  });

  bool get isInProgress => finishedAt == null;

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String,
    startedAt: DateTime.parse(json['started_at'] as String),
    finishedAt: json['finished_at'] == null
        ? null
        : DateTime.parse(json['finished_at'] as String),
  );
}
