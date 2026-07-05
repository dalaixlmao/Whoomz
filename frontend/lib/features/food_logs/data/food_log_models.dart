enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  static MealType fromJson(String value) =>
      MealType.values.firstWhere((m) => m.name == value);

  /// Sensible default for a quick log opened right now.
  static MealType forHour(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 18) return MealType.snack;
    return MealType.dinner;
  }
}

class FoodLog {
  final String id;
  final String name;
  final int calories;
  final MealType mealType;
  final DateTime loggedAt;

  const FoodLog({
    required this.id,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
    id: json['id'] as String,
    name: json['name'] as String,
    calories: json['calories'] as int,
    mealType: MealType.fromJson(json['meal_type'] as String),
    loggedAt: DateTime.parse(json['logged_at'] as String),
  );
}

class FoodLogCreate {
  final String name;
  final int calories;
  final MealType mealType;

  const FoodLogCreate({
    required this.name,
    required this.calories,
    required this.mealType,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'meal_type': mealType.name,
  };
}
