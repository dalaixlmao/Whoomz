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

  Future<WorkoutDetail> detail(String id) async {
    final response = await _dio.get('${ApiEndpoints.workouts}$id');
    return WorkoutDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Workout> finish(String id) async {
    final response = await _dio.patch(
      '${ApiEndpoints.workouts}$id',
      data: {'finished_at': DateTime.now().toUtc().toIso8601String()},
    );
    return Workout.fromJson(response.data as Map<String, dynamic>);
  }
}
