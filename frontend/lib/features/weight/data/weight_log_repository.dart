import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/units.dart';
import 'weight_log_models.dart';

class WeightLogRepository {
  WeightLogRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<WeightLog> create(double weightKg) async {
    final response = await _dio.post(
      ApiEndpoints.weightLogs,
      data: {'weight_kg': weightKg},
    );
    return WeightLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<WeightLog>> listRange(DateTime start, DateTime end) async {
    final response = await _dio.get(
      ApiEndpoints.weightLogs,
      queryParameters: {'start_date': apiDate(start), 'end_date': apiDate(end)},
    );
    return (response.data as List)
        .map((e) => WeightLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
