import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/api_client.dart';
import 'auth/token_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/food_logs/data/food_log_repository.dart';
import '../features/workouts/data/workout_repository.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/voice/data/voice_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
final apiClientProvider = Provider<Dio>((_) => ApiClient.dio);

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());
final foodLogRepositoryProvider = Provider<FoodLogRepository>((_) => FoodLogRepository());
final workoutRepositoryProvider = Provider<WorkoutRepository>((_) => WorkoutRepository());
final chatRepositoryProvider = Provider<ChatRepository>((_) => ChatRepository());
final voiceRepositoryProvider = Provider<VoiceRepository>((_) => VoiceRepository());
