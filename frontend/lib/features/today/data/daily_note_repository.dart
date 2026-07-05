import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/units.dart';

class DailyNoteRepository {
  DailyNoteRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// The daily-notes job writes yesterday's summary; try today then fall back.
  Future<String?> latestNote() async {
    final today = DateTime.now();
    for (final date in [today, today.subtract(const Duration(days: 1))]) {
      final note = await _fetch(apiDate(date));
      if (note != null) return note;
    }
    return null;
  }

  Future<String?> _fetch(String date) async {
    try {
      final response = await _dio.get(ApiEndpoints.dailyNote(date));
      return (response.data as Map<String, dynamic>)['note'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
