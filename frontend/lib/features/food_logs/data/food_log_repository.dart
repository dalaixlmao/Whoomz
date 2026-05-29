import '../../../core/api/api_client.dart';
import 'food_log_models.dart';

class FoodLogRepository {
  final _dio = ApiClient.dio;

  Future<FoodLogResponse> create(FoodLogCreate data) async {
    final res = await _dio.post('/food-logs/', data: data.toJson());
    return FoodLogResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<FoodLogResponse>> listByDate(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _dio.get('/food-logs/', queryParameters: {'date': dateStr});
    return (res.data as List)
        .map((e) => FoodLogResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String logId) async {
    await _dio.delete('/food-logs/$logId');
  }
}
