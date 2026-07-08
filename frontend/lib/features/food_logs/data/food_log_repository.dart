import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/units.dart';
import 'food_log_models.dart';

class FoodLogRepository {
  FoodLogRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<FoodLog> create(FoodLogCreate data) async {
    final response = await _dio.post(
      ApiEndpoints.foodLogs,
      data: data.toJson(),
    );
    return FoodLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${ApiEndpoints.foodLogs}$id');
  }

  Future<List<FoodLog>> listByDate(DateTime date) async {
    final response = await _dio.get(
      ApiEndpoints.foodLogs,
      queryParameters: {'date': apiDate(date)},
    );
    return (response.data as List)
        .map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
