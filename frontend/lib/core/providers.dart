import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/conversation/data/chat_repository.dart';
import '../features/food_logs/data/food_log_repository.dart';
import '../features/today/data/daily_note_repository.dart';
import '../features/weight/data/weight_log_repository.dart';
import '../features/workouts/data/workout_repository.dart';
import 'auth/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

final foodLogRepositoryProvider = Provider<FoodLogRepository>(
  (_) => FoodLogRepository(),
);

final weightLogRepositoryProvider = Provider<WeightLogRepository>(
  (_) => WeightLogRepository(),
);

final dailyNoteRepositoryProvider = Provider<DailyNoteRepository>(
  (_) => DailyNoteRepository(),
);

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (_) => WorkoutRepository(),
);
