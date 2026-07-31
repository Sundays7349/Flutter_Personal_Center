class FitnessDiet {
  final String id;
  final String date;
  final String time;
  final String mealType;
  final String food;
  final int calories;
  final int createdAt;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  FitnessDiet({
    required this.id,
    required this.date,
    required this.time,
    required this.mealType,
    required this.food,
    required this.calories,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  FitnessDiet copyWith({
    String? id,
    String? date,
    String? time,
    String? mealType,
    String? food,
    int? calories,
    int? createdAt,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return FitnessDiet(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      mealType: mealType ?? this.mealType,
      food: food ?? this.food,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory FitnessDiet.fromMap(Map<String, dynamic> map) {
    return FitnessDiet(
      id: map['id'] as String? ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      mealType: map['meal_type'] as String? ?? '',
      food: map['food'] as String? ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      deviceId: map['device_id'] as String? ?? '',
      synced: (map['synced'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'meal_type': mealType,
      'food': food,
      'calories': calories,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}

String detectMealType(DateTime dt) {
  final hour = dt.hour;
  if (hour >= 21 || hour < 6) return '夜宵';
  if (hour >= 6 && hour < 10) return '早餐';
  if (hour >= 10 && hour < 15) return '中餐';
  return '晚餐';
}

String formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
