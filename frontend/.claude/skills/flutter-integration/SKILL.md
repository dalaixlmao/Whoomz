---
name: flutter-integration
description: Generate Flutter client code to integrate with the Whoomz backend API. Use when building a Flutter app, writing API services, models, repositories, or handling auth/SSE streaming for the Whoomz fitness app.
---

# Whoomz Flutter Integration Skill

Generates production-ready Flutter client code for the Whoomz backend (FastAPI, base URL `https://<host>/api/v1`). Covers every endpoint with exact request/response shapes, auth token management, SSE streaming (chat + voice), and a repository-pattern service layer.

---

## API Reference (19 endpoints)

All routes are prefixed `/api/v1`. All except auth and health require `Authorization: Bearer <token>`.

**Auth** (`/auth`)
```
POST /auth/signup          → 201 AuthResponse
POST /auth/login           → 200 AuthResponse
POST /auth/logout          → 204 (requires Bearer token)
POST /auth/refresh         → 200 AuthResponse
```

**Food Logs** (`/food-logs`)
```
POST   /food-logs/                    → 201 FoodLogResponse
GET    /food-logs/?date=YYYY-MM-DD    → 200 List<FoodLogResponse>
DELETE /food-logs/{log_id}            → 204
```

**Workouts** (`/workouts`)
```
POST   /workouts/                                        → 201 WorkoutResponse
GET    /workouts/                                        → 200 List<WorkoutResponse>
GET    /workouts/?date=YYYY-MM-DD                        → 200 List<WorkoutResponse>
GET    /workouts/{workout_id}                            → 200 WorkoutDetailResponse (includes exercises)
PATCH  /workouts/{workout_id}                            → 200 WorkoutResponse
DELETE /workouts/{workout_id}                            → 204

POST   /workouts/{workout_id}/exercises                  → 201 WorkoutExerciseResponse
PATCH  /workouts/{workout_id}/exercises/{exercise_id}    → 200 WorkoutExerciseResponse
DELETE /workouts/{workout_id}/exercises/{exercise_id}    → 204
```

**Chat** (`/chat`)
```
POST /chat/    → SSE stream (text/event-stream)
```

**Voice** (`/voice`)
```
POST /voice/chat    → SSE stream (text/event-stream)
```

**Health**
```
GET /    → 200 (no auth required)
```

---

## Packages

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0          # HTTP client (interceptors, cancellation)
  flutter_secure_storage: ^9.0.0  # store access/refresh tokens
  riverpod: ^2.5.0     # state management
  freezed_annotation: ^2.4.0      # immutable models
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

---

## Project Structure

```
lib/
  core/
    api/
      api_client.dart        # Dio instance + interceptors
      api_endpoints.dart     # endpoint constants
    auth/
      token_storage.dart     # FlutterSecureStorage wrapper
  features/
    auth/
      data/
        auth_repository.dart
        auth_models.dart
    food_logs/
      data/
        food_log_repository.dart
        food_log_models.dart
    workouts/
      data/
        workout_repository.dart
        workout_models.dart
    chat/
      data/
        chat_repository.dart
    voice/
      data/
        voice_repository.dart
```

---

## Core: API Client

```dart
// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _baseUrl = 'https://<your-host>/api/v1';
  static const _storage = FlutterSecureStorage();

  static final Dio dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Retry original request with new token
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await _storage.write(key: 'access_token', value: response.data['access_token']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

---

## API Endpoints Constant

```dart
// lib/core/api/api_endpoints.dart
class ApiEndpoints {
  static const auth       = '/auth';
  static const foodLogs   = '/food-logs';
  static const workouts   = '/workouts';
  static const chat       = '/chat';
  static const voice      = '/voice';
}
```

---

## Feature: Auth

### Models

```dart
// lib/features/auth/data/auth_models.dart

class UserInfo {
  final String id;
  final String email;
  final String? name;

  const UserInfo({required this.id, required this.email, this.name});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
  );
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserInfo user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    tokenType: json['token_type'] as String,
    user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
  );
}
```

### Repository

```dart
// lib/features/auth/data/auth_repository.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  static const _storage = FlutterSecureStorage();
  final _dio = ApiClient.dio;

  // POST /api/v1/auth/signup
  // Body: { name, email, password }
  // Returns: AuthResponse (201)
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  // POST /api/v1/auth/login
  // Body: { email, password }
  // Returns: AuthResponse (200)
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  // POST /api/v1/auth/logout
  // Header: Authorization: Bearer <access_token>
  // Returns: 204 No Content
  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _storage.deleteAll();
  }

  // POST /api/v1/auth/refresh
  // Body: { refresh_token }
  // Returns: AuthResponse (200)
  Future<AuthResponse> refresh(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<void> _persist(AuthResponse auth) async {
    await _storage.write(key: 'access_token', value: auth.accessToken);
    await _storage.write(key: 'refresh_token', value: auth.refreshToken);
  }
}
```

---

## Feature: Food Logs

### Models

```dart
// lib/features/food_logs/data/food_log_models.dart

