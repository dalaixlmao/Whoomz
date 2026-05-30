import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/food_log_models.dart';

class FoodLogNotifier extends Notifier<List<FoodLogResponse>> {
  @override
  List<FoodLogResponse> build() => [];

  void addItem(FoodLogResponse item) {
    state = [...state, item];
  }
}

final foodLogNotifierProvider =
    NotifierProvider<FoodLogNotifier, List<FoodLogResponse>>(FoodLogNotifier.new);
