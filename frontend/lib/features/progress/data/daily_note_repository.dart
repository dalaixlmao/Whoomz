import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'daily_note_models.dart';

class DailyNoteRepository {
  final _dio = ApiClient.dio;

  /// Returns null on 404 — no AI note generated yet for this date.
  Future<DailyNoteResponse?> getByDate(DateTime date) async {
    try {
      final res = await _dio.get('/daily-notes/${_fmt(date)}');
      return DailyNoteResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