enum MealType { breakfast, lunch, dinner, snack }

class FoodLogCreate {
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final MealType mealType;
  final DateTime? loggedAt;

  const FoodLogCreate({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.mealType,
    this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    if (proteinG != null) 'protein_g': proteinG,
    if (carbsG != null) 'carbs_g': carbsG,
    if (fatG != null) 'fat_g': fatG,
    'meal_type': mealType.name,
    if (loggedAt != null) 'logged_at': loggedAt!.toIso8601String(),
  };
}

class FoodLogResponse {
  final String id;
  final String userId;
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final MealType mealType;
  final DateTime loggedAt;

  const FoodLogResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLogResponse.fromJson(Map<String, dynamic> json) => FoodLogResponse(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    calories: json['calories'] as int,
    proteinG: (json['protein_g'] as num?)?.toDouble(),
    carbsG: (json['carbs_g'] as num?)?.toDouble(),
    fatG: (json['fat_g'] as num?)?.toDouble(),
    mealType: MealType.values.byName(json['meal_type'] as String),
    loggedAt: DateTime.parse(json['logged_at'] as String),
  );
}
```

### Repository

```dart
// lib/features/food_logs/data/food_log_repository.dart
import '../../../core/api/api_client.dart';
import 'food_log_models.dart';

class FoodLogRepository {
  final _dio = ApiClient.dio;

