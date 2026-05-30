import '../../../core/api/api_client.dart';
import 'weight_log_models.dart';

class WeightLogRepository {
  final _dio = ApiClient.dio;

  Future<WeightLogResponse> create(WeightLogCreate data) async {
    final res = await _dio.post('/weight-logs/', data: data.toJson());
    return WeightLogResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WeightLogResponse>> listByRange(DateTime start, DateTime end) async {
    final res = await _dio.get('/weight-logs/', queryParameters: {
      'start_date': _fmt(start),
      'end_date': _fmt(end),
    });
    return (res.data as List)
        .map((e) => WeightLogResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) async {
    await _dio.delete('/weight-logs/$id');
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
