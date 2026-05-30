import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workout_models.dart';

class WorkoutNotifier extends Notifier<List<WorkoutDetailResponse>> {
  @override
  List<WorkoutDetailResponse> build() => [];

  void addItem(WorkoutDetailResponse item) {
    state = [...state, item];
  }
}

final workoutNotifierProvider =
    NotifierProvider<WorkoutNotifier, List<WorkoutDetailResponse>>(WorkoutNotifier.new);