  // POST /api/v1/food-logs/
  // Body: FoodLogCreate fields
  // Returns: FoodLogResponse (201)
  Future<FoodLogResponse> create(FoodLogCreate data) async {
    final res = await _dio.post('/food-logs/', data: data.toJson());
    return FoodLogResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /api/v1/food-logs/?date=YYYY-MM-DD
  // Returns: List<FoodLogResponse> (200)
  Future<List<FoodLogResponse>> listByDate(DateTime date) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final res = await _dio.get('/food-logs/', queryParameters: {'date': dateStr});
    return (res.data as List)
        .map((e) => FoodLogResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // DELETE /api/v1/food-logs/{log_id}
  // Returns: 204 No Content
  Future<void> delete(String logId) async {
    await _dio.delete('/food-logs/$logId');
  }
}
```

---

## Feature: Workouts

### Models

```dart
// lib/features/workouts/data/workout_models.dart

enum TrackingType {
  setsRepsWeight,
  distanceDuration,
  laps,
  durationOnly,
  freeform,
}

extension TrackingTypeJson on TrackingType {
  String toJson() => switch (this) {
    TrackingType.setsRepsWeight   => 'sets_reps_weight',
    TrackingType.distanceDuration => 'distance_duration',
    TrackingType.laps             => 'laps',
    TrackingType.durationOnly     => 'duration_only',
    TrackingType.freeform         => 'freeform',
  };

  static TrackingType fromJson(String s) => switch (s) {
    'sets_reps_weight'   => TrackingType.setsRepsWeight,
    'distance_duration'  => TrackingType.distanceDuration,
    'laps'               => TrackingType.laps,
    'duration_only'      => TrackingType.durationOnly,
    _                    => TrackingType.freeform,
  };
}

class WorkoutExerciseResponse {
  final String id;
  final String workoutId;
  final String exerciseName;
  final TrackingType trackingType;
  final Map<String, dynamic> metrics;
  final int order;
  final String? notes;

  const WorkoutExerciseResponse({
    required this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.trackingType,
    required this.metrics,
    required this.order,
    this.notes,
  });

  factory WorkoutExerciseResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseResponse(
        id: json['id'] as String,
        workoutId: json['workout_id'] as String,
        exerciseName: json['exercise_name'] as String,
        trackingType: TrackingTypeJson.fromJson(json['tracking_type'] as String),
        metrics: json['metrics'] as Map<String, dynamic>,
        order: json['order'] as int,
        notes: json['notes'] as String?,
      );
}

class WorkoutResponse {
  final String id;
  final String userId;
  final String name;
  final String? notes;
  final DateTime startedAt;
  final DateTime? finishedAt; // null = in progress

  const WorkoutResponse({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    required this.startedAt,
    this.finishedAt,
  });

  factory WorkoutResponse.fromJson(Map<String, dynamic> json) => WorkoutResponse(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String?,
    startedAt: DateTime.parse(json['started_at'] as String),
    finishedAt: json['finished_at'] != null
        ? DateTime.parse(json['finished_at'] as String)
        : null,
  );

  bool get isInProgress => finishedAt == null;
}

class WorkoutDetailResponse extends WorkoutResponse {
  final List<WorkoutExerciseResponse> exercises;

  const WorkoutDetailResponse({
    required super.id,
    required super.userId,
    required super.name,
    super.notes,
    required super.startedAt,
    super.finishedAt,
    required this.exercises,
  });

  factory WorkoutDetailResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutDetailResponse(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String?,
        startedAt: DateTime.parse(json['started_at'] as String),
        finishedAt: json['finished_at'] != null
            ? DateTime.parse(json['finished_at'] as String)
            : null,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExerciseResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

### Repository

```dart
// lib/features/workouts/data/workout_repository.dart
import '../../../core/api/api_client.dart';
import 'workout_models.dart';

class WorkoutRepository {
  final _dio = ApiClient.dio;

  // POST /api/v1/workouts/
  // Body: { name, started_at, notes? }
  // Returns: WorkoutResponse (201)
  Future<WorkoutResponse> create({
    required String name,
    required DateTime startedAt,
    String? notes,
  }) async {
    final res = await _dio.post('/workouts/', data: {
      'name': name,
      'started_at': startedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    });
    return WorkoutResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /api/v1/workouts/          — all workouts
  // GET /api/v1/workouts/?date=... — filter by date
  // Returns: List<WorkoutResponse> (200)
  Future<List<WorkoutResponse>> list({DateTime? date}) async {
    final params = date == null
        ? <String, dynamic>{}
        : {
            'date': '${date.year.toString().padLeft(4,'0')}-'
                    '${date.month.toString().padLeft(2,'0')}-'
                    '${date.day.toString().padLeft(2,'0')}',
          };
    final res = await _dio.get('/workouts/', queryParameters: params);
    return (res.data as List)
        .map((e) => WorkoutResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/workouts/{workout_id}
  // Returns: WorkoutDetailResponse (200) — includes exercises list
  Future<WorkoutDetailResponse> get(String workoutId) async {
    final res = await _dio.get('/workouts/$workoutId');
    return WorkoutDetailResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /api/v1/workouts/{workout_id}
  // Body: partial { name?, notes?, started_at?, finished_at? }
  // Set finished_at to mark workout complete.
  // Returns: WorkoutResponse (200)
  Future<WorkoutResponse> update(
    String workoutId, {
    String? name,
    String? notes,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) async {
    final res = await _dio.patch('/workouts/$workoutId', data: {
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (startedAt != null) 'started_at': startedAt.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt.toIso8601String(),
    });
    return WorkoutResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // DELETE /api/v1/workouts/{workout_id}
  // Returns: 204 No Content
  Future<void> delete(String workoutId) async {
    await _dio.delete('/workouts/$workoutId');
  }

  // POST /api/v1/workouts/{workout_id}/exercises
  // Body: { exercise_name, tracking_type, metrics, order, notes? }
  // metrics shape depends on tracking_type — see Metrics Shapes section below.
  // Returns: WorkoutExerciseResponse (201)
  Future<WorkoutExerciseResponse> addExercise(
    String workoutId, {
    required String exerciseName,
    required TrackingType trackingType,
    required Map<String, dynamic> metrics,
    required int order,
    String? notes,
  }) async {
    final res = await _dio.post('/workouts/$workoutId/exercises', data: {
      'exercise_name': exerciseName,
      'tracking_type': trackingType.toJson(),
      'metrics': metrics,
      'order': order,
      if (notes != null) 'notes': notes,
    });
    return WorkoutExerciseResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /api/v1/workouts/{workout_id}/exercises/{exercise_id}
  // Body: partial { exercise_name?, tracking_type?, metrics?, order?, notes? }
  // Returns: WorkoutExerciseResponse (200)
  Future<WorkoutExerciseResponse> updateExercise(
    String workoutId,
    String exerciseId, {
    String? exerciseName,
    TrackingType? trackingType,
    Map<String, dynamic>? metrics,
    int? order,
    String? notes,
  }) async {
    final res = await _dio.patch(
      '/workouts/$workoutId/exercises/$exerciseId',
      data: {
        if (exerciseName != null) 'exercise_name': exerciseName,
        if (trackingType != null) 'tracking_type': trackingType.toJson(),
        if (metrics != null) 'metrics': metrics,
        if (order != null) 'order': order,
        if (notes != null) 'notes': notes,
      },
    );
    return WorkoutExerciseResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // DELETE /api/v1/workouts/{workout_id}/exercises/{exercise_id}
  // Returns: 204 No Content
  Future<void> deleteExercise(String workoutId, String exerciseId) async {
    await _dio.delete('/workouts/$workoutId/exercises/$exerciseId');
  }
}
```

---

## Feature: Chat (SSE Streaming)

The chat and voice endpoints return **Server-Sent Events (SSE)** — a stream of `data: <text>\n\n` lines. Use `dio` with `ResponseType.stream` to consume them.

```dart
// lib/features/chat/data/chat_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ChatRepository {
  // POST /api/v1/chat/
  // Body: { session_id, message, mode? }
  // mode: "text" (default) | "voice"
  // Returns: SSE stream — each event is a text chunk from the AI coach
  //
  // Usage:
  //   final stream = chatRepository.chat(sessionId: id, message: 'How many calories?');
  //   await for (final chunk in stream) { setState(() => reply += chunk); }
  Stream<String> chat({
    required String sessionId,
    required String message,
    String mode = 'text',
  }) async* {
    final token = await ApiClient.dio.options.headers['Authorization'];

    final response = await ApiClient.dio.post<ResponseBody>(
      '/chat/',
      data: {'session_id': sessionId, 'message': message, 'mode': mode},
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        if (payload == '[DONE]') break;
        yield payload;
      }
    }
  }
}
```

---

## Feature: Voice Chat (SSE Streaming)

```dart
// lib/features/voice/data/voice_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class VoiceRepository {
  // POST /api/v1/voice/chat
  // Body: { session_id, transcript }
  // Returns: SSE stream — text chunks from the AI coach
  //
  // session_id: unique per conversation session (generate a UUID per session)
  // transcript: the speech-to-text result from the device microphone
  Stream<String> voiceChat({
    required String sessionId,
    required String transcript,
  }) async* {
    final response = await ApiClient.dio.post<ResponseBody>(
      '/voice/chat',
      data: {'session_id': sessionId, 'transcript': transcript},
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        if (payload == '[DONE]') break;
        yield payload;
      }
    }
  }
}
```

---

## Exercise Metrics Shapes

When calling `addExercise` or `updateExercise`, the `metrics` map must match `tracking_type`:

| `tracking_type`       | `metrics` shape |
|---|---|
| `sets_reps_weight`    | `{ "sets": [{ "set_number": 1, "reps": 10, "weight_kg": 60.0 }] }` |
| `distance_duration`   | `{ "distance_km": 5.0, "duration_seconds": 1800, "avg_heart_rate": 145 }` |
| `laps`                | `{ "laps": [{ "lap_number": 1, "lap_time_seconds": 90, "distance_m": 50 }] }` |
| `duration_only`       | `{ "duration_seconds": 3600 }` |
| `freeform`            | `{}` (use the `notes` field instead) |

---

## Error Handling

All API errors come back as `DioException`. Catch them centrally:

```dart
// lib/core/api/api_error.dart
import 'package:dio/dio.dart';

class ApiError implements Exception {
  final int? statusCode;
  final String message;

  const ApiError({this.statusCode, required this.message});

  factory ApiError.fromDio(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] as String? : null;
    return ApiError(
      statusCode: e.response?.statusCode,
      message: detail ?? e.message ?? 'Unknown error',
    );
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}

// Wrap repository calls:
// try {
//   await authRepository.login(email: e, password: p);
// } on DioException catch (e) {
//   throw ApiError.fromDio(e);
// }
```

---

## Gotchas

- **session_id for chat/voice** — generate a UUID per conversation session on the client. The same `session_id` must be reused across turns in a single conversation. Use `package:uuid` to generate: `Uuid().v4()`.
- **SSE `[DONE]` sentinel** — the stream ends with `data: [DONE]`. Always check for it and break, otherwise `await for` will wait forever.
- **401 auto-refresh** — the Dio interceptor in `ApiClient` automatically retries with a fresh token on 401. Do not manually handle 401 in repositories.
- **PATCH is partial** — only send fields you want to change. Sending `null` explicitly may overwrite a value on the server.
- **`finished_at` marks workout done** — to complete a workout, PATCH it with `finished_at: DateTime.now().toIso8601String()`.
- **Date query params** — `food-logs` and `workouts` date filters expect `YYYY-MM-DD` (not ISO 8601 with time). The repositories format this correctly.
- **`order` field in exercises** — must be provided on create; controls display order in the UI. 0-indexed or 1-indexed is up to you — just be consistent.
