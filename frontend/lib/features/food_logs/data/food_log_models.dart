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
