enum TrackingType {
  setsRepsWeight,
  distanceDuration,
  laps,
  durationOnly,
  freeform,
}

extension TrackingTypeJson on TrackingType {
  String toJson() => switch (this) {
        TrackingType.setsRepsWeight => 'sets_reps_weight',
        TrackingType.distanceDuration => 'distance_duration',
        TrackingType.laps => 'laps',
        TrackingType.durationOnly => 'duration_only',
        TrackingType.freeform => 'freeform',
      };

  static TrackingType fromJson(String s) => switch (s) {
        'sets_reps_weight' => TrackingType.setsRepsWeight,
        'distance_duration' => TrackingType.distanceDuration,
        'laps' => TrackingType.laps,
        'duration_only' => TrackingType.durationOnly,
        _ => TrackingType.freeform,
      };
}

class WorkoutExerciseResponse {
  final String id;
  final String workoutId;
  final String exerciseName;
  final TrackingType trackingType;
  final Map<String, dynamic> metrics;
  final int order;
  final String? notes;

  const WorkoutExerciseResponse({
    required this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.trackingType,
    required this.metrics,
    required this.order,
    this.notes,
  });

  factory WorkoutExerciseResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseResponse(
        id: json['id'] as String,
        workoutId: json['workout_id'] as String,
        exerciseName: json['exercise_name'] as String,
        trackingType: TrackingTypeJson.fromJson(json['tracking_type'] as String),
        metrics: json['metrics'] as Map<String, dynamic>,
        order: json['order'] as int,
        notes: json['notes'] as String?,
      );
}

class WorkoutResponse {
  final String id;
  final String userId;
  final String name;
  final String? notes;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const WorkoutResponse({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    required this.startedAt,
    this.finishedAt,
  });

  bool get isInProgress => finishedAt == null;

  factory WorkoutResponse.fromJson(Map<String, dynamic> json) => WorkoutResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String?,
        startedAt: DateTime.parse(json['started_at'] as String),
        finishedAt: json['finished_at'] != null
            ? DateTime.parse(json['finished_at'] as String)
            : null,
      );
}

class WorkoutDetailResponse extends WorkoutResponse {
  final List<WorkoutExerciseResponse> exercises;

  const WorkoutDetailResponse({
    required super.id,
    required super.userId,
    required super.name,
    super.notes,
    required super.startedAt,
    super.finishedAt,
    required this.exercises,
  });

  factory WorkoutDetailResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutDetailResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String?,
        startedAt: DateTime.parse(json['started_at'] as String),
        finishedAt: json['finished_at'] != null
            ? DateTime.parse(json['finished_at'] as String)
            : null,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExerciseResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
