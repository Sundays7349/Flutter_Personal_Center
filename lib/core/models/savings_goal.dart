class SavingsGoal {
  final int? id;
  final double totalGoal;
  final double monthlyGoal;
  final int updatedAt;
  final String deviceId;
  final bool synced;

  SavingsGoal({
    this.id,
    required this.totalGoal,
    required this.monthlyGoal,
    required this.updatedAt,
    required this.deviceId,
    required this.synced,
  });

  SavingsGoal copyWith({
    int? id,
    double? totalGoal,
    double? monthlyGoal,
    int? updatedAt,
    String? deviceId,
    bool? synced,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      totalGoal: totalGoal ?? this.totalGoal,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
    );
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      totalGoal: (map['total_goal'] as num).toDouble(),
      monthlyGoal: (map['monthly_goal'] as num).toDouble(),
      updatedAt: map['updated_at'] as int,
      deviceId: map['device_id'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_goal': totalGoal,
      'monthly_goal': monthlyGoal,
      'updated_at': updatedAt,
      'device_id': deviceId,
      'synced': synced ? 1 : 0,
    };
  }
}
