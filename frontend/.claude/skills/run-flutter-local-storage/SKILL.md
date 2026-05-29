---
name: run-flutter-local-storage
description: Reference and code-generation skill for Flutter local storage — SharedPreferences (simple KV), Hive (structured offline cache with typed adapters), Isar (reactive embedded DB), and hydrated_bloc for persisting BLoC/Cubit state. Use when caching user preferences, offline workout data, or persisting app state across launches.
---

None of these packages are in this project's pubspec. Add what you need:

```bash
# Simple key-value (settings, flags)
~/flutter/bin/flutter pub add shared_preferences

# Structured offline cache (fast, typed, no SQL)
~/flutter/bin/flutter pub add hive hive_flutter
~/flutter/bin/flutter pub add --dev hive_generator build_runner

# Reactive embedded DB (queries, indexes, streams)
~/flutter/bin/flutter pub add isar isar_flutter_libs
~/flutter/bin/flutter pub add --dev isar_generator build_runner

# Persist BLoC/Cubit state automatically
~/flutter/bin/flutter pub add hydrated_bloc
```

---

## SharedPreferences — simple key-value

```dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> setOnboarded(bool value) async =>
      (await _prefs).setBool('onboarded', value);

  Future<bool> isOnboarded() async =>
      (await _prefs).getBool('onboarded') ?? false;

  Future<void> setTheme(String mode) async =>
      (await _prefs).setString('theme', mode);

  Future<String> getTheme() async =>
      (await _prefs).getString('theme') ?? 'system';
}
```

Supported types: `bool`, `int`, `double`, `String`, `List<String>`.

---

## Hive — typed offline cache

### 1. Define a model
```dart
import 'package:hive/hive.dart';
part 'cached_workout.g.dart';

@HiveType(typeId: 0)
class CachedWorkout extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late DateTime createdAt;
}
```

### 2. Generate adapter
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Initialise & use
```dart
// main.dart
await Hive.initFlutter();
Hive.registerAdapter(CachedWorkoutAdapter());
final box = await Hive.openBox<CachedWorkout>('workouts');

// Write
box.put(workout.id, CachedWorkout()
  ..id = workout.id
  ..name = workout.name
  ..createdAt = workout.createdAt);

// Read all
final all = box.values.toList();

// Delete
box.delete(id);

// Clear
await box.clear();
```

---

## Isar — reactive embedded DB

### 1. Define a collection
```dart
import 'package:isar/isar.dart';
part 'food_log_entity.g.dart';

@collection
class FoodLogEntity {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String name;
  late int calories;
  @Index() late DateTime date;
}
```

### 2. Generate schema
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Open & query
```dart
final isar = await Isar.open([FoodLogEntitySchema]);

// Write
await isar.writeTxn(() async {
  await isar.foodLogEntitys.put(FoodLogEntity()
    ..remoteId = log.id
    ..name = log.name
    ..calories = log.calories
    ..date = log.loggedAt);
});

// Query by date
final today = DateTime.now();
final logs = await isar.foodLogEntitys
    .filter()
    .dateBetween(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day, 23, 59),
    )
    .findAll();

// Watch for changes
isar.foodLogEntitys.watchLazy().listen((_) => refreshUI());
```

---

## hydrated_bloc — persist Cubit/BLoC state

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setDark()   => emit(ThemeMode.dark);
  void setLight()  => emit(ThemeMode.light);
  void setSystem() => emit(ThemeMode.system);

  @override
  ThemeMode fromJson(Map<String, dynamic> json) =>
      ThemeMode.values.byName(json['mode'] as String);

  @override
  Map<String, dynamic> toJson(ThemeMode state) => {'mode': state.name};
}

// main.dart — initialise before runApp
HydratedBloc.storage = await HydratedStorage.build(
  storageDirectory: await getTemporaryDirectory(),
);
```

---

## Choosing the right tool

| Need | Tool |
|---|---|
| User settings / feature flags | `SharedPreferences` |
| Cache API responses offline | `Hive` |
| Queryable, indexed local DB | `Isar` |
| Persist BLoC/Cubit across launches | `hydrated_bloc` |
| Encrypted storage (tokens) | `flutter_secure_storage` (already in project) |

## Gotchas

- `SharedPreferences` is async on first call (reads from disk). Cache the instance to avoid repeated awaits.
- Hive `typeId` values must be globally unique across all adapters in your app — keep a registry comment.
- Isar `Id` must be an `int` named `id` or annotated with `@Id()`. Auto-increment uses `Isar.autoIncrement` sentinel.
- `HydratedBloc` stores state as JSON in the app's temp/support directory. If you change your `toJson`/`fromJson` schema, add migration logic or clear storage on version bump to avoid deserialization errors.
- None of these are encrypted by default. For sensitive data (tokens, health info), use `flutter_secure_storage`.
