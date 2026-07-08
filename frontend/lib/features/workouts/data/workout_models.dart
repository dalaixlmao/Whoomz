class Workout {
  final String id;
  final String name;
  final String? notes;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const Workout({
    required this.id,
    required this.name,
    this.notes,
    required this.startedAt,
    this.finishedAt,
  });

  bool get isInProgress => finishedAt == null;

  Duration? get duration => finishedAt?.difference(startedAt);

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String?,
    startedAt: DateTime.parse(json['started_at'] as String),
    finishedAt: json['finished_at'] == null
        ? null
        : DateTime.parse(json['finished_at'] as String),
  );
}

enum TrackingType {
  setsRepsWeight('sets_reps_weight'),
  distanceDuration('distance_duration'),
  laps('laps'),
  durationOnly('duration_only'),
  freeform('freeform');

  const TrackingType(this.wire);

  final String wire;

  static TrackingType fromJson(String value) =>
      TrackingType.values.firstWhere((t) => t.wire == value);
}

class WorkoutExercise {
  final String id;
  final String exerciseName;
  final TrackingType trackingType;
  final Map<String, dynamic> metrics;
  final int order;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.exerciseName,
    required this.trackingType,
    required this.metrics,
    required this.order,
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseName: json['exercise_name'] as String,
        trackingType: TrackingType.fromJson(json['tracking_type'] as String),
        metrics: (json['metrics'] as Map<String, dynamic>?) ?? const {},
        order: json['order'] as int,
        notes: json['notes'] as String?,
      );
}

class WorkoutDetail extends Workout {
  final List<WorkoutExercise> exercises;

  const WorkoutDetail({
    required super.id,
    required super.name,
    super.notes,
    required super.startedAt,
    super.finishedAt,
    required this.exercises,
  });

  factory WorkoutDetail.fromJson(Map<String, dynamic> json) {
    final base = Workout.fromJson(json);
    final exercises =
        ((json['exercises'] as List?) ?? const [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return WorkoutDetail(
      id: base.id,
      name: base.name,
      notes: base.notes,
      startedAt: base.startedAt,
      finishedAt: base.finishedAt,
      exercises: exercises,
    );
  }
}
