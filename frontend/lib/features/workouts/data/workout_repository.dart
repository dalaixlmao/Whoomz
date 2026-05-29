import '../../../core/api/api_client.dart';
import 'workout_models.dart';

class WorkoutRepository {
  final _dio = ApiClient.dio;

  Future<WorkoutResponse> create({
    required String name,
    required DateTime startedAt,
    String? notes,
  }) async {
    final res = await _dio.post('/workouts/', data: {
      'name': name,
      'started_at': startedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    });
    return WorkoutResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WorkoutResponse>> list({DateTime? date}) async {
    final params = date == null
        ? <String, dynamic>{}
        : {
            'date':
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          };
    final res = await _dio.get('/workouts/', queryParameters: params);
    return (res.data as List)
        .map((e) => WorkoutResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutDetailResponse> get(String workoutId) async {
    final res = await _dio.get('/workouts/$workoutId');
    return WorkoutDetailResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WorkoutResponse> update(
    String workoutId, {
    String? name,
    String? notes,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) async {
    final res = await _dio.patch('/workouts/$workoutId', data: {
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (startedAt != null) 'started_at': startedAt.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt.toIso8601String(),
    });
    return WorkoutResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String workoutId) async {
    await _dio.delete('/workouts/$workoutId');
  }

  Future<WorkoutExerciseResponse> addExercise(
    String workoutId, {
    required String exerciseName,
    required TrackingType trackingType,
    required Map<String, dynamic> metrics,
    required int order,
    String? notes,
  }) async {
    final res = await _dio.post('/workouts/$workoutId/exercises', data: {
      'exercise_name': exerciseName,
      'tracking_type': trackingType.toJson(),
      'metrics': metrics,
      'order': order,
      if (notes != null) 'notes': notes,
    });
    return WorkoutExerciseResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WorkoutExerciseResponse> updateExercise(
    String workoutId,
    String exerciseId, {
    String? exerciseName,
    TrackingType? trackingType,
    Map<String, dynamic>? metrics,
    int? order,
    String? notes,
  }) async {
    final res = await _dio.patch('/workouts/$workoutId/exercises/$exerciseId', data: {
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (trackingType != null) 'tracking_type': trackingType.toJson(),
      if (metrics != null) 'metrics': metrics,
      if (order != null) 'order': order,
      if (notes != null) 'notes': notes,
    });
    return WorkoutExerciseResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String workoutId, String exerciseId) async {
    await _dio.delete('/workouts/$workoutId/exercises/$exerciseId');
  }
}
