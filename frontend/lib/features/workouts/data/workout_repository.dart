import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'workout_models.dart';

class WorkoutRepository {
  WorkoutRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Workout>> list() async {
    final response = await _dio.get(ApiEndpoints.workouts);
    return (response.data as List)
        .map((e) => Workout.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
